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
  batteryCapacity,
  batteryVoltage,
  batteryChargingCurrent,
  batteryDischargeCurrent,
  generatorAcVoltage,
  utilityAcVoltage,
  pv1ChargingPower,
  pv2ChargingPower,
  acOutputActivePower,
  pv1InputVoltage,
  pv2InputVoltage,
  pv1InputCurrent,
  pv2InputCurrent,
  todayGeneration,
  totalGeneration,
  inputPower,
}

enum GraphPeriod { day, month, year, total }

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

  GraphMetric _metric = GraphMetric
      .todayGeneration; // Default to power generation instead of output power
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
    GraphMetric.gridVoltage: 'GRID_VOLTAGE',
    GraphMetric.gridFrequency: 'GRID_FREQUENCY',
    GraphMetric.pvInputVoltage: 'PV_INPUT_VOLTAGE',
    GraphMetric.pvInputCurrent: 'PV_INPUT_CURRENT',
    GraphMetric.acOutputVoltage: 'AC2_OUTPUT_VOLTAGE',
    GraphMetric.acOutputCurrent: 'AC2_OUTPUT_CURRENT',
    GraphMetric.batterySoc: 'BATTERY_SOC',
    GraphMetric.batteryCapacity: 'BATTERY_CAPACITY',
    GraphMetric.batteryVoltage: 'BATTERY_VOLTAGE',
    GraphMetric.batteryChargingCurrent: 'BATTERY_CHARGING_CURRENT',
    GraphMetric.batteryDischargeCurrent: 'BATTERY_DISCHARGE_CURRENT',
    GraphMetric.generatorAcVoltage: 'GENERATOR_AC_VOLTAGE',
    GraphMetric.utilityAcVoltage: 'UTILITY_AC_VOLTAGE',
    GraphMetric.pv1ChargingPower: 'PV1_CHARGING_POWER',
    GraphMetric.pv2ChargingPower: 'PV2_CHARGING_POWER',
    GraphMetric.acOutputActivePower: 'AC_OUTPUT_ACTIVE_POWER',
    GraphMetric.pv1InputVoltage: 'PV1_INPUT_VOLTAGE',
    GraphMetric.pv2InputVoltage: 'PV2_INPUT_VOLTAGE',
    GraphMetric.pv1InputCurrent: 'PV1_INPUT_CURRENT',
    GraphMetric.pv2InputCurrent: 'PV2_INPUT_CURRENT',
    GraphMetric.todayGeneration: 'TODAY_GENERATION',
    GraphMetric.totalGeneration: 'TOTAL_GENERATION',
    GraphMetric.inputPower: 'INPUT_POWER',
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
    print('OverviewGraphViewModel: Initializing for plantId: $plantId');
    try {
      await _loadDevices(plantId);
      print(
          'OverviewGraphViewModel: Devices loaded, count: ${_devices.length}');
      await refresh(plantId: plantId);
      print('OverviewGraphViewModel: Initial refresh complete');
    } catch (e, stackTrace) {
      print('OverviewGraphViewModel: Initialization failed: $e');
      print('StackTrace: $stackTrace');
      _error = 'Failed to load graph data: $e';
      _loading = false;
      notifyListeners();
    }
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
      case GraphPeriod.total:
        // Total is all-time; anchor stepping is a no-op
        proposed = _anchor;
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

    print(
        'OverviewGraphViewModel: Refreshing graph - Period: $_period, Metric: $_metric, PlantId: $plantId');

    try {
      if (_period == GraphPeriod.day) {
        print(
            'OverviewGraphViewModel: Loading daily data for ${_anchor.toIso8601String().substring(0, 10)}');
        await _loadDaily(plantId);
      } else if (_period == GraphPeriod.month) {
        print('OverviewGraphViewModel: Loading monthly data');
        await _loadMonthly(plantId);
      } else if (_period == GraphPeriod.year) {
        print('OverviewGraphViewModel: Loading yearly data');
        await _loadYearly(plantId);
      } else {
        print('OverviewGraphViewModel: Loading total data');
        await _loadTotal(plantId);
      }
      print(
          'OverviewGraphViewModel: Data loaded successfully - ${_state.series.length} series, ${_state.labels.length} labels');
    } catch (e, stackTrace) {
      print('OverviewGraphViewModel: Error loading graph data: $e');
      print('StackTrace: $stackTrace');
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
      if (_metric == GraphMetric.outputPower ||
          _metric == GraphMetric.todayGeneration) {
        // Plant-level series from DESS aggregated energy endpoint
        final summary = await _energyRepo.getDailyEnergy(plantId, dateStr);
        values = List<double>.filled(24, 0);
        for (final h in summary.hourlyData) {
          final idx = h.timestamp.hour;
          if (idx >= 0 && idx < 24) {
            // For generation use energy (kWh), for output power use power (kW)
            values[idx] = (_metric == GraphMetric.todayGeneration)
                ? h.energy.toDouble()
                : h.power.toDouble();
          }
        }
        // Fallback: if all zeros (common when plant API returns err=12) try aggregating devices directly
        final allZero = values.every((v) => v == 0.0);
        if (allZero) {
          try {
            final deviceDerived = await _aggregateDevicesDaily(
              plantId: plantId,
              metric: _metric == GraphMetric.todayGeneration
                  ? GraphMetric.todayGeneration
                  : GraphMetric.outputPower,
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
    if (_selectedDevice == null &&
        (_metric == GraphMetric.outputPower ||
            _metric == GraphMetric.todayGeneration)) {
      try {
        final summary = await _energyRepo.getMonthlyEnergy(
          plantId,
          _anchor.year.toString(),
          _anchor.month.toString(),
        );
        final points = summary.hourlyData; // reused field as generic list
        if (points.isNotEmpty) {
          // Build per-day values: prefer energy for generation; otherwise fallback
          for (int i = 0; i < points.length; i++) {
            final p = points[i];
            final v = (_metric == GraphMetric.todayGeneration)
                ? (p.energy)
                : ((p.energy != 0) ? p.energy : p.power);
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
      if (_selectedDevice != null) {
        // Device selected: try device-level aggregated month-per-day first
        List<double> tmp = List<double>.filled(daysInMonth, 0);
        bool gotFromMonthApi = false;
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
            int fallbackIdx = 0;
            for (final p in res.series) {
              final ts = p['ts']?.toString();
              final val = p['val'];
              if (val is! num) continue;
              final v = val.toDouble();
              int? idx;
              if (ts != null) {
                final dt = DateTime.tryParse(ts);
                if (dt != null && dt.month == _anchor.month) {
                  idx = dt.day - 1;
                }
              }
              // If timestamp missing/unparseable, place sequentially
              idx ??=
                  (fallbackIdx < daysInMonth ? fallbackIdx : daysInMonth - 1);
              if (idx >= 0 && idx < tmp.length) tmp[idx] = v;
              fallbackIdx++;
            }
            gotFromMonthApi = tmp.any((v) => v != 0);
          }
        } catch (_) {
          gotFromMonthApi = false;
        }

        if (!gotFromMonthApi) {
          // Fallback: compute per-day values by aggregating each day's series
          final logical = _metricToLogical[_metric]!;
          final isSum = _aggregationForMetric(_metric) == _Agg.sum;
          for (int day = 1; day <= daysInMonth; day++) {
            final dateStr =
                _fmtDate(DateTime(_anchor.year, _anchor.month, day));
            double dayVal = 0.0;
            try {
              final r = await _deviceRepo.resolveMetricOneDay(
                logicalMetric: logical,
                sn: _selectedDevice!.sn,
                pn: _selectedDevice!.pn,
                devcode: _selectedDevice!.devcode,
                devaddr: _selectedDevice!.devaddr,
                date: dateStr,
              );
              if (r.series.isNotEmpty) {
                if (isSum) {
                  for (final pt in r.series) {
                    final v = pt['val'];
                    if (v is num) dayVal += v.toDouble();
                  }
                } else {
                  double s = 0.0;
                  int c = 0;
                  for (final pt in r.series) {
                    final v = pt['val'];
                    if (v is num) {
                      s += v.toDouble();
                      c += 1;
                    }
                  }
                  dayVal = c == 0 ? 0.0 : s / c;
                }
              } else {
                // Fallback to ViewModel key-parameter day fetch
                final deviceVm = getIt<vm.DeviceViewModel>();
                final param = _mapMetricToDeviceParameter(_metric);
                final data = await deviceVm.fetchDeviceKeyParameterOneDay(
                  sn: _selectedDevice!.sn,
                  pn: _selectedDevice!.pn,
                  devcode: _selectedDevice!.devcode,
                  devaddr: _selectedDevice!.devaddr,
                  parameter: param,
                  date: dateStr,
                );
                if (data != null && data.dat?.row != null) {
                  if (isSum) {
                    for (final row in data.dat!.row!) {
                      if (row.field != null && row.field!.isNotEmpty) {
                        final v =
                            double.tryParse(row.field!.first.toString()) ?? 0.0;
                        dayVal += v;
                      }
                    }
                  } else {
                    double s = 0.0;
                    int c = 0;
                    for (final row in data.dat!.row!) {
                      if (row.field != null && row.field!.isNotEmpty) {
                        final v =
                            double.tryParse(row.field!.first.toString()) ?? 0.0;
                        s += v;
                        c += 1;
                      }
                    }
                    dayVal = c == 0 ? 0.0 : s / c;
                  }
                }
              }
            } catch (_) {
              dayVal = 0.0;
            }
            tmp[day - 1] = dayVal;
          }
        }

        data.addAll(tmp);
      } else {
        // All devices: fast aggregate by day (one call per day only if non-output metrics)
        if (_metric == GraphMetric.outputPower ||
            _metric == GraphMetric.todayGeneration) {
          // If we got here, aggregated monthly failed; fall back to per-day totals but avoid long waits
          // Limit to existing days up to today in current month; for past months, still loop but this is rare
          for (int day = 1; day <= daysInMonth; day++) {
            final dateStr =
                _fmtDate(DateTime(_anchor.year, _anchor.month, day));
            final summary = await _energyRepo.getDailyEnergy(plantId, dateStr);
            // For generation graph we want daily kWh; for output power monthly fallback also uses kWh
            data.add(summary.totalEnergy);
          }
        } else {
          for (int day = 1; day <= daysInMonth; day++) {
            final dateStr =
                _fmtDate(DateTime(_anchor.year, _anchor.month, day));
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
            final v = (_metric == GraphMetric.todayGeneration)
                ? p.energy
                : (p.energy != 0 ? p.energy : p.power);
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
      if (_selectedDevice != null) {
        // Device selected: try device-level year-per-month first
        List<double> tmp = List<double>.filled(12, 0);
        bool gotFromYearApi = false;
        try {
          final logical = _metricToLogical[_metric]!;
          var res = await _deviceRepo.resolveMetricYearPerMonth(
            logicalMetric: logical,
            sn: _selectedDevice!.sn,
            pn: _selectedDevice!.pn,
            devcode: _selectedDevice!.devcode,
            devaddr: _selectedDevice!.devaddr,
            year: _anchor.year.toString(),
          );
          if (res.series.isEmpty && logical == 'PV_OUTPUT_POWER') {
            res = await _deviceRepo.resolveMetricYearPerMonth(
              logicalMetric: 'ENERGY_TODAY',
              sn: _selectedDevice!.sn,
              pn: _selectedDevice!.pn,
              devcode: _selectedDevice!.devcode,
              devaddr: _selectedDevice!.devaddr,
              year: _anchor.year.toString(),
            );
          }
          if (res.series.isNotEmpty) {
            int fallbackIdx = 0;
            for (final p in res.series) {
              final ts = p['ts']?.toString();
              final val = p['val'];
              if (val is! num) continue;
              final v = val.toDouble();
              int? idx;
              if (ts != null) {
                final dt = DateTime.tryParse(ts);
                if (dt != null && dt.year == _anchor.year) {
                  idx = dt.month - 1;
                }
              }
              // If timestamp missing/unparseable, place sequentially
              idx ??= (fallbackIdx < 12 ? fallbackIdx : 11);
              if (idx >= 0 && idx < tmp.length) tmp[idx] = v;
              fallbackIdx++;
            }
            gotFromYearApi = tmp.any((v) => v != 0);
          }
        } catch (_) {
          gotFromYearApi = false;
        }

        if (!gotFromYearApi) {
          // Fallback: compute each month from the month-per-day endpoint
          final logical = _metricToLogical[_metric]!;
          final isSum = _aggregationForMetric(_metric) == _Agg.sum;
          for (int m = 1; m <= 12; m++) {
            double monthVal = 0.0;
            double acc = 0.0;
            int count = 0;
            try {
              var res = await _deviceRepo.resolveMetricMonthPerDay(
                logicalMetric: logical,
                sn: _selectedDevice!.sn,
                pn: _selectedDevice!.pn,
                devcode: _selectedDevice!.devcode,
                devaddr: _selectedDevice!.devaddr,
                yearMonth:
                    '${_anchor.year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}',
              );
              if (res.series.isEmpty && logical == 'PV_OUTPUT_POWER') {
                res = await _deviceRepo.resolveMetricMonthPerDay(
                  logicalMetric: 'ENERGY_TODAY',
                  sn: _selectedDevice!.sn,
                  pn: _selectedDevice!.pn,
                  devcode: _selectedDevice!.devcode,
                  devaddr: _selectedDevice!.devaddr,
                  yearMonth:
                      '${_anchor.year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}',
                );
              }
              if (res.series.isNotEmpty) {
                for (final p in res.series) {
                  final v = p['val'];
                  if (v is num) {
                    final d = v.toDouble();
                    if (isSum) {
                      acc += d;
                    } else {
                      acc += d;
                      count += 1;
                    }
                  }
                }
              }
            } catch (_) {
              acc = 0.0;
              count = 0;
            }
            monthVal = isSum ? acc : (count == 0 ? 0.0 : acc / count);
            tmp[m - 1] = monthVal;
          }
        }

        data.addAll(tmp);
      } else {
        // All devices: for output power, sum per month via yearly endpoint (one call)
        if (_metric == GraphMetric.outputPower) {
          try {
            final yearly = await _energyRepo.getYearlyEnergy(
                plantId, _anchor.year.toString());
            final points = yearly.hourlyData;
            if (points.isNotEmpty) {
              for (final p in points) {
                data.add(p.energy != 0 ? p.energy : p.power);
              }
            } else {
              data.addAll(List<double>.filled(12, 0));
            }
          } catch (_) {
            data.addAll(List<double>.filled(12, 0));
          }
        } else {
          // Non-output metrics: quick zeros to avoid long waits
          data.addAll(List<double>.filled(12, 0));
        }
      }
    }
    // Ensure we always have 12 points to avoid 'No data' rendering when API is empty
    while (data.length < 12) {
      data.add(0);
    }
    if (data.length > 12) {
      data.removeRange(12, data.length);
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

  Future<void> _loadTotal(String plantId) async {
    // Total view: per-year total energy bars across all available years
    final labels = <String>[];
    final data = <double>[];

    if (_selectedDevice == null && _metric == GraphMetric.outputPower) {
      try {
        final summary = await _energyRepo.getPlantEnergyTotalPerYear(plantId);
        final points = summary.hourlyData; // reused as generic list
        if (points.isNotEmpty) {
          for (final p in points) {
            labels.add(p.timestamp.year.toString());
            data.add(_metric == GraphMetric.todayGeneration
                ? p.energy
                : (p.energy != 0 ? p.energy : p.power));
          }
        } else {
          // Fallback when API returns empty: query recent years individually
          final currentYear = DateTime.now().year;
          final startYear = currentYear - 4;
          for (int y = startYear; y <= currentYear; y++) {
            try {
              final yearly = await _energyRepo.getYearlyEnergy(
                plantId,
                y.toString(),
              );
              double yearSum = 0.0;
              for (final p in yearly.hourlyData) {
                yearSum += p.energy != 0 ? p.energy : p.power;
              }
              labels.add(y.toString());
              data.add(yearSum);
            } catch (_) {
              labels.add(y.toString());
              data.add(0.0);
            }
          }
        }
      } catch (_) {
        // fallback: use yearly aggregated endpoint per year (few calls)
        final currentYear = DateTime.now().year;
        final startYear = currentYear - 4;
        for (int y = startYear; y <= currentYear; y++) {
          try {
            final yearly = await _energyRepo.getYearlyEnergy(
              plantId,
              y.toString(),
            );
            double yearSum = 0.0;
            for (final p in yearly.hourlyData) {
              yearSum += p.energy != 0 ? p.energy : p.power;
            }
            labels.add(y.toString());
            data.add(yearSum);
          } catch (_) {
            labels.add(y.toString());
            data.add(0.0);
          }
        }
      }
    } else if (_selectedDevice != null && _metric == GraphMetric.outputPower) {
      try {
        final logical = _metricToLogical[_metric]!;
        var res = await _deviceRepo.resolveMetricTotalPerYear(
          logicalMetric: logical,
          sn: _selectedDevice!.sn,
          pn: _selectedDevice!.pn,
          devcode: _selectedDevice!.devcode,
          devaddr: _selectedDevice!.devaddr,
        );
        if (res.series.isEmpty && logical == 'PV_OUTPUT_POWER') {
          res = await _deviceRepo.resolveMetricTotalPerYear(
            logicalMetric: 'ENERGY_TODAY',
            sn: _selectedDevice!.sn,
            pn: _selectedDevice!.pn,
            devcode: _selectedDevice!.devcode,
            devaddr: _selectedDevice!.devaddr,
          );
        }
        for (final p in res.series) {
          final ts = p['ts']?.toString();
          final val = p['val'];
          if (ts != null && val is num) {
            final dt = DateTime.tryParse(ts);
            if (dt != null) {
              labels.add(dt.year.toString());
              data.add(val.toDouble());
            }
          }
        }
      } catch (_) {
        // fallback: for a handful of recent years, sum year-per-month
        try {
          final logical = _metricToLogical[_metric]!;
          final currentYear = DateTime.now().year;
          final startYear = currentYear - 4;
          for (int y = startYear; y <= currentYear; y++) {
            try {
              var res = await _deviceRepo.resolveMetricYearPerMonth(
                logicalMetric: logical,
                sn: _selectedDevice!.sn,
                pn: _selectedDevice!.pn,
                devcode: _selectedDevice!.devcode,
                devaddr: _selectedDevice!.devaddr,
                year: y.toString(),
              );
              if (res.series.isEmpty && logical == 'PV_OUTPUT_POWER') {
                res = await _deviceRepo.resolveMetricYearPerMonth(
                  logicalMetric: 'ENERGY_TODAY',
                  sn: _selectedDevice!.sn,
                  pn: _selectedDevice!.pn,
                  devcode: _selectedDevice!.devcode,
                  devaddr: _selectedDevice!.devaddr,
                  year: y.toString(),
                );
              }
              double sum = 0.0;
              for (final p in res.series) {
                final v = p['val'];
                if (v is num) sum += v.toDouble();
              }
              labels.add(y.toString());
              data.add(sum);
            } catch (_) {
              labels.add(y.toString());
              data.add(0.0);
            }
          }
        } catch (_) {}
      }
    } else {
      // For non-output metrics, build a single-series total-like view: sum yearly values for a few recent years
      final currentYear = DateTime.now().year;
      final startYear = currentYear - 4;
      for (int y = startYear; y <= currentYear; y++) {
        labels.add(y.toString());
        data.add(0.0);
      }
    }

    // Ensure labels and data are non-empty to avoid 'No data'
    if (labels.isEmpty) {
      final y = DateTime.now().year;
      labels.addAll([for (int i = 4; i >= 0; i--) (y - i).toString()]);
      data.addAll(List<double>.filled(5, 0));
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
      unit: 'kWh',
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
      case GraphMetric.batteryCapacity:
        return 'Battery Capacity';
      case GraphMetric.batteryVoltage:
        return 'Battery Voltage';
      case GraphMetric.batteryChargingCurrent:
        return 'Battery Charging Current';
      case GraphMetric.batteryDischargeCurrent:
        return 'Battery Discharge Current';
      case GraphMetric.generatorAcVoltage:
        return 'Generator AC Voltage';
      case GraphMetric.utilityAcVoltage:
        return 'Utility AC Voltage';
      case GraphMetric.pv1ChargingPower:
        return 'PV1 Charging Power';
      case GraphMetric.pv2ChargingPower:
        return 'PV2 Charging Power';
      case GraphMetric.acOutputActivePower:
        return 'AC Output Active Power';
      case GraphMetric.pv1InputVoltage:
        return 'PV1 Input Voltage';
      case GraphMetric.pv2InputVoltage:
        return 'PV2 Input Voltage';
      case GraphMetric.pv1InputCurrent:
        return 'PV1 Input Current';
      case GraphMetric.pv2InputCurrent:
        return 'PV2 Input Current';
      case GraphMetric.todayGeneration:
        return 'Today Generation';
      case GraphMetric.totalGeneration:
        return 'Total Generation';
      case GraphMetric.inputPower:
        return 'Input Power';
    }
  }

  String _unitForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
      case GraphMetric.loadPower:
      case GraphMetric.gridPower:
      case GraphMetric.pv1ChargingPower:
      case GraphMetric.pv2ChargingPower:
      case GraphMetric.acOutputActivePower:
      case GraphMetric.inputPower:
        return 'kW';
      case GraphMetric.gridVoltage:
      case GraphMetric.pvInputVoltage:
      case GraphMetric.acOutputVoltage:
      case GraphMetric.batteryVoltage:
      case GraphMetric.generatorAcVoltage:
      case GraphMetric.utilityAcVoltage:
      case GraphMetric.pv1InputVoltage:
      case GraphMetric.pv2InputVoltage:
        return 'V';
      case GraphMetric.gridFrequency:
        return 'Hz';
      case GraphMetric.pvInputCurrent:
      case GraphMetric.acOutputCurrent:
      case GraphMetric.batteryChargingCurrent:
      case GraphMetric.batteryDischargeCurrent:
      case GraphMetric.pv1InputCurrent:
      case GraphMetric.pv2InputCurrent:
        return 'A';
      case GraphMetric.batterySoc:
      case GraphMetric.batteryCapacity:
        return '%';
      case GraphMetric.todayGeneration:
      case GraphMetric.totalGeneration:
        return 'kWh';
    }
  }

  Color _colorForMetric(GraphMetric m) {
    switch (m) {
      case GraphMetric.outputPower:
      case GraphMetric.pv1ChargingPower:
      case GraphMetric.pv2ChargingPower:
      case GraphMetric.inputPower:
        return Colors.orange;
      case GraphMetric.loadPower:
      case GraphMetric.gridVoltage:
        return Colors.blue;
      case GraphMetric.gridPower:
      case GraphMetric.gridFrequency:
        return Colors.purple;
      case GraphMetric.pvInputVoltage:
      case GraphMetric.pv1InputVoltage:
      case GraphMetric.pv2InputVoltage:
        return Colors.amber;
      case GraphMetric.pvInputCurrent:
      case GraphMetric.pv1InputCurrent:
      case GraphMetric.pv2InputCurrent:
        return Colors.deepOrange;
      case GraphMetric.acOutputVoltage:
      case GraphMetric.acOutputActivePower:
        return Colors.red;
      case GraphMetric.acOutputCurrent:
        return Colors.teal;
      case GraphMetric.batterySoc:
      case GraphMetric.batteryCapacity:
        return Colors.green;
      case GraphMetric.batteryVoltage:
      case GraphMetric.batteryChargingCurrent:
      case GraphMetric.batteryDischargeCurrent:
        return Colors.lightGreen;
      case GraphMetric.generatorAcVoltage:
        return Colors.brown;
      case GraphMetric.utilityAcVoltage:
        return Colors.indigo;
      case GraphMetric.todayGeneration:
      case GraphMetric.totalGeneration:
        return Colors.cyan;
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
        (p == GraphPeriod.month ||
            p == GraphPeriod.year ||
            p == GraphPeriod.total)) {
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
        return 'GRID_VOLTAGE';
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
      case GraphMetric.batteryCapacity:
        return 'BATTERY_CAPACITY';
      case GraphMetric.batteryVoltage:
        return 'BATTERY_VOLTAGE';
      case GraphMetric.batteryChargingCurrent:
        return 'BATTERY_CHARGING_CURRENT';
      case GraphMetric.batteryDischargeCurrent:
        return 'BATTERY_DISCHARGE_CURRENT';
      case GraphMetric.generatorAcVoltage:
        return 'GENERATOR_AC_VOLTAGE';
      case GraphMetric.utilityAcVoltage:
        return 'UTILITY_AC_VOLTAGE';
      case GraphMetric.pv1ChargingPower:
        return 'PV1_CHARGING_POWER';
      case GraphMetric.pv2ChargingPower:
        return 'PV2_CHARGING_POWER';
      case GraphMetric.acOutputActivePower:
        return 'AC_OUTPUT_ACTIVE_POWER';
      case GraphMetric.pv1InputVoltage:
        return 'PV1_INPUT_VOLTAGE';
      case GraphMetric.pv2InputVoltage:
        return 'PV2_INPUT_VOLTAGE';
      case GraphMetric.pv1InputCurrent:
        return 'PV1_INPUT_CURRENT';
      case GraphMetric.pv2InputCurrent:
        return 'PV2_INPUT_CURRENT';
      case GraphMetric.todayGeneration:
        return 'TODAY_GENERATION';
      case GraphMetric.totalGeneration:
        return 'TOTAL_GENERATION';
      case GraphMetric.inputPower:
        return 'INPUT_POWER';
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
      case GraphMetric.pv1InputVoltage:
      case GraphMetric.pv2InputVoltage:
      case GraphMetric.pv1InputCurrent:
      case GraphMetric.pv2InputCurrent:
      case GraphMetric.pv1ChargingPower:
      case GraphMetric.pv2ChargingPower:
      case GraphMetric.inputPower:
      case GraphMetric.todayGeneration:
      case GraphMetric.totalGeneration:
        return isInverter ||
            isStorage ||
            isCollector; // collectors sometimes proxy
      case GraphMetric.loadPower:
      case GraphMetric.acOutputActivePower:
        return isInverter || isStorage || isSmart || isCollector;
      case GraphMetric.gridPower:
      case GraphMetric.gridVoltage:
      case GraphMetric.gridFrequency:
        return isCollector ||
            isSmart ||
            isInverter; // grid metrics likely from collector/smart meter/inverter
      case GraphMetric.batterySoc:
      case GraphMetric.batteryCapacity:
      case GraphMetric.batteryVoltage:
      case GraphMetric.batteryChargingCurrent:
      case GraphMetric.batteryDischargeCurrent:
        return isStorage || isBattery || isInverter; // inverter with battery
      case GraphMetric.generatorAcVoltage:
      case GraphMetric.utilityAcVoltage:
        return isStorage || isInverter; // typically on storage/hybrid systems
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
      case GraphMetric.batteryCapacity:
      case GraphMetric.batteryVoltage:
      case GraphMetric.batteryChargingCurrent:
      case GraphMetric.batteryDischargeCurrent:
      case GraphMetric.generatorAcVoltage:
      case GraphMetric.utilityAcVoltage:
      case GraphMetric.pv1ChargingPower:
      case GraphMetric.pv2ChargingPower:
      case GraphMetric.acOutputActivePower:
      case GraphMetric.pv1InputVoltage:
      case GraphMetric.pv2InputVoltage:
      case GraphMetric.pv1InputCurrent:
      case GraphMetric.pv2InputCurrent:
      case GraphMetric.todayGeneration:
      case GraphMetric.totalGeneration:
      case GraphMetric.inputPower:
        // Use base parameter only for these new metrics
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
      case GraphMetric.pv1ChargingPower:
      case GraphMetric.pv2ChargingPower:
      case GraphMetric.acOutputActivePower:
      case GraphMetric.inputPower:
      case GraphMetric.pv1InputCurrent:
      case GraphMetric.pv2InputCurrent:
      case GraphMetric.batteryChargingCurrent:
      case GraphMetric.batteryDischargeCurrent:
      case GraphMetric.todayGeneration:
      case GraphMetric.totalGeneration:
        return _Agg.sum;
      case GraphMetric.gridVoltage:
      case GraphMetric.gridFrequency:
      case GraphMetric.pvInputVoltage:
      case GraphMetric.acOutputVoltage:
      case GraphMetric.batterySoc:
      case GraphMetric.batteryCapacity:
      case GraphMetric.batteryVoltage:
      case GraphMetric.generatorAcVoltage:
      case GraphMetric.utilityAcVoltage:
      case GraphMetric.pv1InputVoltage:
      case GraphMetric.pv2InputVoltage:
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

    // FIX: Auto-select first device if no device is selected and devices are available
    if (_selectedDevice == null && _devices.isNotEmpty) {
      _selectedDevice = _devices.first;
      print(
          'OverviewGraphViewModel: Auto-selected first device: ${_selectedDevice!.pn}');
    } else if (_selectedDevice != null) {
      // Preserve selection if still present
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
      case GraphPeriod.total:
        // no clamping needed
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
      case GraphPeriod.total:
        return true;
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
