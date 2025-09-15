import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
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
    show DeviceEnergyFlowModel; // ensure model available
// Use the unified alarm notification screen (same as home) for consistent loading logic
import 'package:crown_micro_solar/view/home/alarm_notification_screen.dart';
import 'package:video_player/video_player.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late final DeviceViewModel _deviceVM;
  DeviceLiveSignalModel? _live;
  late final MetricAggregatorViewModel _metricAggVM;
  DeviceEnergyFlowModel? _energyFlow;
  bool _loading = true;
  bool _hasData = false;
  String? _err;
  DateTime _anchorDate = DateTime.now();
  Timer? _refreshTimer;
  bool _isFetching = false;
  String? _lastFlowKey;

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
    final repo = getIt<DeviceRepository>();
    _metricAggVM = MetricAggregatorViewModel(
      deviceRepository: repo,
      sn: widget.device.sn,
      pn: widget.device.pn,
      devcode: widget.device.devcode,
      devaddr: widget.device.devaddr,
    );
    _fetch();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetch(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
    try {
      final date = DateFormat('yyyy-MM-dd').format(_anchorDate);
      // Run independent calls in parallel for faster turnaround
      final repo = getIt<DeviceRepository>();
      final futures = await Future.wait([
        _deviceVM.fetchDeviceLiveSignal(
          sn: widget.device.sn,
          pn: widget.device.pn,
          devcode: widget.device.devcode,
          devaddr: widget.device.devaddr,
        ),
        repo.fetchDeviceEnergyFlow(
          sn: widget.device.sn,
          pn: widget.device.pn,
          devcode: widget.device.devcode,
          devaddr: widget.device.devaddr,
        ),
        _metricAggVM.resolveMetrics([
          'PV_OUTPUT_POWER',
          'PV_INPUT_VOLTAGE',
          'AC2_OUTPUT_VOLTAGE',
          'BATTERY_SOC',
          'LOAD_POWER',
          'GRID_POWER',
        ], date: date),
      ]);
      final live = futures[0] as DeviceLiveSignalModel?;
      final flow = futures[1] as DeviceEnergyFlowModel?;
      if (!mounted) return;
      final newKey = _computeFlowKey(flow);
      setState(() {
        _live = live;
        _energyFlow = flow;
        _lastFlowKey = newKey;
        _loading = false;
        _hasData = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
    _isFetching = false;
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

    final pvVoltage = _energyFlow?.pvVoltage ?? pvVoltageMetric?.latestValue;
    final pvPower =
        _energyFlow?.pvPower ?? pvPowerMetric?.latestValue ?? _live?.inputPower;
    final loadVoltage = acOutVoltageMetric?.latestValue;
    final loadPower = _energyFlow?.loadPower ??
        loadPowerMetric?.latestValue ??
        _live?.outputPower;
    final gridVoltageVal = _energyFlow?.gridVoltage;
    final gridPowerVal = _energyFlow?.gridPower ?? gridPowerMetric?.latestValue;
    final batteryVoltage = _energyFlow?.batteryVoltage;
    final batSoc = _energyFlow?.batterySoc ??
        batSocMetric?.latestValue ??
        _live?.batteryLevel;

    final rawCards = <Map<String, Object?>>[];
    if (pvVoltage != null || pvPower != null) {
      rawCards.add({
        'title': 'PV',
        'value': _fmtVoltageOrPower(pvVoltage ?? pvPower),
        'subtitle':
            pvVoltage != null && pvPower != null ? _fmtPowerW(pvPower) : null,
        'icon': Icons.solar_power,
      });
    }
    if (batteryVoltage != null || batSoc != null) {
      rawCards.add({
        'title': 'Battery',
        'value': batteryVoltage != null
            ? _fmtVoltage(batteryVoltage)
            : _fmtSoc(batSoc),
        'subtitle': () {
          if (batteryVoltage != null && batSoc != null) return _fmtSoc(batSoc);
          final pw = _energyFlow?.batteryPower;
          if (batteryVoltage == null && pw != null && pw.abs() > 0) {
            return _fmtPowerW(pw);
          }
          return null;
        }(),
        'icon': Icons.battery_full,
      });
    }
    if (loadVoltage != null || loadPower != null) {
      rawCards.add({
        'title': 'Load',
        'value': _fmtVoltageOrPower(loadVoltage ?? loadPower),
        'subtitle': (loadVoltage != null && loadPower != null)
            ? _fmtPowerW(loadPower)
            : null,
        'icon': Icons.home,
      });
    }
    if (gridVoltageVal != null || gridPowerVal != null) {
      rawCards.add({
        'title': 'Grid',
        'value': _fmtVoltageOrPower(gridVoltageVal ?? gridPowerVal),
        'subtitle': (gridVoltageVal != null && gridPowerVal != null)
            ? _fmtPowerW(gridPowerVal)
            : null,
        'icon': Icons.electrical_services,
      });
    }
    if (rawCards.isEmpty) return const SizedBox();

    const double cardHeight = 113; // increased by 5px to avoid overflow
    const double titleAreaHeight = 26; // two line slot
    const double subtitleHeight = 12; // reserved
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rawCards.length, (i) {
        final c = rawCards[i];
        return Expanded(
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
              ],
            ),
          ),
        );
      }),
    );
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
              ],
            ),
          ),
        ),
      ),
      body: ((_loading && !_hasData) || (_metricAggVM.isLoading && !_hasData))
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
                      _DeviceHeader(device: widget.device, live: _live),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _EnergyFlowDiagram(
                          key: ValueKey(_lastFlowKey ?? 'empty'),
                          pvW: _energyFlow?.pvVoltage ?? _energyFlow?.pvPower,
                          loadW: _energyFlow?.loadPower,
                          gridW: _energyFlow?.gridVoltage ??
                              _energyFlow?.gridPower,
                          batterySoc: _energyFlow?.batterySoc,
                          batteryFlowW: _energyFlow?.batteryVoltage ??
                              _energyFlow?.batteryPower,
                          lastUpdated: _live?.timestamp,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _summaryCards(),
                      const SizedBox(height: 24),
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

class _SquareIconButton extends StatelessWidget {
  final IconData? icon;
  final String? customSvg;
  final VoidCallback onTap;
  final String? tooltip;
  const _SquareIconButton({
    this.icon,
    this.customSvg,
    required this.onTap,
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
                const SizedBox(height: 4),
                Text(
                  online
                      ? gen.AppLocalizations.of(context).online
                      : gen.AppLocalizations.of(context).offline,
                  style: TextStyle(
                    color: online ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
  const _EnergyFlowDiagram({
    Key? key,
    required this.pvW,
    required this.loadW,
    required this.gridW,
    required this.batterySoc,
    required this.batteryFlowW,
    required this.lastUpdated,
  }) : super(key: key);
  @override
  State<_EnergyFlowDiagram> createState() => _EnergyFlowDiagramState();
}

class _EnergyFlowDiagramState extends State<_EnergyFlowDiagram> {
  VideoPlayerController? _controller;
  String? _currentAsset;

  bool _present(double? v, {double threshold = 5}) => (v ?? 0) > threshold;

  String _selectVideoAsset() {
    // Use thresholds consistent with previous image selection logic
    final pvOn = _present(widget.pvW, threshold: 50);
    final gridOn = _present(widget.gridW, threshold: 50);
    final batOn = _present(widget.batteryFlowW, threshold: 20) ||
        (widget.batterySoc ?? 0) > 5;

    if (pvOn && gridOn) return 'assets/energy_diagram/grid_solar.mp4';
    if (pvOn && batOn) return 'assets/energy_diagram/solar_battery.mp4';
    if (gridOn && batOn) return 'assets/energy_diagram/grid_battery.mp4';
    if (pvOn) return 'assets/energy_diagram/solar_battery.mp4';
    if (gridOn) return 'assets/energy_diagram/grid_battery.mp4';
    return 'assets/energy_diagram/battery_only.mp4';
  }

  Future<void> _initControllerFor(String asset) async {
    if (_currentAsset == asset && _controller != null) return;
    final old = _controller;
    _controller = VideoPlayerController.asset(asset);
    _currentAsset = asset;
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      await _controller!.play();
    } catch (_) {
      // ignore play errors for missing/invalid assets
    }
    if (mounted) setState(() {});
    await old?.pause();
    await old?.dispose();
  }

  @override
  void didUpdateWidget(covariant _EnergyFlowDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    final asset = _selectVideoAsset();
    _initControllerFor(asset);
  }

  @override
  void initState() {
    super.initState();
    final asset = _selectVideoAsset();
    _initControllerFor(asset);
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
        if (!ready) return const SizedBox.shrink();
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
                child: (_controller != null && _controller!.value.isInitialized)
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
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
