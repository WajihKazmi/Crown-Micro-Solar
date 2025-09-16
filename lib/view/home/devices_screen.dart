import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/view/home/device_detail_screen.dart';
import 'package:crown_micro_solar/core/services/report_download_service.dart';
import 'package:intl/intl.dart';
import 'collector_detail_screen.dart';

/// Devices tab content to be embedded inside the parent Scaffold (no own Scaffold/AppBar)
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final DeviceViewModel _deviceVM;
  late final PlantViewModel _plantVM;
  bool _loading = true;
  bool _initialLoadDone = false;
  String? _error;
  String _selectedDeviceType = 'All Types';
  DateTime? _lastLoadTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deviceVM = getIt<DeviceViewModel>();
    _plantVM = getIt<PlantViewModel>();
    _deviceVM.addListener(_onVMChange);
    // If data already loaded in the shared ViewModel, don't reload on re-nav
    if (_deviceVM.allDevices.isNotEmpty || _deviceVM.collectors.isNotEmpty) {
      _loading = false;
      _initialLoadDone = true;
    } else {
      _loadDevices();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deviceVM.removeListener(_onVMChange);
    super.dispose();
  }

  void _onVMChange() {
    if (!mounted) return;
    setState(() {
      _loading = _deviceVM.isLoading;
      _error = _deviceVM.error;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastLoadTime == null ||
          now.difference(_lastLoadTime!).inMinutes > 5) {
        _loadDevices(force: true);
      }
    }
  }

  Future<void> _loadDevices({bool force = false}) async {
    if (!mounted) return;
    if (!force &&
        (_deviceVM.allDevices.isNotEmpty || _deviceVM.collectors.isNotEmpty)) {
      _loading = false;
      _initialLoadDone = true;
      setState(() {});
      return;
    }
    _lastLoadTime = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_plantVM.plants.isEmpty) await _plantVM.loadPlants();
      if (_plantVM.plants.isEmpty) {
        setState(() {
          _error = 'No plants available';
          _loading = false;
        });
        return;
      }
      final plantId = _plantVM.plants.first.id;
      await _deviceVM.loadDevicesAndCollectors(plantId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoadDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadDevicesWithFilters() async {
    if (!mounted) return;
    if (_selectedDeviceType == 'All Types') {
      _loadDevices();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_plantVM.plants.isEmpty) await _plantVM.loadPlants();
      if (_plantVM.plants.isEmpty) {
        setState(() {
          _error = 'No plants available';
          _loading = false;
        });
        return;
      }
      final plantId = _plantVM.plants.first.id;
      String deviceType = '0101';
      switch (_selectedDeviceType) {
        case 'Inverter':
          deviceType = '512';
          break;
        case 'Datalogger':
          deviceType = '0110';
          break;
        case 'Env-monitor':
          deviceType = '768';
          break;
        case 'Smart meter':
          deviceType = '1024';
          break;
        case 'Energy storage':
          deviceType = '2452';
          break;
      }
      await _deviceVM.loadDevicesWithFilters(
        plantId,
        status: '0101',
        deviceType: deviceType,
      );
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    Widget content;
    if (_loading || !_initialLoadDone) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadDevices, child: const Text('Retry')),
          ],
        ),
      );
    } else if (_deviceVM.allDevices.isEmpty) {
      // Show graceful empty state inside scroll view to avoid unbounded flex errors when embedded
      content = SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(children: [
                const Icon(Icons.devices_other, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No devices found'),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _loadDevices, child: const Text('Refresh')),
              ])));
    } else {
      content = SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterDropdown(surface, onSurface),
            _buildDeviceList(surface),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    // Floating Add Datalogger button using Stack so it doesn't cut background
    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: FloatingActionButton.extended(
            heroTag: 'add_datalogger_fab',
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.add),
            label: const Text('Datalogger'),
            onPressed: (_loading || !_initialLoadDone)
                ? null
                : _showAddDataloggerDialog,
          ),
        )
      ],
    );
  }

  Widget _buildFilterDropdown(Color surface, Color onSurface) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(color: onSurface.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDeviceType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'All Types', child: Text('All Types')),
            DropdownMenuItem(value: 'Inverter', child: Text('Inverter')),
            DropdownMenuItem(value: 'Datalogger', child: Text('Datalogger')),
            DropdownMenuItem(value: 'Env-monitor', child: Text('Env-monitor')),
            DropdownMenuItem(value: 'Smart meter', child: Text('Smart meter')),
            DropdownMenuItem(
                value: 'Energy storage', child: Text('Energy storage')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedDeviceType = v);
            _loadDevicesWithFilters();
          },
        ),
      ),
    );
  }

  Widget _buildDeviceList(Color surface) {
    final hasStandalone = _deviceVM.standaloneDevices.isNotEmpty;
    final hasCollectors = _deviceVM.collectors.isNotEmpty;
    final widgets = <Widget>[];

    if (hasCollectors) {
      for (final c in _deviceVM.collectors) {
        widgets.add(_buildCollectorCard(c));
        final pn = c['pn']?.toString() ?? '';
        if (_deviceVM.isCollectorExpanded(pn)) {
          final subs = _deviceVM.getSubordinateDevices(pn);
          widgets.addAll(subs.map((d) => _buildSubordinateDeviceCard(d)));
        }
      }
    }
    if (hasStandalone) {
      widgets
          .addAll(_deviceVM.standaloneDevices.map((d) => _buildDeviceCard(d)));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(children: widgets),
    );
  }

  void _showAddDataloggerDialog() {
    final nameController = TextEditingController();
    final pnController = TextEditingController();
    String? error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Datalogger Name and PN Number',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 16),
                const Text('Datalogger',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter Datalogger Name'),
                ),
                const SizedBox(height: 12),
                const Text('PN Number',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: pnController,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  decoration: const InputDecoration(
                      hintText: 'Enter PN Number (14 digits)', counterText: ''),
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final pn = pnController.text.trim();
                        String? localError;
                        if (name.isEmpty) {
                          localError = 'Datalogger name is required';
                        } else if (!RegExp(r'^\d{14}$').hasMatch(pn)) {
                          localError = 'PN must be 14 digits';
                        }
                        if (localError != null) {
                          setState(() => error = localError);
                          return;
                        }
                        setState(() => error = null);
                        if (_plantVM.plants.isEmpty) {
                          setState(() => error = 'No plants available');
                          return;
                        }
                        final plantId = _plantVM.plants.first.id;
                        try {
                          final res = await _deviceVM.addDatalogger(
                              plantId: plantId, pn: pn, name: name);
                          if (res['err'] == 0) {
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Datalogger added successfully')));
                              _loadDevices();
                            }
                          } else {
                            setState(() => error = res['desc']?.toString() ??
                                'Failed to add datalogger');
                          }
                        } catch (e) {
                          setState(() => error = e.toString());
                        }
                      },
                      child: _deviceVM.isAddingDatalogger
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : const Text('Add',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectorCard(Map<String, dynamic> collector) {
    final pn = collector['pn']?.toString() ?? '';
    final alias = collector['alias']?.toString() ?? 'Datalogger';
    final status = collector['status'] ?? 0;
    final load = collector['load'] ?? 0;
    final signal = collector['signal'] != null
        ? double.tryParse(collector['signal'].toString())
        : null;
    final isExpanded = _deviceVM.isCollectorExpanded(pn);
    final subs = _deviceVM.getSubordinateDevices(pn);
    final hasSubs = subs.isNotEmpty;
    final statusText = _getDeviceStatusText(status);
    final statusColor = _getStatusColor(status);
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    return GestureDetector(
        onTap: () {
          if (pn.isEmpty) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CollectorDetailScreen(collector: collector)));
        },
        child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
              ],
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (hasSubs)
                    GestureDetector(
                      onTap: () => setState(
                          () => _deviceVM.toggleCollectorExpansion(pn)),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_right,
                            color: Colors.grey[600]),
                      ),
                    ),
                  if (hasSubs) const SizedBox(width: 8),
                  Image.asset('assets/images/device1.png',
                      width: 56, height: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALIAS: $alias',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('PN: $pn',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('LOAD: $load',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Text('STATUS: ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54)),
                            Text(statusText,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor)),
                          ]),
                          if (signal != null && signal > 0) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Text('SIGNAL: ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54)),
                              RatingBarIndicator(
                                rating: signal / 20.0,
                                itemBuilder: (_, __) => Icon(Icons.circle,
                                    color: _getSignalColor(signal), size: 10),
                                itemCount: 5,
                                itemSize: 10,
                                unratedColor: Colors.grey.withAlpha(40),
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 4),
                              Text('${signal.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getSignalColor(signal)))
                            ])
                          ]
                        ]),
                  ),
                  IconButton(
                    tooltip: 'Download full report',
                    icon: const Icon(Icons.description_outlined,
                        color: Colors.black54),
                    onPressed: () {
                      if (pn.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Collector PN missing')));
                        return;
                      }
                      _showCollectorFullReportDialog(pn);
                    },
                  )
                ]))));
  }

  Widget _buildDeviceCard(Device device) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DeviceDetailScreen(device: device)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Image.asset('assets/images/device1.png', width: 56, height: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'ALIAS: ${device.alias.isNotEmpty ? device.alias : device.pn}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('PN: ${device.pn}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text('LOAD: ${device.load ?? 0}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Text('STATUS: ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      Text(statusText,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor)),
                    ]),
                    if (device.signal != null && device.signal! > 0) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('SIGNAL: ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                        RatingBarIndicator(
                          rating: device.signal! / 20.0,
                          itemBuilder: (_, __) => Icon(Icons.circle,
                              color: _getSignalColor(device.signal!), size: 10),
                          itemCount: 5,
                          itemSize: 10,
                          unratedColor: Colors.grey.withAlpha(40),
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 4),
                        Text('${device.signal!.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getSignalColor(device.signal!)))
                      ])
                    ]
                  ]),
            ),
            Icon(Icons.keyboard_double_arrow_right, color: Colors.grey[600])
          ]),
        ),
      ),
    );
  }

  // (Corrupted previous dialog implementation removed; see cleaned version below.)

  // New: Legacy-compatible full report dialog for a specific collector (by PN)
  void _showCollectorFullReportDialog(String collectorPn) {
    CollectorReportRange range = CollectorReportRange.daily;
    DateTime anchorDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StatefulBuilder(builder: (context, setState) {
              Widget rangeChip(CollectorReportRange r, String label) {
                final selected = range == r;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => range = r),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
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
                    collectorPn: collectorPn,
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

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Download Full Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      rangeChip(CollectorReportRange.daily, 'Daily'),
                      rangeChip(CollectorReportRange.monthly, 'Monthly'),
                      rangeChip(CollectorReportRange.yearly, 'Yearly'),
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
                      if (picked != null) setState(() => anchorDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
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
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onDownload,
                        child: const Text('Download'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSubordinateDeviceCard(Device device) {
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);
    final isOnline = device.isOnline;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
          ),
        ).then((_) => _loadDevices()); // Reload devices when returning
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Small Device Icon with Status
              Stack(
                children: [
                  Image.asset(
                    'assets/images/device_sub.png',
                    width: 40,
                    height: 40,
                  ),
                  if (isOnline)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Device Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SN: ${device.sn}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'STATUS: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PLANT: ${device.plantId.isEmpty ? "null" : device.plantId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DEVICE TYPE: ${device.devcode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      case 2:
      case 3:
      case 4:
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getDeviceStatusText(int status) {
    switch (status) {
      case 0:
        return 'Online';
      case 1:
        return 'Offline';
      case 2:
        return 'Warning';
      case 3:
        return 'Fault';
      case 4:
        return 'PV Loss';
      case 5:
        return 'Grid Loss';
      default:
        return 'Unknown';
    }
  }

  Color _getSignalColor(double signal) {
    if (signal <= 20) return Colors.red;
    if (signal <= 60) return Colors.orange;
    return Colors.green;
  }
}
