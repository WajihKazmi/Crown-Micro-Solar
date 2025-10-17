import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;
import 'package:fl_chart/fl_chart.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/core/services/report_download_service.dart';
import 'package:crown_micro_solar/core/utils/navigation_service.dart';
import 'dart:ui' as ui;
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/overview_graph_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/metric_aggregator_view_model.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart'
    show DeviceEnergyFlowModel, DeviceEnergyFlowItem; // ensure model available
// Use the unified alarm notification screen (same as home) for consistent loading logic
import 'package:crown_micro_solar/view/home/alarm_notification_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:crown_micro_solar/view/home/data_control_old_screen.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/core/utils/device_model_config.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late final DeviceViewModel _deviceVM;
  late final RealtimeDataService _realtime;
  DeviceLiveSignalModel? _live;
  late final MetricAggregatorViewModel _metricAggVM;
  DeviceEnergyFlowModel? _energyFlow;
  bool _loading = true;
  bool _hasData = false;
  String? _err;
  DateTime _anchorDate = DateTime.now();
  Timer? _refreshTimer;
  Timer? _heavyOnceTimer;
  bool _isFetching = false;
  String? _lastFlowKey;
  bool _graphEnabled = false;
  final Map<String, String> _selectedParByCategory =
      {}; // pv|battery|load|grid -> selected par label
  final Map<String, String> _latestPagingValues =
      {}; // UI Label -> formatted value

  String _computeFlowKey(DeviceEnergyFlowModel? flow) {
    if (flow == null) return 'empty';
    final pvOn = (flow.pvVoltage ?? 0) > 50 || (flow.pvPower ?? 0) > 50;
    final gridOn = (flow.gridVoltage ?? 0) > 50;
    final batOn = (flow.batteryVoltage ?? 0) > 20 || (flow.batterySoc ?? 0) > 5;
    return '${pvOn ? 1 : 0}${gridOn ? 1 : 0}${batOn ? 1 : 0}';
  }

  @override
  void initState() {
    super.initState();
    _deviceVM = getIt<DeviceViewModel>();
    _realtime = getIt<RealtimeDataService>();
    // Listen for realtime prefetch updates to paint instantly when available
    _realtime.addListener(_onRealtimeUpdated);
    final repo = getIt<DeviceRepository>();
    _metricAggVM = MetricAggregatorViewModel(
      deviceRepository: repo,
      sn: widget.device.sn,
      pn: widget.device.pn,
      devcode: widget.device.devcode,
      devaddr: widget.device.devaddr,
    );
    // Persist last opened PN to prioritize prefetch on next app start (fire-and-forget)
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastOpenedPn', widget.device.pn);
      } catch (_) {}
    }();
    // Show cached energy flow instantly if we already have it
    DeviceEnergyFlowModel? cached =
        _realtime.snapshotEnergyFlow(widget.device.pn);
    if (cached != null) {
      _energyFlow = cached;
      _lastFlowKey = _computeFlowKey(cached);
      _hasData = true;
      _loading = false;
    } else {
      // Restore last-known snapshot from prefs if available (async, non-blocking)
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString('energyFlow:${widget.device.pn}');
          if (raw != null && raw.isNotEmpty && mounted) {
            final map = Map<String, dynamic>.from(jsonDecode(raw));
            final restored = DeviceEnergyFlowModel.fromJson(map);
            setState(() {
              _energyFlow = restored;
              _lastFlowKey = _computeFlowKey(restored);
              _hasData = true;
              _loading = false;
            });
          }
        } catch (_) {}
      }();
    }
    // Warm cache for energy flow immediately to speed up grid/pv cards
    _realtime.prefetchEnergyFlow(widget.device);
    // Kick fast phase: if we have cached flow, avoid spinner flicker
    _fetch(silent: cached != null);
    // Schedule a one-off heavy phase after UI settles
    _heavyOnceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _graphEnabled = true; // enable graph rendering after heavy starts
      final date = DateFormat('yyyy-MM-dd').format(_anchorDate);
      _fetchHeavy(date: date);
      setState(() {});
    });
    // Lightweight periodic refresh for live/flow; avoid heavy calls every tick
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _fetch(silent: true);
    });
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeUpdated);
    _refreshTimer?.cancel();
    _heavyOnceTimer?.cancel();
    super.dispose();
  }

  void _onRealtimeUpdated() {
    if (!mounted) return;
    final updated = _realtime.snapshotEnergyFlow(widget.device.pn);
    if (updated == null) return;
    final newKey = _computeFlowKey(updated);
    if (_lastFlowKey == newKey && _energyFlow != null)
      return; // no visual change
    setState(() {
      _energyFlow = updated;
      _lastFlowKey = newKey;
      _hasData = true;
      _loading = false;
    });
  }

  Future<void> _fetch({bool silent = false}) async {
    if (_isFetching) return; // skip if a fetch is already in flight
    _isFetching = true;
    if (!silent) {
      setState(() {
        _loading = true;
        _err = null;
      });
    }
    // Heavy phase date is computed when scheduled; no need here
    final repo = getIt<DeviceRepository>();
    // Phase 1: fast fetches (live + energy flow)
    int pending = 2;
    bool anySuccess = false;
    void done() {
      pending -= 1;
      if (pending <= 0) {
        _isFetching = false;
        if (!mounted) return;
        if (!anySuccess && !silent) {
          setState(() {
            _loading = false;
            _err = _err ?? 'Failed to load device data';
          });
        }
      }
    }

    // Live signal
    () async {
      try {
        final live = await _deviceVM.fetchDeviceLiveSignal(
          sn: widget.device.sn,
          pn: widget.device.pn,
          devcode: widget.device.devcode,
          devaddr: widget.device.devaddr,
        );
        if (!mounted) return;
        setState(() {
          _live = live;
          _hasData = true;
          _loading = false; // first successful response hides spinner
          anySuccess = true;
        });
      } catch (e) {
        // ignore individual errors
      } finally {
        done();
      }
    }();

    // Energy flow (prefer cached snapshot first to render instantly)
    () async {
      try {
        // Immediate snapshot was already applied in initState; keep here as safety
        final cached = _realtime.snapshotEnergyFlow(widget.device.pn);
        if (cached != null && mounted) {
          setState(() {
            _energyFlow = cached;
            _lastFlowKey = _computeFlowKey(cached);
            _hasData = true;
            _loading = false;
            anySuccess = true;
          });
        }
        // Kick an async refresh in background while UI shows cached
        final flow = await repo.fetchDeviceEnergyFlow(
          sn: widget.device.sn,
          pn: widget.device.pn,
          devcode: widget.device.devcode,
          devaddr: widget.device.devaddr,
        );
        if (!mounted) return;
        final newKey = _computeFlowKey(flow);
        setState(() {
          _energyFlow = flow;
          _lastFlowKey = newKey;
          _hasData = true;
          _loading = false;
          anySuccess = true;
        });
        // Update realtime cache to benefit other screens
        if (flow != null) {
          _realtime.deviceEnergyFlow[widget.device.pn] = flow;
        }
      } catch (e) {
      } finally {
        done();
      }
    }();

    // Heavy operations (metrics + paging) are moved to _fetchHeavy and not
    // executed during the initial fast phase or silent refreshes.
  }

  Future<void> _fetchHeavy({required String date}) async {
    final repo = getIt<DeviceRepository>();
    // Run both in parallel but do not change global loading flags
    await Future.wait([
      () async {
        try {
          await _metricAggVM.resolveMetrics([
            'PV_OUTPUT_POWER',
            'PV_INPUT_VOLTAGE',
            'AC2_OUTPUT_VOLTAGE',
            'BATTERY_SOC',
            'LOAD_POWER',
            'GRID_POWER',
            'GRID_FREQUENCY',
          ], date: date);
          if (!mounted) return;
          setState(() {}); // metrics available for UI/graphs
        } catch (_) {}
      }(),
      () async {
        try {
          final paging = await repo.fetchDeviceDataOneDayPaging(
            sn: widget.device.sn,
            pn: widget.device.pn,
            devcode: widget.device.devcode,
            devaddr: widget.device.devaddr,
            date: date,
            page: 0,
            pageSize: 200,
          );
          if (!mounted) return;
          setState(() {
            _latestPagingValues
              ..clear()
              ..addAll(_buildLatestFromPaging(paging));
          });
        } catch (_) {}
      }(),
    ]);
  }

  Map<String, String> _buildLatestFromPaging(Map<String, dynamic>? paging) {
    final res = <String, String>{};
    if (paging == null) return res;
    try {
      final dat = paging['dat'];
      if (dat is! Map) return res;
      final titles = (dat['title'] as List?)
              ?.map((e) => (e as Map)['title']?.toString() ?? '')
              .toList() ??
          [];
      final rows = (dat['row'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (titles.isEmpty || rows.isEmpty) return res;
      final last = rows.last;
      final field = (last['field'] as List?) ?? const [];

      int idxOf(List<String> candidates) {
        for (final cand in candidates) {
          final idx = titles.indexWhere(
              (t) => t.toLowerCase().trim() == cand.toLowerCase().trim());
          if (idx != -1) return idx;
        }
        return -1;
      }

      num? toNum(dynamic x) => x is num ? x : num.tryParse(x?.toString() ?? '');

      String fmtNum(num? v, String unit, {int prec1 = 1, int prec2 = 2}) {
        if (v == null) return '--';
        final d = v.toDouble();
        String n;
        final abs = d.abs();
        if (unit == 'W' && abs >= 1000) {
          return '${(d / 1000).toStringAsFixed(1)} kW';
        }
        if (abs >= 100)
          n = d.toStringAsFixed(0);
        else if (abs >= 10)
          n = d.toStringAsFixed(prec1);
        else
          n = d.toStringAsFixed(prec2);
        return unit.isNotEmpty ? '$n $unit' : n;
      }

      void setBy(List<String> candidates, String uiLabel, String unit,
          {bool assumeKWForPower = true}) {
        final idx = idxOf(candidates);
        if (idx != -1 && idx < field.length) {
          final raw = field[idx];
          num? v = toNum(raw);
          if (assumeKWForPower && unit == 'W' && v != null && v <= 50) {
            res[uiLabel] = fmtNum(v * 1000, unit);
            return;
          }
          res[uiLabel] = fmtNum(v, unit);
        }
      }

      // PV
      setBy(
          ['PV1 Input Voltage', 'PV1 Input voltage'], 'PV1 Input Voltage', 'V');
      setBy(['PV1 Charging Power', 'PV1 Input Power', 'PV1 Active Power'],
          'PV1 Input Power (Watts)', 'W');
      setBy(
          ['PV2 Input Voltage', 'PV2 Input voltage'], 'PV2 Input Voltage', 'V');
      setBy(['PV2 Charging power', 'PV2 Input Power', 'PV2 Active Power'],
          'PV2 Input Power (Watts)', 'W');

      // Battery
      setBy(['Battery Voltage'], 'Battery Voltage', 'V');
      setBy(['Battery Capacity'], 'Battery Capacity (%)', '%');
      setBy(['Battery charging current'], 'Battery Charging Current (A)', 'A',
          assumeKWForPower: false);
      setBy([
        'Battery discharging current'
      ], 'Battery Discharging Current (A)', 'A', assumeKWForPower: false);
      final btTypeIdx = idxOf(['Battery Type']);
      if (btTypeIdx != -1 && btTypeIdx < field.length) {
        res['Battery Type'] = (field[btTypeIdx]?.toString() ?? '--');
      }

      // Load
      final loadStatusIdx = idxOf(['Load Status']);
      if (loadStatusIdx != -1 && loadStatusIdx < field.length) {
        res['Load Status'] = (field[loadStatusIdx]?.toString() ?? '--');
      }
      setBy(['AC Output Voltage', 'AC1 Output Voltage'], 'AC Output Voltage',
          'V');
      setBy(['AC Output Frequency', 'AC1 Output Frequency'],
          'AC Output Frequency (Hz)', 'Hz');
      setBy(['AC2 Output Voltage'], 'Second Output Voltage', 'V');
      setBy(['AC2 Output Frequency'], 'Second Output Frequency (Hz)', 'Hz');
      setBy([
        'AC Output Active Power',
        'Load Active Power',
        'Output Active Power'
      ], 'AC Output Active Power (W)', 'W');
      setBy(['Output Load Percentage', 'Output Load %'],
          'Output Load Percentage (%)', '%');

      // Grid
      setBy(['Grid Voltage'], 'Grid Voltage', 'V');
      setBy(
          ['Grid Frequency', 'AC Grid Frequency'], 'Grid Frequency (Hz)', 'Hz');
      final acInputIdx = idxOf(['AC Input Range', 'AC input range']);
      if (acInputIdx != -1 && acInputIdx < field.length) {
        res['AC Input Range (APL/UPS)'] = field[acInputIdx]?.toString() ?? '--';
      }
    } catch (_) {}
    return res;
  }

  String _fmtPowerW(double? w) {
    if (w == null) return '--';
    if (w.abs() < 1) return '0 W';
    if (w.abs() < 1000) return '${w.toStringAsFixed(0)} W';
    return '${(w / 1000).toStringAsFixed(1)} kW';
  }

  String _fmtVoltageOrPower(double? v) {
    if (v == null) return '--';
    if (v >= 10 && v <= 800) {
      return '${v.toStringAsFixed(0)} V';
    }
    return _fmtPowerW(v);
  }

  String _fmtVoltage(double? v) {
    if (v == null) return '--';
    return '${v.toStringAsFixed(0)} V';
  }

  String _fmtSoc(double? s) {
    if (s == null) return '--';
    return '${s.toStringAsFixed(0)}%';
  }

  // Parse a numeric from latest paging snapshot by label list; strips units
  double? _numFromLatest(List<String> labels) {
    String? raw;
    for (final l in labels) {
      raw = _latestPagingValues[l];
      if (raw != null) break;
    }
    if (raw == null) return null;
    // Extract first number in the string (handles "12.3 kW", "230 V", "50 Hz")
    final m = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(raw);
    if (m == null) return null;
    final v = double.tryParse(m.group(1)!);
    // If in kW string, scale back to W for presence thresholds
    if (raw.toLowerCase().contains('kw') && v != null) return v * 1000.0;
    return v;
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        CollectorReportRange range = CollectorReportRange.daily;
        DateTime anchorDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setState) {
            Widget rangeChip(CollectorReportRange r, String label) {
              final selected = r == range;
              return InkWell(
                onTap: () => setState(() {
                  range = r;
                }),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            String formatDate(CollectorReportRange r, DateTime d) {
              switch (r) {
                case CollectorReportRange.daily:
                  return DateFormat('yyyy/MM/dd').format(d);
                case CollectorReportRange.monthly:
                  return DateFormat('yyyy/MM').format(d);
                case CollectorReportRange.yearly:
                  return DateFormat('yyyy').format(d);
              }
            }

            Future<void> onDownload() async {
              try {
                final service = ReportDownloadService();
                await service.downloadFullReportByCollector(
                  collectorPn: widget.device.pn,
                  range: range,
                  anchorDate: anchorDate,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report download started')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to download: $e')),
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gen.AppLocalizations.of(
                        context,
                      ).report_download_full_title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        rangeChip(
                          CollectorReportRange.daily,
                          gen.AppLocalizations.of(context).range_day,
                        ),
                        rangeChip(
                          CollectorReportRange.monthly,
                          gen.AppLocalizations.of(context).range_month,
                        ),
                        rangeChip(
                          CollectorReportRange.yearly,
                          gen.AppLocalizations.of(context).range_year,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: anchorDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => anchorDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatDate(range, anchorDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            gen.AppLocalizations.of(context).action_cancel,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onDownload,
                          child: Text(
                            gen.AppLocalizations.of(context).action_download,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Uniform summary metric cards
  Widget _summaryCards() {
    final pvPowerMetric = _metricAggVM.metric('PV_OUTPUT_POWER');
    final pvVoltageMetric = _metricAggVM.metric('PV_INPUT_VOLTAGE');
    final batSocMetric = _metricAggVM.metric('BATTERY_SOC');
    final loadPowerMetric = _metricAggVM.metric('LOAD_POWER');
    final gridPowerMetric = _metricAggVM.metric('GRID_POWER');
    final acOutVoltageMetric = _metricAggVM.metric('AC2_OUTPUT_VOLTAGE');
    final gridFreqMetric = _metricAggVM.metric('GRID_FREQUENCY');

    final pvVoltage = _energyFlow?.pvVoltage ?? pvVoltageMetric?.latestValue;
    final pvPower =
        _energyFlow?.pvPower ?? pvPowerMetric?.latestValue ?? _live?.inputPower;
    final loadVoltage = acOutVoltageMetric?.latestValue;
    final loadPower = _energyFlow?.loadPower ??
        loadPowerMetric?.latestValue ??
        _live?.outputPower;
    final gridVoltageVal = _energyFlow?.gridVoltage;
    final gridPowerVal = _energyFlow?.gridPower ?? gridPowerMetric?.latestValue;
    final gridFreqVal = gridFreqMetric?.latestValue;
    final batteryVoltage = _energyFlow?.batteryVoltage;
    final batSoc = _energyFlow?.batterySoc ??
        batSocMetric?.latestValue ??
        _live?.batteryLevel;

    String? _selectedValueFor(String category) {
      final sel = _selectedParByCategory[category];
      if (sel == null) return null;
      String selL = sel.trim().toLowerCase();
      DeviceEnergyFlowItem? it;
      List<DeviceEnergyFlowItem> listFor(String c) {
        switch (c) {
          case 'pv':
            return _energyFlow?.pvStatus ?? const [];
          case 'battery':
            return _energyFlow?.btStatus ?? const [];
          case 'load':
            return [...?_energyFlow?.bcStatus, ...?_energyFlow?.olStatus];
          case 'grid':
            return _energyFlow?.gdStatus ?? const [];
        }
        return const [];
      }

      final list = listFor(category);
      it = list.firstWhere(
        (e) => e.par.trim().toLowerCase() == selL,
        orElse: () => DeviceEnergyFlowItem(par: '', value: null),
      );
      if (it.par.isEmpty) {
        // try matching formatted label
        it = list.firstWhere(
          (e) => _formatLabel(e.par).trim().toLowerCase() == selL,
          orElse: () => DeviceEnergyFlowItem(par: '', value: null),
        );
      }
      if (it.par.isNotEmpty) {
        return _formatValueWithUnit(it.value, it.unit);
      }
      // fallback to paging latest values by canonical UI label
      final v = _latestPagingValues[sel];
      if (v != null) return v;
      return null;
    }

    final rawCards = <Map<String, Object?>>[];
    if (pvVoltage != null || pvPower != null) {
      final selected = _selectedValueFor('pv');
      final pvCurrent = _energyFlow?.pvCurrent;
      rawCards.add({
        'title': 'PV',
        'value': selected ?? _fmtVoltageOrPower(pvVoltage ?? pvPower),
        'subtitle': selected != null
            ? _formatLabel(_selectedParByCategory['pv'] ?? '')
            : (pvVoltage != null && pvPower != null
                ? _fmtPowerW(pvPower)
                : null),
        'extraInfo': selected == null && pvVoltage != null && pvCurrent != null
            ? '${_fmtVoltage(pvVoltage)} / ${pvCurrent.toStringAsFixed(1)}A'
            : null,
        'icon': Icons.solar_power,
        'key': 'pv',
      });
    }
    if (batteryVoltage != null || batSoc != null) {
      final selected = _selectedValueFor('battery');
      rawCards.add({
        'title': 'Battery',
        'value': selected ??
            (batteryVoltage != null
                ? _fmtVoltage(batteryVoltage)
                : _fmtSoc(batSoc)),
        'subtitle': () {
          if (selected != null)
            return _formatLabel(_selectedParByCategory['battery'] ?? '');
          if (batteryVoltage != null && batSoc != null) return _fmtSoc(batSoc);
          final pw = _energyFlow?.batteryPower;
          if (batteryVoltage == null && pw != null && pw.abs() > 0) {
            return _fmtPowerW(pw);
          }
          return null;
        }(),
        'icon': Icons.battery_full,
        'key': 'battery',
      });
    }
    if (loadVoltage != null || loadPower != null) {
      final selected = _selectedValueFor('load');
      rawCards.add({
        'title': 'Load',
        'value': selected ?? _fmtVoltageOrPower(loadVoltage ?? loadPower),
        'subtitle': selected != null
            ? _formatLabel(_selectedParByCategory['load'] ?? '')
            : ((loadVoltage != null && loadPower != null)
                ? _fmtPowerW(loadPower)
                : null),
        'icon': Icons.home,
        'key': 'load',
      });
    }
    // Grid card: show Power (Watts) as primary value; voltage/frequency as secondary
    final selectedGrid = _selectedValueFor('grid');
    String? gridValueStr;
    String? gridSubtitle;
    
    if (selectedGrid != null) {
      gridValueStr = selectedGrid;
      gridSubtitle = _formatLabel(_selectedParByCategory['grid'] ?? '');
    } else if (gridPowerVal != null) {
      // Primary: Grid Power in Watts
      gridValueStr = _fmtPowerW(gridPowerVal);
      // Secondary: Voltage or Frequency
      if (gridVoltageVal != null) {
        gridSubtitle = _fmtVoltage(gridVoltageVal);
      } else if (gridFreqVal != null) {
        gridSubtitle = '${gridFreqVal.toStringAsFixed(1)} Hz';
      }
    } else if (gridVoltageVal != null) {
      // Fallback if no power: show voltage
      gridValueStr = _fmtVoltage(gridVoltageVal);
      if (gridFreqVal != null) {
        gridSubtitle = '${gridFreqVal.toStringAsFixed(1)} Hz';
      }
    } else if (gridFreqVal != null) {
      // Fallback if only frequency available
      gridValueStr = '${gridFreqVal.toStringAsFixed(1)} Hz';
    } else {
      // Last resort: check paging values
      gridValueStr = _latestPagingValues['Grid Power'] ??
          _latestPagingValues['Grid Voltage'] ??
          _latestPagingValues['Grid Frequency (Hz)'] ??
          '--';
    }
    
    // Always show Grid card
    rawCards.add({
      'title': 'Grid',
      'value': gridValueStr,
      'subtitle': gridSubtitle,
      'icon': Icons.electrical_services,
      'key': 'grid',
    });
    if (rawCards.isEmpty) return const SizedBox();

    const double cardHeight = 113; // increased by 5px to avoid overflow
    const double titleAreaHeight = 26; // two line slot
    const double subtitleHeight = 12; // reserved
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rawCards.length, (i) {
        final c = rawCards[i];
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              final k = (c['key'] as String?) ?? '';
              _showFlowDetails(k);
            },
            child: Container(
              height: cardHeight,
              margin: EdgeInsets.only(right: i == rawCards.length - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                6,
                12,
                6,
                6,
              ), // more top, less bottom
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      final primary = Theme.of(context).colorScheme.primary;
                      return Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          c['icon'] as IconData,
                          color: Colors.white,
                          size: 16,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: titleAreaHeight,
                    child: Center(
                      child: Text(
                        c['title'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6882),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3), // a bit more space before value
                  Text(
                    c['value'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: subtitleHeight,
                    child: (c['subtitle'] != null)
                        ? Text(
                            c['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (c['extraInfo'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      c['extraInfo'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showFlowDetails(String category) {
    if (_energyFlow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No details available')),
      );
      return;
    }

    // Detect device model and get model-specific configuration
    final deviceModel = DeviceModel.detect(
      devcode: widget.device.devcode,
      alias: widget.device.alias,
    );
    final modelConfig = DeviceModelPopupConfig.forModel(deviceModel);
    final fieldConfigs = modelConfig.getFieldsForCategory(category);

    String title = '';
    List<DeviceEnergyFlowItem> items = const [];
    IconData icon = Icons.info_outline;

    // Helper to find item by trying multiple API parameter names
    DeviceEnergyFlowItem? findByCandidate(
        List<DeviceEnergyFlowItem> source, List<String> candidates) {
      for (final candidate in candidates) {
        final found = source.firstWhere(
          (e) => e.par.trim().toLowerCase() == candidate.trim().toLowerCase(),
          orElse: () => DeviceEnergyFlowItem(par: '', value: null),
        );
        if (found.par.isNotEmpty) return found;
      }
      return null;
    }

    switch (category) {
      case 'pv':
        title = 'PV Details (${deviceModel.name.toUpperCase()})';
        final list = _energyFlow!.pvStatus;
        
        // Build ordered items based on model configuration
        final ordered = <DeviceEnergyFlowItem>[];
        for (final fieldConfig in fieldConfigs) {
          final item = findByCandidate(list, fieldConfig.apiCandidates);
          if (item != null) {
            // Create a normalized item with clean label from config
            ordered.add(DeviceEnergyFlowItem(
              par: fieldConfig.label,
              value: item.value,
              unit: fieldConfig.unit.isNotEmpty ? fieldConfig.unit : item.unit,
              status: item.status,
            ));
          }
        }
        
        // Add any remaining fields not in the model config
        final rest = list.where((e) => 
          !fieldConfigs.any((fc) => fc.apiCandidates.any(
            (c) => c.toLowerCase() == e.par.toLowerCase()
          ))
        ).toList();
        
        items = [...ordered, ...rest];
        icon = Icons.solar_power;
        break;
        
      case 'battery':
        title = 'Battery Details (${deviceModel.name.toUpperCase()})';
        final list = _energyFlow!.btStatus;
        
        final ordered = <DeviceEnergyFlowItem>[];
        for (final fieldConfig in fieldConfigs) {
          final item = findByCandidate(list, fieldConfig.apiCandidates);
          if (item != null) {
            ordered.add(DeviceEnergyFlowItem(
              par: fieldConfig.label,
              value: item.value,
              unit: fieldConfig.unit.isNotEmpty ? fieldConfig.unit : item.unit,
              status: item.status,
            ));
          }
        }
        
        final rest = list.where((e) => 
          !fieldConfigs.any((fc) => fc.apiCandidates.any(
            (c) => c.toLowerCase() == e.par.toLowerCase()
          ))
        ).toList();
        
        items = [...ordered, ...rest];
        icon = Icons.battery_full;
        break;
        
      case 'load':
        title = 'Load Details (${deviceModel.name.toUpperCase()})';
        final list = [..._energyFlow!.bcStatus, ..._energyFlow!.olStatus];
        
        final ordered = <DeviceEnergyFlowItem>[];
        for (final fieldConfig in fieldConfigs) {
          final item = findByCandidate(list, fieldConfig.apiCandidates);
          if (item != null) {
            ordered.add(DeviceEnergyFlowItem(
              par: fieldConfig.label,
              value: item.value,
              unit: fieldConfig.unit.isNotEmpty ? fieldConfig.unit : item.unit,
              status: item.status,
            ));
          }
        }
        
        // Filter out unwanted power fields from rest
        final rest = list.where((e) => 
          !fieldConfigs.any((fc) => fc.apiCandidates.any(
            (c) => c.toLowerCase() == e.par.toLowerCase()
          )) &&
          !e.par.toLowerCase().contains('ac output active power') &&
          !e.par.toLowerCase().contains('ac active output power')
        ).toList();
        
        items = [...ordered, ...rest];
        icon = Icons.home;
        break;
        
      case 'grid':
        title = 'Grid Details (${deviceModel.name.toUpperCase()})';
        final list = _energyFlow!.gdStatus;
        
        final ordered = <DeviceEnergyFlowItem>[];
        for (final fieldConfig in fieldConfigs) {
          final item = findByCandidate(list, fieldConfig.apiCandidates);
          if (item != null) {
            ordered.add(DeviceEnergyFlowItem(
              par: fieldConfig.label,
              value: item.value,
              unit: fieldConfig.unit.isNotEmpty ? fieldConfig.unit : item.unit,
              status: item.status,
            ));
          }
        }
        
        // Filter out 'Grid Active Power' from rest
        final rest = list.where((e) => 
          !fieldConfigs.any((fc) => fc.apiCandidates.any(
            (c) => c.toLowerCase() == e.par.toLowerCase()
          )) &&
          !e.par.toLowerCase().contains('grid active power')
        ).toList();
        
        items = [...ordered, ...rest];
        icon = Icons.electrical_services;
        break;
        
      default:
        title = 'Details';
        items = const [];
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty && _latestPagingValues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No data'),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final it in items)
                              InkWell(
                                onTap: () {
                                  // set selected label for category and update card
                                  _selectedParByCategory[category] = it.par;
                                  Navigator.of(ctx).pop();
                                  setState(() {});
                                },
                                child: _FlowDetailRow(
                                  label: _formatLabel(it.par),
                                  value:
                                      _formatValueWithUnit(it.value, it.unit),
                                  status: it.status,
                                  selected: () {
                                    final sel =
                                        _selectedParByCategory[category];
                                    if (sel == null) return false;
                                    final a = sel.trim().toLowerCase();
                                    final b1 = it.par.trim().toLowerCase();
                                    final b2 = _formatLabel(it.par)
                                        .trim()
                                        .toLowerCase();
                                    return a == b1 || a == b2;
                                  }(),
                                ),
                              ),
                            // Extras from paging for missing required labels
                            ..._extraRowsForCategory(
                                category,
                                items.map((e) => _formatLabel(e.par)).toSet(),
                                ctx),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatValueWithUnit(double? value, String? unit) {
    if (value == null) return '--';
    String u = (unit ?? '').trim();
    double v = value;
    // Keep original unit display; do not normalize here to avoid confusion
    // Format decimals based on magnitude
    String numStr;
    final abs = v.abs();
    if (abs >= 100) {
      numStr = v.toStringAsFixed(0);
    } else if (abs >= 10) {
      numStr = v.toStringAsFixed(1);
    } else {
      numStr = v.toStringAsFixed(2);
    }
    return u.isNotEmpty ? '$numStr $u' : numStr;
  }

  String _formatLabel(String raw) {
    if (raw.isEmpty) return raw;
    String s = raw.trim();
    s = s.replaceAll('_', ' ');
    // Normalize spacing
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    
    // Fix incorrect labels from API
    // Remove "Bt" prefix from battery capacity
    if (s.toLowerCase().startsWith('bt ')) {
      s = s.substring(3);
    }
    // Fix "Oil Output Capacity" to "Output Capacity"
    if (s.toLowerCase().contains('oil output capacity')) {
      s = s.replaceFirst(RegExp(r'(?i)oil output capacity'), 'Output Capacity');
    }
    
    // Map known variants first
    final low = s.toLowerCase();
    if (low.contains('ac2 output'))
      s = s.replaceFirst(RegExp(r'(?i)ac2 output'), 'Second Output');
    if (low == 'pv1 input voltage') s = 'PV1 Input Voltage';
    if (low == 'pv2 input voltage' || low == 'pv2 input voltage')
      s = 'PV2 Input Voltage';
    if (low == 'pv1 charging power') s = 'PV1 Input Power (Watts)';
    if (low == 'pv2 charging power') s = 'PV2 Input Power (Watts)';
    if (low == 'ac input range') s = 'AC Input Range (APL/UPS)';
    if (low == 'battery capacity') s = 'Battery Capacity (%)';
    if (low == 'battery charging current') s = 'Battery Charging Current (A)';
    if (low == 'battery discharging current')
      s = 'Battery Discharging Current (A)';
    if (low == 'ac output active power') s = 'AC Output Active Power (W)';
    if (low == 'output load percentage') s = 'Output Load Percentage (%)';
    if (low == 'grid frequency') s = 'Grid Frequency (Hz)';
    if (low == 'ac output frequency') s = 'AC Output Frequency (Hz)';

    // Title case but preserve common acronyms and numbers
    List<String> words = s.split(' ');
    final preserve = {'PV', 'AC', 'DC', 'UPS', 'APL', 'SOC', 'Hz', 'W', 'kW'};
    words = words.map((w) {
      if (w.isEmpty) return w;
      final core = w.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (preserve.contains(core.toUpperCase())) return core.toUpperCase();
      if (RegExp(r'^[0-9]+$').hasMatch(core)) return w; // leave numbers
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).toList();
    return words.join(' ');
  }

  List<Widget> _extraRowsForCategory(
      String category, Set<String> existingLabels, BuildContext ctx) {
    // Define desired labels per category (canonical UI labels)
    final desired = <String>[];
    switch (category) {
      case 'pv':
        desired.addAll([
          'PV1 Input Voltage',
          'PV1 Input Power (Watts)',
          'PV2 Input Voltage',
          'PV2 Input Power (Watts)',
        ]);
        break;
      case 'battery':
        desired.addAll([
          'Battery Voltage',
          'Battery Capacity (%)',
          'Battery Charging Current (A)',
          'Battery Discharging Current (A)',
          'Battery Type',
        ]);
        break;
      case 'load':
        desired.addAll([
          'Load Status',
          'AC Output Voltage',
          'AC Output Frequency (Hz)',
          'Second Output Voltage',
          'Second Output Frequency (Hz)',
          'AC Output Active Power (W)',
          'Output Load Percentage (%)',
        ]);
        break;
      case 'grid':
        desired.addAll([
          'Grid Voltage',
          'Grid Frequency (Hz)',
          'AC Input Range (APL/UPS)',
        ]);
        break;
    }
    String norm(String s) => s.trim().toLowerCase();
    final have = existingLabels.map(norm).toSet();
    final rows = <Widget>[];
    for (final label in desired) {
      if (have.contains(norm(label))) continue;
      final v = _latestPagingValues[label];
      if (v == null) continue;
      rows.add(
        InkWell(
          onTap: () {
            _selectedParByCategory[category] = label;
            Navigator.of(ctx).pop();
            setState(() {});
          },
          child: _FlowDetailRow(
            label: label,
            value: v,
            status: 0,
            selected: () {
              final sel = _selectedParByCategory[category];
              if (sel == null) return false;
              final a = sel.trim().toLowerCase();
              final b = label.trim().toLowerCase();
              return a == b;
            }(),
          ),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            color: Colors.white,
            child: Row(
              children: [
                _SquareIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SN Device Detail',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Power generation (collector) report - open prompt dialog
                _SquareIconButton(
                  customSvg: 'assets/icons/download_report_svg.svg',
                  tooltip: 'Power Generation Report',
                  onTap: _showPowerGenerationDialog,
                ),
                const SizedBox(width: 8),
                // Full report dialog (user selects range)
                _SquareIconButton(
                  customSvg: 'assets/icons/download_report_svg2.svg',
                  tooltip: 'Full Report',
                  onTap: _showReportDialog,
                ),
                const SizedBox(width: 8),
                // Navigate to alarms screen
                _SquareIconButton(
                  icon: Icons.notifications_none,
                  tooltip: 'Alarms',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AlarmNotificationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Settings icon - open Device Settings
                _SquareIconButton(
                  icon: Icons.settings,
                  tooltip: 'Settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DataControlOldScreen.fromDevice(
                          widget.device,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: (_loading && !_hasData)
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: $_err',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _fetch, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Header card removed as per requirements
                      // Diagram at the top now
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _EnergyFlowDiagram(
                          key: ValueKey(_lastFlowKey ?? 'empty'),
                          pvW: _energyFlow?.pvVoltage ??
                              _energyFlow?.pvPower ??
                              _numFromLatest([
                                'PV1 Input Voltage',
                                'PV2 Input Voltage',
                                'PV1 Input Power (Watts)'
                              ]),
                          loadW: _energyFlow?.loadPower,
                          gridW: _energyFlow?.gridVoltage ??
                              _energyFlow?.gridPower ??
                              _numFromLatest(
                                  ['Grid Voltage', 'Grid Frequency (Hz)']),
                          batterySoc: _energyFlow?.batterySoc,
                          batteryFlowW: _energyFlow?.batteryVoltage ??
                              _energyFlow?.batteryPower ??
                              _numFromLatest(['Battery Voltage']),
                          lastUpdated: _live?.timestamp,
                          energyFlow: _energyFlow, // Pass full model for status
                        ),
                      ),
                      const SizedBox(height: 16),
                      _summaryCards(),
                      const SizedBox(height: 24),
                      if (_graphEnabled)
                        _DeviceMetricGraph(device: widget.device),
                    ],
                  ),
                ),
    );
  }

  void _showPowerGenerationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        CollectorReportRange range = CollectorReportRange.daily;
        DateTime anchorDate = DateTime.now();

        String formatDate(CollectorReportRange r, DateTime d) {
          switch (r) {
            case CollectorReportRange.daily:
              return DateFormat('yyyy/MM/dd').format(d);
            case CollectorReportRange.monthly:
              return DateFormat('yyyy/MM').format(d);
            case CollectorReportRange.yearly:
              return DateFormat('yyyy').format(d);
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            Widget rangeChip(CollectorReportRange r, String label) {
              final selected = r == range;
              return InkWell(
                onTap: () => setState(() => range = r),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            Future<void> onDownload() async {
              try {
                final service = ReportDownloadService();
                Navigator.of(context).pop();

                final progressVN = ValueNotifier<double>(0);
                final safeContext =
                    NavigationService.navigatorKey.currentContext;
                if (safeContext == null) return;
                showModalBottomSheet(
                  context: safeContext,
                  isDismissible: false,
                  enableDrag: false,
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ValueListenableBuilder<double>(
                        valueListenable: progressVN,
                        builder: (c, value, _) {
                          final pctText = value > 0
                              ? '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%'
                              : 'Starting...';
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Power Generation Report',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: value == 0 ? null : value,
                              ),
                              const SizedBox(height: 8),
                              Text(pctText),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(c).pop();
                                },
                                child: Text(
                                  gen.AppLocalizations.of(c).action_cancel,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                );

                await service.downloadCollectorReport(
                  collectorPn: widget.device.pn,
                  range: range,
                  anchorDate: anchorDate,
                  filePrefix: 'power_generation',
                  onProgress: (r, t) {
                    if (t > 0) {
                      progressVN.value = (r / t).clamp(0, 1);
                    }
                  },
                );

                if (NavigationService.canPop()) {
                  NavigationService.pop();
                }
                final sc = NavigationService.navigatorKey.currentContext;
                if (sc != null) {
                  ScaffoldMessenger.of(sc).showSnackBar(
                    const SnackBar(content: Text('Report saved to Downloads')),
                  );
                }
              } catch (e) {
                if (NavigationService.canPop()) {
                  NavigationService.pop();
                }
                final sc = NavigationService.navigatorKey.currentContext;
                if (sc != null) {
                  ScaffoldMessenger.of(sc).showSnackBar(
                    SnackBar(content: Text('Failed to download: $e')),
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power Generation Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        rangeChip(
                          CollectorReportRange.daily,
                          gen.AppLocalizations.of(context).range_day,
                        ),
                        rangeChip(
                          CollectorReportRange.monthly,
                          gen.AppLocalizations.of(context).range_month,
                        ),
                        rangeChip(
                          CollectorReportRange.yearly,
                          gen.AppLocalizations.of(context).range_year,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: anchorDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => anchorDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatDate(range, anchorDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            gen.AppLocalizations.of(context).action_cancel,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onDownload,
                          child: Text(
                            gen.AppLocalizations.of(context).action_download,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FlowDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final int? status;
  final bool selected;
  const _FlowDetailRow({
    required this.label,
    required this.value,
    this.status,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) {
    // Color based on status (green=active, red=fault, grey=unknown)
    Color dotColor;
    switch (status) {
      case 1:
        dotColor = Colors.green;
        break;
      case -1:
        dotColor = Colors.red;
        break;
      default:
        dotColor = Colors.grey;
    }
    
    // Red filled dot for selected item, empty border for non-selected
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        // ONLY show filled dot when selected (red color to indicate selection)
        color: selected ? Colors.red : Colors.transparent,
        shape: BoxShape.circle,
        // Show border only for non-selected items
        border: selected ? null : Border.all(color: dotColor.withOpacity(0.3), width: 1.5),
      ),
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF7F9FC) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA)),
        ),
      ),
      child: Row(
        children: [
          dot,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.black : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData? icon;
  final String? customSvg;
  final VoidCallback? onTap;
  final String? tooltip;
  const _SquareIconButton({
    this.icon,
    this.customSvg,
    this.onTap,
    this.tooltip,
  });
  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: customSvg != null
            ? SvgPicture.asset(customSvg!, width: 22, height: 22)
            : Icon(icon, color: Colors.black, size: 22),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// Header block with image & status
class _DeviceHeader extends StatelessWidget {
  final Device device;
  final DeviceLiveSignalModel? live;
  const _DeviceHeader({required this.device, this.live});
  @override
  Widget build(BuildContext context) {
    // Map online/offline using device status (0 == online) to match legacy;
    // live.err is request success and may not reflect device online state.
    final online = device.isOnline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/overview_bg.png'),
          fit: BoxFit.cover,
          opacity: .18,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/device1.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? Colors.green : Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.alias.isNotEmpty ? device.alias : device.pn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Removed Offline/Online status display
                if (live != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gen.AppLocalizations.of(context).live_data,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// (Report dialog implemented within state class above)

class _DeviceMetricGraph extends StatefulWidget {
  final Device device;
  const _DeviceMetricGraph({required this.device});
  @override
  State<_DeviceMetricGraph> createState() => _DeviceMetricGraphState();
}

class _DeviceMetricGraphState extends State<_DeviceMetricGraph> {
  late OverviewGraphViewModel _vm;
  @override
  void initState() {
    super.initState();
    _vm = getIt<OverviewGraphViewModel>();
    final plantId = widget.device.plantId.isNotEmpty
        ? widget.device.plantId
        : widget.device.pid.toString();
    // Initialize for this specific device so allowed metrics filter correctly
    final deviceRef = DeviceRef(
      sn: widget.device.sn,
      pn: widget.device.pn,
      devcode: widget.device.devcode,
      devaddr: widget.device.devaddr,
      alias: widget.device.alias.isNotEmpty
          ? widget.device.alias
          : widget.device.pn,
    );
    // Fire async after build frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _vm.initForDevice(device: deviceRef, plantId: plantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<OverviewGraphViewModel>(
        builder: (context, vm, _) {
          final plantId = widget.device.plantId.isNotEmpty
              ? widget.device.plantId
              : widget.device.pid.toString();
          String anchorLabel;
          switch (vm.period) {
            case GraphPeriod.day:
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sept',
                'Oct',
                'Nov',
                'Dec',
              ];
              anchorLabel =
                  '${vm.anchor.day.toString().padLeft(2, '0')} ${months[vm.anchor.month - 1]} ${vm.anchor.year}';
              break;
            case GraphPeriod.month:
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sept',
                'Oct',
                'Nov',
                'Dec',
              ];
              anchorLabel = '${months[vm.anchor.month - 1]} ${vm.anchor.year}';
              break;
            case GraphPeriod.year:
              anchorLabel = vm.anchor.year.toString();
              break;
            case GraphPeriod.total:
              anchorLabel = 'Total';
              break;
          }
          final state = vm.state;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vm.metric.name,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: vm.allowedMetricsForSelectedDevice
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.name,
                                  child: Text(_metricLabel(m)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val == null) return;
                            final m =
                                vm.allowedMetricsForSelectedDevice.firstWhere(
                              (g) => g.name == val,
                              orElse: () =>
                                  vm.allowedMetricsForSelectedDevice.first,
                            );
                            await vm.setMetric(m, plantId: plantId);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _periodChip(
                    'Day',
                    vm.period == GraphPeriod.day,
                    () => vm.setPeriod(GraphPeriod.day, plantId: plantId),
                  ),
                  const SizedBox(width: 8),
                  _periodChip(
                    'Month',
                    vm.period == GraphPeriod.month,
                    () => vm.setPeriod(GraphPeriod.month, plantId: plantId),
                  ),
                  const SizedBox(width: 8),
                  _periodChip(
                    'Year',
                    vm.period == GraphPeriod.year,
                    () => vm.setPeriod(GraphPeriod.year, plantId: plantId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, color: Colors.black54),
                    onPressed: () => vm.stepDate(-1, plantId: plantId),
                  ),
                  Text(
                    anchorLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final now = DateTime.now();
                      bool canForward;
                      switch (vm.period) {
                        case GraphPeriod.day:
                          canForward = DateTime(
                            vm.anchor.year,
                            vm.anchor.month,
                            vm.anchor.day,
                          ).isBefore(DateTime(now.year, now.month, now.day));
                          break;
                        case GraphPeriod.month:
                          canForward = DateTime(
                            vm.anchor.year,
                            vm.anchor.month,
                          ).isBefore(DateTime(now.year, now.month));
                          break;
                        case GraphPeriod.year:
                          canForward = vm.anchor.year < now.year;
                          break;
                        case GraphPeriod.total:
                          canForward = false;
                          break;
                      }
                      return IconButton(
                        icon: Icon(
                          Icons.arrow_right,
                          color: canForward ? Colors.black54 : Colors.black26,
                        ),
                        onPressed: canForward
                            ? () => vm.stepDate(1, plantId: plantId)
                            : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Single unified graph card containing the chart
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  // adjust bottom padding to reduce excess whitespace below chart
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: SizedBox(height: 240, child: _LineChart(state: state)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _periodChip(String label, bool selected, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final OverviewGraphState state;
  const _LineChart({required this.state});
  @override
  Widget build(BuildContext context) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (state.labels.isEmpty || state.series.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.primary;
    final isDaily = state.labels.length == 24 &&
        (state.labels.first.contains(':') || state.labels.last.contains(':'));
    final minY = state.min;
    final maxY = state.max == state.min ? state.min + 1 : state.max;
    // range calculation not needed without left tick labels
    // interval removed (no left axis labels)
    // Unified axis style: ticks on bottom only with custom labels
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.black.withOpacity(.15), width: 1),
            bottom: BorderSide(color: Colors.black.withOpacity(.15), width: 1),
            right: const BorderSide(color: Colors.transparent),
            top: const BorderSide(color: Colors.transparent),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(.04), strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final range = (maxY - minY).abs();
                final tick1 = minY;
                final tick2 = minY + range / 2.0;
                final tick3 = maxY;
                bool near(double a, double b) => (a - b).abs() <= range * 0.02;

                if (!(near(value, tick1) ||
                    near(value, tick2) ||
                    near(value, tick3))) {
                  return const SizedBox.shrink();
                }

                String unit = state.unit;
                double disp = value;
                if (unit.toLowerCase() == 'w' && maxY >= 1000) {
                  disp = value / 1000.0;
                  unit = 'kW';
                }
                String numStr;
                final abs = disp.abs();
                if (abs >= 100)
                  numStr = disp.toStringAsFixed(0);
                else if (abs >= 10)
                  numStr = disp.toStringAsFixed(1);
                else
                  numStr = disp.toStringAsFixed(2);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '$numStr $unit',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // reduced reserved size to lessen bottom whitespace
              reservedSize: 38,
              interval: isDaily ? 360 : 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                bool isFirst = false;
                if (isDaily) {
                  final minute = value.round();
                  if (minute == 0) {
                    text = '12AM';
                    isFirst = true;
                  } else if (minute == 360)
                    text = '6AM';
                  else if (minute == 720)
                    text = '12PM';
                  else if (minute == 1080) text = '6PM';
                } else {
                  final len = state.labels.length;
                  if (len == 0) return const SizedBox.shrink();
                  final idx = value.round();
                  if (len == 12) {
                    if (idx == 0) {
                      text = state.labels.first; // Jan
                      isFirst = true;
                    } else if (idx == 5)
                      text = state.labels[5]; // Jun
                    else if (idx == 11) text = state.labels.last; // Dec
                  } else {
                    final lastIdx = len - 1;
                    if (idx == 0) {
                      text = state.labels.first; // 1
                      isFirst = true;
                    } else if (int.tryParse(state.labels[idx]) == 15)
                      text = '15';
                    else if (idx == lastIdx)
                      text = state.labels.last; // last day
                  }
                }
                if (text.isEmpty) return const SizedBox.shrink();
                final style = const TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                );
                final textDir = Directionality.of(context);
                final tp = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: textDir,
                )..layout();
                final sign = (textDir == ui.TextDirection.ltr) ? 1.0 : -1.0;
                final dx = isFirst ? sign * (tp.width / 2 + 2) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(top: 8, right: 6),
                  child: Transform.translate(
                    offset: Offset(dx, 2),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            getTooltipItems: (items) => items.map((it) {
              String label;
              if (isDaily) {
                int minute = it.x.round();
                minute = minute.clamp(0, 1439);
                final h = minute ~/ 60;
                final m = minute % 60;
                final hour12 = ((h + 11) % 12) + 1;
                final ampm = h < 12 ? 'AM' : 'PM';
                label = '$hour12:${m.toString().padLeft(2, '0')} $ampm';
              } else {
                final len = state.labels.length;
                int idx = it.x.round();
                if (idx < 0) idx = 0;
                if (idx >= len) idx = len - 1;
                label = len > 0 ? state.labels[idx] : '';
              }
              return LineTooltipItem(
                '$label\n${it.y.toStringAsFixed(1)} ${state.unit}',
                const TextStyle(color: Colors.black),
              );
            }).toList(),
          ),
        ),
        minX: 0,
        maxX: isDaily ? 1439 : null,
        lineBarsData: state.series.map((s) {
          final spots = isDaily ? _expandDaily(s.data) : _upsample(s.data, 16);
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.36,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(.30),
                  lineColor.withOpacity(.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<FlSpot> _expandDaily(List<double> hourly) {
    if (hourly.isEmpty) return const [];
    if (hourly.length == 1)
      return List.generate(1440, (i) => FlSpot(i.toDouble(), hourly.first));
    final spots = <FlSpot>[];
    for (int h = 0; h < hourly.length - 1; h++) {
      final y0 = hourly[h];
      final y1 = hourly[h + 1];
      for (int m = 0; m < 60; m++) {
        final r = m / 60.0;
        spots.add(FlSpot(h * 60 + m.toDouble(), y0 + (y1 - y0) * r));
      }
    }
    spots.add(FlSpot(1439, hourly.last));
    return spots;
  }

  List<FlSpot> _upsample(List<double> data, int factor) {
    if (data.isEmpty) return const [];
    if (data.length == 1 || factor <= 1)
      return List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final out = <FlSpot>[];
    for (int i = 0; i < data.length - 1; i++) {
      final x0 = i.toDouble(), y0 = data[i];
      final x1 = (i + 1).toDouble(), y1 = data[i + 1];
      out.add(FlSpot(x0, y0));
      for (int t = 1; t < factor; t++) {
        final r = t / factor;
        out.add(FlSpot(x0 + (x1 - x0) * r, y0 + (y1 - y0) * r));
      }
    }
    out.add(FlSpot((data.length - 1).toDouble(), data.last));
    return out;
  }
}

String _metricLabel(GraphMetric m) {
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

class _EnergyFlowDiagram extends StatefulWidget {
  final double? pvW; // using W or Voltage value generically for presence
  final double? loadW;
  final double? gridW;
  final double? batterySoc;
  final double? batteryFlowW; // using battery voltage/power for presence
  final DateTime? lastUpdated;
  final DeviceEnergyFlowModel? energyFlow; // Full model for status directions
  const _EnergyFlowDiagram({
    Key? key,
    required this.pvW,
    required this.loadW,
    required this.gridW,
    required this.batterySoc,
    required this.batteryFlowW,
    required this.lastUpdated,
    this.energyFlow,
  }) : super(key: key);
  @override
  State<_EnergyFlowDiagram> createState() => _EnergyFlowDiagramState();
}

class _EnergyFlowDiagramState extends State<_EnergyFlowDiagram> {
  VideoPlayerController? _controller;
  String? _currentAsset;
  bool _isInitializing = false;

  bool _present(double? v, {double threshold = 5}) => (v ?? 0) > threshold;

  String _selectVideoAsset() {
    // If no energyFlow data, use simple logic based on available values
    if (widget.energyFlow == null) {
      final hasPV = _present(widget.pvW, threshold: 10);
      final hasBattery = (widget.batterySoc ?? 0) > 5 ||
          _present(widget.batteryFlowW, threshold: 10);
      final hasGrid = _present(widget.gridW, threshold: 10);

      if (hasPV && hasBattery) return 'assets/energy_diagram/Case_5.mp4';
      if (hasBattery && hasGrid) return 'assets/energy_diagram/Case_3.mp4';
      if (hasBattery) return 'assets/energy_diagram/Case_4.mp4';
      return 'assets/energy_diagram/Case_2.mp4';
    }

    // Get status directions from energyFlow
    final int? pvStatus = widget.energyFlow?.pvStatusDir;
    final int? batteryStatus = widget.energyFlow?.batteryStatusDir;
    final int? gridStatus = widget.energyFlow?.gridStatusDir;

    // Get power values
    final double pvPower = widget.pvW ?? 0;
    final double batteryPower = widget.batteryFlowW ?? 0;
    final double gridPower = widget.gridW ?? 0;
    final double loadPower = widget.loadW ?? 0;

    // Solar to inverter: PV producing power
    final bool solarToInverter = pvPower > 50 || (pvStatus ?? 0) > 0;

    // Battery discharging (to inverter): positive power flow OR positive status
    final bool batteryToInverter =
        batteryPower > 20 || (batteryStatus ?? 0) > 0;

    // Battery charging (from inverter): negative status
    final bool inverterToBattery = (batteryStatus ?? 0) < 0;

    // Grid to inverter: Grid status positive OR (load exists but no other sources)
    // CRITICAL: If load > 100W but solar=0 and battery not discharging, grid MUST be supplying!
    final bool gridToInverter = (gridStatus ?? 0) > 0 ||
        gridPower > 50 ||
        (loadPower > 100 && !solarToInverter && !batteryToInverter);

    // Inverter to grid (exporting): negative grid status
    final bool inverterToGrid = (gridStatus ?? 0) < 0;

    // Inverter to home: always true when device is online
    final bool inverterToHome = true;

    // Case matching with EXACT conditions:

    // Case 1: Solar + Battery + Grid → Home (all sources active)
    if (solarToInverter &&
        batteryToInverter &&
        gridToInverter &&
        inverterToHome) {
      return 'assets/energy_diagram/Case_1.mp4';
    }

    // Case 6: Solar → Battery + Grid + Home (excess solar, charging + exporting)
    if (solarToInverter &&
        inverterToBattery &&
        inverterToGrid &&
        inverterToHome) {
      return 'assets/energy_diagram/Case_6.mp4';
    }

    // Case 5: Solar + Battery → Home (no grid)
    if (solarToInverter &&
        batteryToInverter &&
        !gridToInverter &&
        inverterToHome) {
      return 'assets/energy_diagram/Case_5.mp4';
    }

    // Case 3: Battery + Grid → Home (no solar)
    if (!solarToInverter &&
        batteryToInverter &&
        gridToInverter &&
        inverterToHome) {
      return 'assets/energy_diagram/Case_3.mp4';
    }

    // Case 4: Battery only → Home
    if (!solarToInverter &&
        batteryToInverter &&
        !gridToInverter &&
        inverterToHome) {
      return 'assets/energy_diagram/Case_4.mp4';
    }

    // Grid only → Home (IMPORTANT: When load exists but no solar/battery)
    if (!solarToInverter && !batteryToInverter && gridToInverter) {
      return 'assets/energy_diagram/Case_3.mp4'; // Use Case 3 video (grid powering home)
    }

    // Solar only → Home
    if (solarToInverter && !batteryToInverter && !gridToInverter) {
      return 'assets/energy_diagram/Case_5.mp4';
    }

    // Case 2: Minimal/standby (no sources, very low or no load)
    if (!solarToInverter && !batteryToInverter && !gridToInverter) {
      return 'assets/energy_diagram/Case_2.mp4';
    }

    // Final fallback based on load
    if (loadPower > 100) {
      // If there's significant load, grid must be active
      return 'assets/energy_diagram/Case_3.mp4';
    }

    return 'assets/energy_diagram/Case_2.mp4';
  }

  Future<void> _initControllerFor(String asset) async {
    if (_currentAsset == asset &&
        _controller != null &&
        _controller!.value.isInitialized) {
      return;
    }
    if (_isInitializing) {
      return; // Prevent concurrent initialization
    }

    _isInitializing = true;

    final old = _controller;

    try {
      // Create controller
      _controller = VideoPlayerController.asset(asset);
      _currentAsset = asset;

      // Initialize
      await _controller!.initialize();

      // Check if initialized
      if (!_controller!.value.isInitialized) {
        throw Exception('Controller not initialized after initialize() call');
      }

      // Set looping
      _controller!.setLooping(true);

      // Start playback
      await _controller!.play();

      // Verify playing
    } catch (e) {
      // Set controller to null so PNG fallback shows
      _controller?.dispose();
      _controller = null;
      _currentAsset = null;
    }

    _isInitializing = false;

    // Update UI
    if (mounted) {
      setState(() {});
    }

    // Cleanup old controller
    if (old != null) {
      await old.pause();
      await old.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant _EnergyFlowDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force init if no controller
    if (_controller == null && !_isInitializing) {
      final asset = _selectVideoAsset();
      _initControllerFor(asset);
      return;
    }

    // Reinit if values changed
    final pvChanged = (oldWidget.pvW ?? 0) != (widget.pvW ?? 0);
    final batteryChanged =
        (oldWidget.batterySoc ?? 0) != (widget.batterySoc ?? 0);
    final gridChanged = (oldWidget.gridW ?? 0) != (widget.gridW ?? 0);

    if (pvChanged || batteryChanged || gridChanged) {
      final asset = _selectVideoAsset();
      _initControllerFor(asset);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final asset = _selectVideoAsset();
        _initControllerFor(asset);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller != null && _controller!.value.isInitialized;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final aspect = 365 / 302; // original design aspect
        final double height =
            width.isFinite ? (width / aspect).toDouble() : 240.0;

        if (!ready) {
          // Show loading indicator while video initializes
          return Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isInitializing
                        ? 'Loading Energy Diagram...'
                        : 'Initializing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    const _LiveDataDot(),
                    const SizedBox(width: 6),
                    Text(
                      gen.AppLocalizations.of(context).live_data,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveDataDot extends StatelessWidget {
  const _LiveDataDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
}
