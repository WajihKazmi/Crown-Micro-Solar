import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/view/home/device_detail_screen.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
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
    final hasAny =
        _deviceVM.allDevices.isNotEmpty || _deviceVM.collectors.isNotEmpty;
    setState(() {
      // Only show blocking loading when we have no data to render
      _loading = !hasAny && _deviceVM.isLoading;
      _error = _deviceVM.error;
      if (hasAny) _initialLoadDone = true;
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

      // INSTANT CACHE LOAD: Show cached data immediately if available
      final hadCache = await _deviceVM.loadDevicesFromCache(plantId);
      if (hadCache && mounted) {
        setState(() {
          _loading = false;
          _initialLoadDone = true;
        });

        // Then refresh from network in background WITHOUT blocking UI
        _deviceVM.loadDevicesAndCollectors(plantId).then((_) {
          // ViewModel will notify listeners when done
        }).catchError((e) {
          print('Background refresh error: $e');
        });
        return; // Exit early to prevent duplicate loading
      }

      // No cache available, load from network
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

    final hasAnyList =
        _deviceVM.allDevices.isNotEmpty || _deviceVM.collectors.isNotEmpty;
    Widget content;
    // Only show full-screen loading when we have NO data AND loading is in progress
    if (!hasAnyList && _loading && !_initialLoadDone) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null && !hasAnyList) {
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
    } else if (!hasAnyList) {
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
        // Subtle refresh indicator when background loading but content is shown
        if (_deviceVM.isLoading && hasAnyList)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.4),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: FloatingActionButton.extended(
            heroTag: 'add_datalogger_fab',
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.add),
            label: const Text('Datalogger'),
            onPressed: ((!hasAnyList) && (_loading || !_initialLoadDone))
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
        // Secondary (dropdown) cards removed; sub-devices shown in detail page
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
    // Use subordinate devices (if any) to display a representative SN and plant/type context
    final subDevices = _deviceVM.getSubordinateDevices(pn);
    final Device? firstSub = subDevices.isNotEmpty ? subDevices.first : null;
    final sn = firstSub?.sn ?? '';
    final plant = firstSub?.plantId ?? '';
    final dtype = firstSub?.type ?? 'Datalogger';
    final statusText = _getDeviceStatusText(status);
    final statusColor = _getStatusColor(status);
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    // Get devcode and devaddr from first subordinate device (needed for deletion)
    final devcode = firstSub?.devcode ?? 0;
    final devaddr = firstSub?.devaddr ?? 0;

    // Wrap with Dismissible for swipe-to-delete
    return Dismissible(
      key: Key('collector_${pn}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before deleting
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Delete Datalogger'),
                content: Text(
                  'Are you sure you want to delete this datalogger?\n\n'
                  'Alias: $alias\n'
                  'PN: $pn\n'
                  'Load: $load device(s)',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        // Perform delete operation
        try {
          final repo = getIt<DeviceRepository>();
          final plantId = plant.isNotEmpty
              ? plant
              : (_plantVM.plants.isNotEmpty ? _plantVM.plants.first.id : '');

          print('Deleting collector: $pn, plantId: $plantId');

          // Use the first subordinate device's info for deletion if available
          final result = await repo.deleteDevice(
            plantId: plantId,
            pn: pn,
            sn: sn.isNotEmpty ? sn : pn, // Use pn if sn is empty
            devcode: devcode,
            devaddr: devaddr,
          );

          if (result['err'] == 0 || result['err'] == 258) {
            // Success (258 is also considered success) - reload devices
            await _loadDevices(force: true);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Datalogger $alias deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Failed - show error and reload to restore collector
            final errorMsg = result['desc'] ?? 'Unknown error';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete datalogger: $errorMsg'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            // Reload to restore collector in list
            await _loadDevices(force: true);
          }
        } catch (e) {
          print('Error deleting collector: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // Reload to restore collector in list
          await _loadDevices(force: true);
        }
      },
      child: GestureDetector(
        onTap: () async {
          // If exactly one subordinate device, open its detail directly; else open collector details
          if (subDevices.length == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeviceDetailScreen(device: firstSub!),
              ),
            );
          } else if (subDevices.isNotEmpty) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectorDetailScreen(
                  collector: collector,
                  prefetchedSubDevices: subDevices,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No devices found under this datalogger')),
            );
          }
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
                          Text('SN: ${sn.isEmpty ? '—' : sn}',
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
                          ],
                          const SizedBox(height: 4),
                          Text('PLANT: ${plant.isEmpty ? "null" : plant}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('DEVICE TYPE: $dtype',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                  IconButton(
                    tooltip: 'Open Datalogger Details',
                    icon: const Icon(Icons.description_outlined,
                        color: Colors.black54),
                    onPressed: () async {
                      if (pn.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Collector PN missing')));
                        return;
                      }
                      final subs = _deviceVM.getSubordinateDevices(pn);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectorDetailScreen(
                            collector: collector,
                            prefetchedSubDevices: subs,
                          ),
                        ),
                      );
                    },
                  )
                ]))),
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);

    // Wrap card in Dismissible for swipe-to-delete functionality
    return Dismissible(
      key: Key('device_${device.sn}_${device.pn}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before deleting
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Delete Device'),
                content: Text(
                  'Are you sure you want to delete this device?\n\n'
                  'Alias: ${device.alias.isNotEmpty ? device.alias : device.pn}\n'
                  'SN: ${device.sn}\n'
                  'PN: ${device.pn}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        // Perform delete operation
        try {
          final repo = getIt<DeviceRepository>();
          final plantId = device.plantId.isNotEmpty
              ? device.plantId
              : device.pid.toString();

          print('Deleting device: ${device.sn}, plantId: $plantId');

          final result = await repo.deleteDevice(
            plantId: plantId,
            pn: device.pn,
            sn: device.sn,
            devcode: device.devcode,
            devaddr: device.devaddr,
          );

          if (result['err'] == 0) {
            // Success - reload devices
            await _loadDevices(force: true);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Device ${device.alias.isNotEmpty ? device.alias : device.sn} deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Failed - show error and reload to restore device
            final errorMsg = result['desc'] ?? 'Unknown error';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete device: $errorMsg'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            // Reload to restore device in list
            await _loadDevices(force: true);
          }
        } catch (e) {
          print('Error deleting device: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // Reload to restore device in list
          await _loadDevices(force: true);
        }
      },
      child: GestureDetector(
        onTap: () async {
          // Pre-warm energy flow so detail cards render instantly
          try {
            final rt = getIt<RealtimeDataService>();
            await rt.prefetchEnergyFlow(device);
          } catch (_) {}
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
                      Text('SN: ${device.sn}',
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
                                color: _getSignalColor(device.signal!),
                                size: 10),
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
                      ],
                      const SizedBox(height: 4),
                      Text(
                          'PLANT: ${device.plantId.isEmpty ? "null" : device.plantId}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text('DEVICE TYPE: ${device.type}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ]),
              ),
              Icon(Icons.keyboard_double_arrow_right, color: Colors.grey[600])
            ]),
          ),
        ), // closing GestureDetector child (Container)
      ), // closing GestureDetector
    ); // closing Dismissible
  }

  // (Corrupted previous dialog implementation removed; see cleaned version below.)

  // New: Legacy-compatible full report dialog for a specific collector (by PN)
  // Removed full report dialog; not used and replaced with details navigation

  // Removed subordinate device card; secondary dropdown card is eliminated

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
