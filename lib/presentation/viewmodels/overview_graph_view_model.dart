import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crown_micro_solar/presentation/repositories/energy_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/models/device/device_key_parameter_model.dart'
    as model;
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart'
    as vm;
import 'package:crown_micro_solar/core/di/service_locator.dart';

enum GraphMetric {
  outputPower,
  loadPower,
  gridPower,
  gridVoltage,
  gridFrequency,
  pvInputVoltage,
  pvInputCurrent,
  acOutputVoltage,
  acOutputCurrent,
  batterySoc,
}

enum GraphPeriod { day, month, year }

class OverviewGraphSeries {
  final String label;
  final Color color;
  final List<double> data; // aligned to labels
  OverviewGraphSeries(
      {required this.label, required this.color, required this.data});
}

class OverviewGraphState {
  final List<String> labels; // x-axis labels already formatted
  final List<OverviewGraphSeries> series;
  final String unit;
  final double min;
  final double max;
  final double avg;
  final bool isLoading;
  final String? error;

  OverviewGraphState({
    required this.labels,
    required this.series,
    required this.unit,
    required this.min,
    required this.max,
    required this.avg,
    this.isLoading = false,
    this.error,
  });

  factory OverviewGraphState.loading() => OverviewGraphState(
        labels: const [],
        series: const [],
        unit: '',
        min: 0,
        max: 0,
        avg: 0,
        isLoading: true,
      );
}

class OverviewGraphViewModel extends ChangeNotifier {
  final _energyRepo = getIt<EnergyRepository>();
  final _deviceRepo = getIt<DeviceRepository>();

  GraphMetric _metric = GraphMetric.outputPower;
  GraphPeriod _period = GraphPeriod.day;
  DateTime _anchor = DateTime.now();
  String? _error;
  bool _loading = false;
  OverviewGraphState _state = OverviewGraphState.loading();

  // Device selection support
  List<DeviceRef> _devices = [];
  DeviceRef? _selectedDevice;

  List<DeviceRef> get devices => _devices;
  DeviceRef? get selectedDevice => _selectedDevice;

  // A stable key for dropdowns
  String? get selectedDeviceKey => _selectedDevice?.key;
  List<({String key, String label})> get deviceOptions => _devices
      .map((d) => (key: d.key, label: d.alias.isNotEmpty ? d.alias : d.pn))
      .toList();

  GraphMetric get metric => _metric;
  GraphPeriod get period => _period;
  DateTime get anchor => _anchor;
  OverviewGraphState get state => _state;
  bool get isLoading => _loading;
  String? get error => _error;

  // Map GraphMetric to logical repository parameter keys
  static const Map<GraphMetric, String> _metricToLogical = {
    GraphMetric.outputPower: 'PV_OUTPUT_POWER', // corrected mapping
    GraphMetric.loadPower: 'LOAD_POWER',
    GraphMetric.gridPower: 'GRID_POWER',
    GraphMetric.gridVoltage: 'AC2_OUTPUT_VOLTAGE',
    GraphMetric.gridFrequency: 'GRID_FREQUENCY',
    GraphMetric.pvInputVoltage: 'PV_INPUT_VOLTAGE',
    GraphMetric.pvInputCurrent: 'PV_INPUT_CURRENT',
    GraphMetric.acOutputVoltage: 'AC2_OUTPUT_VOLTAGE',
    GraphMetric.acOutputCurrent: 'AC2_OUTPUT_CURRENT',
    GraphMetric.batterySoc: 'BATTERY_SOC',
  };

  // Determine which metrics are supported for a given device by consulting DeviceRepository capability map
  List<GraphMetric> allowedMetricsForDevice(int devcode) {
    final all = GraphMetric.values;
    final out = <GraphMetric>[];
    for (final m in all) {
      final key = _metricToLogical[m]!;
      if (_deviceRepo.deviceSupportsParameter(devcode, key)) {
        out.add(m);
      }
    }
    // Ensure at least outputPower present as fallback
    if (out.isEmpty) return [GraphMetric.outputPower];
    return out;
  }

  List<GraphMetric> get allowedMetricsForSelectedDevice =>
      _selectedDevice == null
          ? GraphMetric.values
          : allowedMetricsForDevice(_selectedDevice!.devcode);

  // Public API
  Future<void> init(String plantId) async {
    await _loadDevices(plantId);
    if (_devices.length == 1 && _selectedDevice == null) {
      _selectedDevice = _devices.first;
    }
    await refresh(plantId: plantId);
  }

  Future<void> setMetric(GraphMetric m, {required String plantId}) async {
    _metric = m;
    await refresh(plantId: plantId);
  }

  Future<void> setPeriod(GraphPeriod p, {required String plantId}) async {
    _period = p;
    // Prevent anchor from being in the future for the selected period
    _clampAnchorToNow();
    await refresh(plantId: plantId);
  }

  Future<void> stepDate(int delta, {required String plantId}) async {
    final prev = _anchor;
    DateTime proposed;
    switch (_period) {
      case GraphPeriod.day:
        proposed = _anchor.add(Duration(days: delta));
        break;
      case GraphPeriod.month:
        proposed = DateTime(_anchor.year, _anchor.month + delta, 1);
        break;
      case GraphPeriod.year:
        proposed = DateTime(_anchor.year + delta, 1, 1);
        break;
    }
    _anchor = proposed;
    _clampAnchorToNow();
    // If clamping kept us in the same bucket, skip refresh
    if (_sameBucket(prev, _anchor)) {
      return;
    }
    await refresh(plantId: plantId);
  }

  Future<void> refresh({required String plantId}) async {
    // Ensure anchor is not beyond current date for the active period
    _clampAnchorToNow();
    _loading = true;
    _error = null;
    _state = OverviewGraphState.loading();
    notifyListeners();

    try {
      if (_period == GraphPeriod.day) {
        await _loadDaily(plantId);
      } else if (_period == GraphPeriod.month) {
        await _loadMonthly(plantId);
      } else {
        await _loadYearly(plantId);
      }
    } catch (e) {
      _error = e.toString();
      _state = OverviewGraphState(
        labels: const [],
        series: const [],
        unit: _unitForMetric(_metric),
        min: 0,
        max: 0,
        avg: 0,
        isLoading: false,
        error: _error,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDaily(String plantId) async {
    final dateStr = _anchor.toIso8601String().substring(0, 10);
    final labels =
        List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
    List<double> values;

    // If a specific device is selected, build the series for that device only
    if (_selectedDevice != null) {
      // New approach: use DeviceRepository metric resolver to get series when available
      values = List<double>.filled(24, 0);
      final logical = _metricToLogical[_metric]!;
      final metricResult = await _deviceRepo.resolveMetricOneDay(
        logicalMetric: logical,
        sn: _selectedDevice!.sn,
        pn: _selectedDevice!.pn,
        devcode: _selectedDevice!.devcode,
        devaddr: _selectedDevice!.devaddr,
        date: dateStr,
      );
      if (metricResult.series.isNotEmpty) {
        // Series contains ts -> map to hour buckets
        for (final point in metricResult.series) {
          final ts = point['ts']?.toString();
          final val = point['val'];
          if (ts != null && val is num) {
            // Expect formats like '2025-08-22 05:17:30' or ISO 8601
            int hour;
            try {
              if (ts.contains('T')) {
                hour = DateTime.parse(ts).hour;
              } else {
                final timePart = ts.split(' ').last;
                hour = int.tryParse(timePart.split(':').first) ?? 0;
              }
            } catch (_) {
              hour = 0;
            }
            if (hour >= 0 && hour < 24) {
              // For sum metrics accumulate; for avg style we overwrite (will average later if needed)
              if (_aggregationForMetric(_metric) == _Agg.sum) {
                values[hour] += val.toDouble();
              } else {
                values[hour] = val.toDouble();
              }
            }
          }
        }
      } else {
        // Fallback to existing key parameter approach if series empty
        final deviceVm = getIt<vm.DeviceViewModel>();
        final param = _mapMetricToDeviceParameter(_metric);
        var data = await deviceVm.fetchDeviceKeyParameterOneDay(
          sn: _selectedDevice!.sn,
          pn: _selectedDevice!.pn,
          devcode: _selectedDevice!.devcode,
          devaddr: _selectedDevice!.devaddr,
          parameter: param,
          date: dateStr,
        );
        Map<String, dynamic>? pagingJson;
        if ((data == null ||
            data.dat == null ||
            data.dat!.row == null ||
            data.dat!.row!.isEmpty)) {
          pagingJson = await _deviceRepo.fetchDeviceDataOneDayPaging(
            sn: _selectedDevice!.sn,
            pn: _selectedDevice!.pn,
            devcode: _selectedDevice!.devcode,
            devaddr: _selectedDevice!.devaddr,
            date: dateStr,
          );
        }
        if (data != null &&
            data.dat != null &&
            data.dat!.row != null &&
            data.dat!.row!.isNotEmpty) {
          for (final row in data.dat!.row!) {
            final timeStr = row.time ?? '00:00';
            final parts = timeStr.split(':');
            final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
            if (hour < 0 || hour > 23) continue;
            final v = (row.field != null && row.field!.isNotEmpty)
                ? (double.tryParse(row.field!.first.toString()) ?? 0.0)
                : 0.0;
            values[hour] = v;
          }
        } else if (pagingJson != null) {
          final guessedNames = [
            'Grid Power',
            'Load Power',
            'PV Power',
            'Output Power',
            'Battery SOC',
            'SOC'
          ];
          double? flat;
          for (final name in guessedNames) {
            flat = _deviceRepo.extractLatestPagingValue(pagingJson, name);
            if (flat != null) break;
          }
          if (flat != null) {
            for (int h = 0; h < 24; h++) {
              if (_aggregationForMetric(_metric) == _Agg.sum) {
                values[h] += flat;
              } else {
                values[h] = flat;
              }
            }
          }
        }
      }
    } else {
      if (_metric == GraphMetric.outputPower) {
        // Plant-level output power from DESS
        final summary = await _energyRepo.getDailyEnergy(plantId, dateStr);
        values = List<double>.filled(24, 0);
        for (final h in summary.hourlyData) {
          final idx = h.timestamp.hour;
          if (idx >= 0 && idx < 24) values[idx] = h.power.toDouble();
        }
        // Fallback: if all zeros (common when plant API returns err=12) try aggregating devices directly
        final allZero = values.every((v) => v == 0.0);
        if (allZero) {
          try {
            final deviceDerived = await _aggregateDevicesDaily(
              plantId: plantId,
              metric: GraphMetric.outputPower,
              date: dateStr,
            );
            // Only replace if deviceDerived has some non-zero data
            if (deviceDerived.any((v) => v > 0)) {
              values = deviceDerived;
            }
          } catch (_) {}
        }
      } else {
        values = await _aggregateDevicesDaily(
            plantId: plantId, metric: _metric, date: dateStr);
      }
    }

    final stats = _stats(values);
    _state = OverviewGraphState(
      labels: labels,
      series: [
        OverviewGraphSeries(
          label: _labelForMetric(_metric),
          color: _colorForMetric(_metric),
          data: values,
        )
      ],
      unit: _unitForMetric(_metric),
      min: stats.min,
      max: stats.max,
      avg: stats.avg,
      isLoading: false,
    );
  }

  Future<void> _loadMonthly(String plantId) async {
    final daysInMonth = DateTime(_anchor.year, _anchor.month + 1, 0).day;
    final labels = List.generate(daysInMonth, (i) => '${i + 1}');
    final data = <double>[];

    // Prefer aggregated API for plant-level Output Power
    bool usedAggregated = false;
    if (_selectedDevice == null && _metric == GraphMetric.outputPower) {
      try {
        final summary = await _energyRepo.getMonthlyEnergy(
          plantId,
          _anchor.year.toString(),
          _anchor.month.toString(),
        );
        final points = summary.hourlyData; // reused field as generic list
        if (points.isNotEmpty) {
          // Build per-day values using energy first, fallback to power
          for (int i = 0; i < points.length; i++) {
            final p = points[i];
            final v = (p.energy != 0) ? p.energy : p.power;
            data.add(v);
          }
          // Adjust labels if API returned fewer/more points
          if (data.length != labels.length) {
            labels
              ..clear()
              ..addAll(List.generate(data.length, (i) => '${i + 1}'));
          }
          usedAggregated = true;
        }
      } catch (_) {
        usedAggregated = false;
      }
    }

    if (!usedAggregated) {
      for (int day = 1; day <= daysInMonth; day++) {
        final dateStr = _fmtDate(DateTime(_anchor.year, _anchor.month, day));
        if (_selectedDevice != null) {
          // Try device-level month-per-day resolver first
          try {
            final logical = _metricToLogical[_metric]!;
            final res = await _deviceRepo.resolveMetricMonthPerDay(
              logicalMetric: logical,
              sn: _selectedDevice!.sn,
              pn: _selectedDevice!.pn,
              devcode: _selectedDevice!.devcode,
              devaddr: _selectedDevice!.devaddr,
              yearMonth:
                  '${_anchor.year.toString().padLeft(4, '0')}-${_anchor.month.toString().padLeft(2, '0')}',
            );
            if (res.series.isNotEmpty) {
              // Map series day i to value
              // Ensure data only built once from resolver
              if (data.isEmpty) {
                final tmp = List<double>.filled(daysInMonth, 0);
                for (final p in res.series) {
                  final ts = p['ts']?.toString();
                  final val = p['val'];
                  if (ts != null && val is num) {
                    final dt = DateTime.tryParse(ts);
                    if (dt != null && dt.month == _anchor.month) {
                      final idx = dt.day - 1;
                      if (idx >= 0 && idx < tmp.length)
                        tmp[idx] = val.toDouble();
                    }
                  }
                }
                data.addAll(tmp);
                continue; // proceed to next day loop iteration via outer control
              }
            }
          } catch (_) {}
          // Fallback: compute per day from daily rows
          final hourly = await _deviceDailyForDate(
            device: _selectedDevice!,
            metric: _metric,
            date: dateStr,
          );
          final agg = _aggregationForMetric(_metric) == _Agg.sum
              ? hourly.fold(0.0, (a, b) => a + b)
              : (hourly.isEmpty
                  ? 0.0
                  : hourly.reduce((a, b) => a + b) / hourly.length);
          data.add(agg);
        } else {
          if (_metric == GraphMetric.outputPower) {
            final summary = await _energyRepo.getDailyEnergy(plantId, dateStr);
            data.add(summary.totalEnergy);
          } else {
            final hourly = await _aggregateDevicesDaily(
              plantId: plantId,
              metric: _metric,
              date: dateStr,
            );
            final agg = _aggregationForMetric(_metric) == _Agg.sum
                ? hourly.fold(0.0, (a, b) => a + b)
                : (hourly.isEmpty
                    ? 0.0
                    : hourly.reduce((a, b) => a + b) / hourly.length);
            data.add(agg);
          }
        }
      }
    }

    final stats = _stats(data);
    _state = OverviewGraphState(
      labels: labels,
      series: [
        OverviewGraphSeries(
          label: _labelForMetric(_metric),
          color: _colorForMetric(_metric),
          data: data,
        )
      ],
      unit: _unitForMetricForPeriod(_metric, GraphPeriod.month),
      min: stats.min,
      max: stats.max,
      avg: stats.avg,
      isLoading: false,
    );
  }

  Future<void> _loadYearly(String plantId) async {
    final labels = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final data = <double>[];
    bool usedAggregated = false;
    if (_selectedDevice == null && _metric == GraphMetric.outputPower) {
      try {
        final summary =
            await _energyRepo.getYearlyEnergy(plantId, _anchor.year.toString());
        final points = summary.hourlyData; // reused field as generic list
        if (points.isNotEmpty) {
          for (final p in points) {
            final v = (p.energy != 0) ? p.energy : p.power;
            data.add(v);
          }
          // Ensure exactly 12 points
          if (data.length != 12) {
            // pad or trim to 12
            if (data.length < 12) {
              data.addAll(List<double>.filled(12 - data.length, 0));
            } else {
              data.removeRange(12, data.length);
            }
          }
          usedAggregated = true;
        }
      } catch (_) {
        usedAggregated = false;
      }
    }

    if (!usedAggregated) {
      for (int m = 1; m <= 12; m++) {
        if (_selectedDevice != null) {
          // Try device-level year-per-month resolver first
          try {
            final logical = _metricToLogical[_metric]!;
            final res = await _deviceRepo.resolveMetricYearPerMonth(
              logicalMetric: logical,
              sn: _selectedDevice!.sn,
              pn: _selectedDevice!.pn,
              devcode: _selectedDevice!.devcode,
              devaddr: _selectedDevice!.devaddr,
              year: _anchor.year.toString(),
            );
            if (res.series.isNotEmpty) {
              if (data.isEmpty) {
                final tmp = List<double>.filled(12, 0);
                for (final p in res.series) {
                  final ts = p['ts']?.toString();
                  final val = p['val'];
                  if (ts != null && val is num) {
                    final dt = DateTime.tryParse(ts);
                    if (dt != null && dt.year == _anchor.year) {
                      final idx = dt.month - 1;
                      if (idx >= 0 && idx < tmp.length)
                        tmp[idx] = val.toDouble();
                    }
                  }
                }
                data.addAll(tmp);
                continue;
              }
            }
          } catch (_) {}
          // Fallback: approximate month via mid-month day
          final midDay = DateTime(_anchor.year, m, 15);
          final dateStr = _fmtDate(midDay);
          final hourly = await _deviceDailyForDate(
            device: _selectedDevice!,
            metric: _metric,
            date: dateStr,
          );
          final agg = _aggregationForMetric(_metric) == _Agg.sum
              ? hourly.fold(0.0, (a, b) => a + b)
              : (hourly.isEmpty
                  ? 0.0
                  : hourly.reduce((a, b) => a + b) / hourly.length);
          data.add(agg);
        } else {
          if (_metric == GraphMetric.outputPower) {
            // Sum of daily totals in month
            double monthSum = 0.0;
            final daysInMonth = DateTime(_anchor.year, m + 1, 0).day;
            for (int d = 1; d <= daysInMonth; d++) {
              final dateStr = _fmtDate(DateTime(_anchor.year, m, d));
              final summary =
                  await _energyRepo.getDailyEnergy(plantId, dateStr);
              monthSum += summary.totalEnergy;
            }
            data.add(monthSum);
          } else {
            // Representative sampling: take mid-month day aggregate
            final midDay = DateTime(_anchor.year, m, 15);
            final dateStr = _fmtDate(midDay);
            final hourly = await _aggregateDevicesDaily(
              plantId: plantId,
              metric: _metric,
              date: dateStr,
            );
            final agg = _aggregationForMetric(_metric) == _Agg.sum
                ? hourly.fold(0.0, (a, b) => a + b)
                : (hourly.isEmpty
                    ? 0.0
                    : hourly.reduce((a, b) => a + b) / hourly.length);
            data.add(agg);
          }
        }
      }
    }
    final stats = _stats(data);
    _state = OverviewGraphState(
      labels: labels,
      series: [
        OverviewGraphSeries(
          label: _labelForMetric(_metric),
          color: _colorForMetric(_metric),
          data: data,
        )
      ],
      unit: _unitForMetricForPeriod(_metric, GraphPeriod.year),
      min: stats.min,
      max: stats.max,
      avg: stats.avg,
      isLoading: false,
    );
  }

  // Helpers
  Future<List<double>> _aggregateDevicesDaily({
    required String plantId,
    required GraphMetric metric,
    required String date,
  }) async {
    // Use cached devices if loaded; otherwise fetch once
    List devices;
    if (_devices.isNotEmpty) {
      devices = _devices;
    } else {
      final devicesBundle = await _deviceRepo.getDevicesAndCollectors(plantId);
      devices = (devicesBundle['allDevices'] as List?) ?? [];
      if (_devices.isEmpty && devices.isNotEmpty) {
        // Cache for later
        _devices = devices.map<DeviceRef>((d) {
          try {
            if (d is Map) {
              return DeviceRef(
                  sn: d['sn']?.toString() ?? '',
                  pn: d['pn']?.toString() ?? '',
                  devcode: int.tryParse(d['devcode']?.toString() ?? '') ?? 0,
                  devaddr: int.tryParse(d['devaddr']?.toString() ?? '') ?? 0,
                  alias: d['alias']?.toString() ?? d['pn']?.toString() ?? '');
            }
          } catch (_) {}
          return DeviceRef(sn: '', pn: '', devcode: 0, devaddr: 0, alias: '');
        }).toList();
      }
    }
    if (devices.isEmpty) {
      return List<double>.filled(24, 0);
    }

    // Use DeviceViewModel's mapping and fallbacks
    final deviceVm = getIt<vm.DeviceViewModel>();
    // We'll attempt multiple parameter fallbacks depending on device type
    // to avoid empty data (collector vs inverter vs storage differences)
    final aggType = _aggregationForMetric(metric);

    final sums = List<double>.filled(24, 0);
    final counts = List<int>.filled(24, 0);

    for (final d in devices) {
      try {
        // Support both Map and typed objects
        String sn;
        String pn;
        int devcode;
        int devaddr;

        if (d is Map) {
          sn = d['sn']?.toString() ?? '';
          pn = d['pn']?.toString() ?? '';
          devcode = int.tryParse(d['devcode']?.toString() ?? '') ?? 0;
          devaddr = int.tryParse(d['devaddr']?.toString() ?? '') ?? 0;
        } else {
          // Fallback for any typed models
          try {
            // ignore: avoid_dynamic_calls
            sn = (d.sn)?.toString() ?? '';
            // ignore: avoid_dynamic_calls
            pn = (d.pn)?.toString() ?? '';
            // ignore: avoid_dynamic_calls
            devcode = int.tryParse((d.devcode)?.toString() ?? '') ?? 0;
            // ignore: avoid_dynamic_calls
            devaddr = int.tryParse((d.devaddr)?.toString() ?? '') ?? 0;
          } catch (_) {
            sn = '';
            pn = '';
            devcode = 0;
            devaddr = 0;
          }
        }

        // Skip devices that clearly don't support the metric
        if (!_deviceSupportsMetric(devcode, metric)) continue;

        model.DeviceKeyParameterModel? data;
        for (final candidate in _candidateParameters(metric, devcode)) {
          data = await deviceVm.fetchDeviceKeyParameterOneDay(
            sn: sn,
            pn: pn,
            devcode: devcode,
            devaddr: devaddr,
            parameter: candidate,
            date: date,
          );
          if (data != null &&
              data.dat != null &&
              data.dat!.row != null &&
              data.dat!.row!.isNotEmpty) {
            break; // got usable data
          }
        }

        if (data == null || data.dat == null || data.dat!.row == null) continue;
        for (final row in data.dat!.row!) {
          try {
            final timeStr = row.time ?? '00:00';
            final parts = timeStr.split(':');
            final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
            if (hour < 0 || hour > 23) continue;

            double v = 0.0;
            if (row.field != null && row.field!.isNotEmpty) {
              v = double.tryParse(row.field!.first.toString()) ?? 0.0;
            }
            sums[hour] += v;
            counts[hour] += 1;
          } catch (_) {}
        }
      } catch (_) {}
    }

    // Combine by aggregation rule
    final res = <double>[];
    for (int i = 0; i < 24; i++) {
      if (aggType == _Agg.sum) {
        res.add(sums[i]);
      } else {
        final c = counts[i];
        res.add(c == 0 ? 0.0 : (sums[i] / c));
      }
    }
    return res;
  }

  String _labelForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
        return 'Output Power';
      case GraphMetric.loadPower:
        return 'Load Power';
      case GraphMetric.gridPower:
        return 'Grid Power';
      case GraphMetric.gridVoltage:
        return 'Grid Voltage';
      case GraphMetric.gridFrequency:
        return 'Grid Frequency';
      case GraphMetric.pvInputVoltage:
        return 'PV Input Voltage';
      case GraphMetric.pvInputCurrent:
        return 'PV Input Current';
      case GraphMetric.acOutputVoltage:
        return 'AC Output Voltage';
      case GraphMetric.acOutputCurrent:
        return 'AC Output Current';
      case GraphMetric.batterySoc:
        return 'Battery SOC';
    }
  }

  String _unitForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
        return 'kW';
      case GraphMetric.loadPower:
        return 'kW';
      case GraphMetric.gridPower:
        return 'kW';
      case GraphMetric.gridVoltage:
        return 'V';
      case GraphMetric.gridFrequency:
        return 'Hz';
      case GraphMetric.pvInputVoltage:
        return 'V';
      case GraphMetric.pvInputCurrent:
        return 'A';
      case GraphMetric.acOutputVoltage:
        return 'V';
      case GraphMetric.acOutputCurrent:
        return 'A';
      case GraphMetric.batterySoc:
        return '%';
    }
  }

  Color _colorForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
        return Colors.orange;
      case GraphMetric.loadPower:
        return Colors.blue;
      case GraphMetric.gridPower:
        return Colors.purple;
      case GraphMetric.gridVoltage:
        return Colors.blue;
      case GraphMetric.gridFrequency:
        return Colors.purple;
      case GraphMetric.pvInputVoltage:
        return Colors.amber;
      case GraphMetric.pvInputCurrent:
        return Colors.deepOrange;
      case GraphMetric.acOutputVoltage:
        return Colors.red;
      case GraphMetric.acOutputCurrent:
        return Colors.teal;
      case GraphMetric.batterySoc:
        return Colors.green;
    }
  }

  _Stats _stats(List<double> values) {
    if (values.isEmpty) return _Stats(0, 0, 0);
    double minV = values.first;
    double maxV = values.first;
    double sum = 0;
    for (final v in values) {
      minV = min(minV, v);
      maxV = max(maxV, v);
      sum += v;
    }
    return _Stats(minV, maxV, values.isEmpty ? 0 : sum / values.length);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _unitForMetricForPeriod(GraphMetric m, GraphPeriod p) {
    if (m == GraphMetric.outputPower &&
        (p == GraphPeriod.month || p == GraphPeriod.year)) {
      return 'kWh';
    }
    return _unitForMetric(m);
  }

  // Metric -> device parameter mapping used by device VM
  String _mapMetricToDeviceParameter(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
        return 'PV_OUTPUT_POWER';
      case GraphMetric.loadPower:
        return 'LOAD_POWER';
      case GraphMetric.gridPower:
        return 'GRID_POWER';
      case GraphMetric.gridVoltage:
        return 'AC2_OUTPUT_VOLTAGE';
      case GraphMetric.gridFrequency:
        return 'GRID_FREQUENCY';
      case GraphMetric.pvInputVoltage:
        return 'PV_INPUT_VOLTAGE';
      case GraphMetric.pvInputCurrent:
        return 'PV_INPUT_CURRENT';
      case GraphMetric.acOutputVoltage:
        return 'AC2_OUTPUT_VOLTAGE';
      case GraphMetric.acOutputCurrent:
        return 'AC2_OUTPUT_CURRENT';
      case GraphMetric.batterySoc:
        return 'BATTERY_SOC';
    }
  }

  // Determine if a device (by devcode) plausibly supports a metric
  bool _deviceSupportsMetric(int devcode, GraphMetric m) {
    // -1 (collector), 512 (inverter), 1024 (smart meter), 2452/2304/2449/2400 (storage), 1792 (battery)
    final isCollector = devcode == -1;
    final isInverter = devcode == 512;
    final isSmart = devcode == 1024;
    final isStorage = const {2452, 2304, 2449, 2400}.contains(devcode);
    final isBattery = devcode == 1792;
    switch (m) {
      case GraphMetric.outputPower:
      case GraphMetric.pvInputVoltage:
      case GraphMetric.pvInputCurrent:
      case GraphMetric.acOutputVoltage:
      case GraphMetric.acOutputCurrent:
        return isInverter ||
            isStorage ||
            isCollector; // collectors sometimes proxy
      case GraphMetric.loadPower:
        return isInverter || isStorage || isSmart || isCollector;
      case GraphMetric.gridPower:
      case GraphMetric.gridVoltage:
      case GraphMetric.gridFrequency:
        return isCollector ||
            isSmart ||
            isInverter; // grid metrics likely from collector/smart meter/inverter
      case GraphMetric.batterySoc:
        return isStorage || isBattery || isInverter; // inverter with battery
    }
  }

  // Provide a prioritized list of parameter keys to try per metric & device type
  List<String> _candidateParameters(GraphMetric m, int devcode) {
    final base = _mapMetricToDeviceParameter(m);
    final list = <String>[base];
    // Add fallbacks based on observed API variants (uppercase or legacy names)
    switch (m) {
      case GraphMetric.outputPower:
        list.addAll(['OUTPUT_POWER', 'AC_OUTPUT_POWER']);
        break;
      case GraphMetric.loadPower:
        list.addAll(['LOAD_POWER', 'AC_LOAD_POWER']);
        break;
      case GraphMetric.gridPower:
        list.add('AC_GRID_POWER');
        break;
      case GraphMetric.gridVoltage:
        list.addAll(['GRID_VOLTAGE', 'AC_GRID_VOLTAGE']);
        break;
      case GraphMetric.gridFrequency:
        list.add('AC_GRID_FREQUENCY');
        break;
      case GraphMetric.pvInputVoltage:
        list.add('PV_VOLTAGE');
        break;
      case GraphMetric.pvInputCurrent:
        list.add('PV_CURRENT');
        break;
      case GraphMetric.acOutputVoltage:
        list.addAll(['AC_OUTPUT_VOLTAGE']);
        break;
      case GraphMetric.acOutputCurrent:
        list.addAll(['AC_OUTPUT_CURRENT']);
        break;
      case GraphMetric.batterySoc:
        list.addAll(['BATTERY_SOC_PERCENT', 'SOC']);
        break;
    }
    // Deduplicate while preserving order
    final seen = <String>{};
    return [
      for (final p in list)
        if (seen.add(p)) p
    ];
  }

  // Aggregation rule per metric
  _Agg _aggregationForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
      case GraphMetric.loadPower:
      case GraphMetric.gridPower:
      case GraphMetric.pvInputCurrent:
      case GraphMetric.acOutputCurrent:
        return _Agg.sum;
      case GraphMetric.gridVoltage:
      case GraphMetric.gridFrequency:
      case GraphMetric.pvInputVoltage:
      case GraphMetric.acOutputVoltage:
      case GraphMetric.batterySoc:
        return _Agg.avg;
    }
  }

  // Load devices for the plant and prepare dropdown options
  Future<void> _loadDevices(String plantId) async {
    final devicesBundle = await _deviceRepo.getDevicesAndCollectors(plantId);
    final list = (devicesBundle['allDevices'] as List?) ?? [];
    _devices = list.map<DeviceRef>((d) {
      String sn;
      String pn;
      int devcode;
      int devaddr;
      String alias;
      if (d is Map) {
        sn = d['sn']?.toString() ?? '';
        pn = d['pn']?.toString() ?? '';
        devcode = int.tryParse(d['devcode']?.toString() ?? '') ?? 0;
        devaddr = int.tryParse(d['devaddr']?.toString() ?? '') ?? 0;
        alias = d['alias']?.toString() ?? d['devalias']?.toString() ?? pn;
      } else {
        try {
          // ignore: avoid_dynamic_calls
          sn = (d.sn)?.toString() ?? '';
          // ignore: avoid_dynamic_calls
          pn = (d.pn)?.toString() ?? '';
          // ignore: avoid_dynamic_calls
          devcode = int.tryParse((d.devcode)?.toString() ?? '') ?? 0;
          // ignore: avoid_dynamic_calls
          devaddr = int.tryParse((d.devaddr)?.toString() ?? '') ?? 0;
          // ignore: avoid_dynamic_calls
          alias = (d.alias)?.toString() ?? pn;
        } catch (_) {
          sn = '';
          pn = '';
          devcode = 0;
          devaddr = 0;
          alias = pn;
        }
      }
      return DeviceRef(
          sn: sn, pn: pn, devcode: devcode, devaddr: devaddr, alias: alias);
    }).toList();
    // Preserve selection if still present
    if (_selectedDevice != null) {
      _selectedDevice = _devices.firstWhere(
          (x) => x.key == _selectedDevice!.key,
          orElse: () =>
              _devices.isNotEmpty ? _devices.first : _selectedDevice!);
    }
  }

  // Change selected device by key
  Future<void> setSelectedDevice(String key, {required String plantId}) async {
    if (key.isEmpty) {
      _selectedDevice = null; // All devices
    } else {
      if (_devices.isEmpty) {
        _selectedDevice = null;
      } else {
        final match = _devices.firstWhere(
          (d) => d.key == key,
          orElse: () => _devices.first,
        );
        _selectedDevice = match;
      }
    }
    await refresh(plantId: plantId);
  }

  // Initialize for a fixed device (device detail screen)
  Future<void> initForDevice(
      {required DeviceRef device, required String plantId}) async {
    _devices = [device];
    _selectedDevice = device;
    await refresh(plantId: plantId);
  }

  // Helper: get hourly values for a device and date
  Future<List<double>> _deviceDailyForDate({
    required DeviceRef device,
    required GraphMetric metric,
    required String date,
  }) async {
    final deviceVm = getIt<vm.DeviceViewModel>();
    final param = _mapMetricToDeviceParameter(metric);
    final data = await deviceVm.fetchDeviceKeyParameterOneDay(
      sn: device.sn,
      pn: device.pn,
      devcode: device.devcode,
      devaddr: device.devaddr,
      parameter: param,
      date: date,
    );
    final values = List<double>.filled(24, 0);
    if (data != null && data.dat != null && data.dat!.row != null) {
      for (final row in data.dat!.row!) {
        final timeStr = row.time ?? '00:00';
        final parts = timeStr.split(':');
        final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
        if (hour < 0 || hour > 23) continue;
        final v = (row.field != null && row.field!.isNotEmpty)
            ? (double.tryParse(row.field!.first.toString()) ?? 0.0)
            : 0.0;
        values[hour] = v;
      }
    }
    return values;
  }

  // Ensure the anchor does not exceed "now" for the selected period
  void _clampAnchorToNow() {
    final now = DateTime.now();
    switch (_period) {
      case GraphPeriod.day:
        final today = DateTime(now.year, now.month, now.day);
        final proposed = DateTime(_anchor.year, _anchor.month, _anchor.day);
        if (proposed.isAfter(today)) {
          _anchor = today;
        }
        break;
      case GraphPeriod.month:
        final currentMonth = DateTime(now.year, now.month, 1);
        final proposedMonth = DateTime(_anchor.year, _anchor.month, 1);
        if (proposedMonth.isAfter(currentMonth)) {
          _anchor = currentMonth;
        }
        break;
      case GraphPeriod.year:
        final currentYear = DateTime(now.year, 1, 1);
        final proposedYear = DateTime(_anchor.year, 1, 1);
        if (proposedYear.isAfter(currentYear)) {
          _anchor = currentYear;
        }
        break;
    }
  }

  bool _sameBucket(DateTime a, DateTime b) {
    switch (_period) {
      case GraphPeriod.day:
        return a.year == b.year && a.month == b.month && a.day == b.day;
      case GraphPeriod.month:
        return a.year == b.year && a.month == b.month;
      case GraphPeriod.year:
        return a.year == b.year;
    }
  }
}

// A simple device reference for selection and API calls
class DeviceRef {
  final String sn;
  final String pn;
  final int devcode;
  final int devaddr;
  final String alias;
  DeviceRef(
      {required this.sn,
      required this.pn,
      required this.devcode,
      required this.devaddr,
      required this.alias});
  String get key => '$pn|$sn|$devcode|$devaddr';
}

class _Stats {
  final double min;
  final double max;
  final double avg;
  _Stats(this.min, this.max, this.avg);
}

enum _Agg { sum, avg }
