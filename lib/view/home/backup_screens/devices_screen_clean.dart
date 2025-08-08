import 'package:flutter/material.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:crown_micro_solar/view/home/device_detail_screen.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen>
    with WidgetsBindingObserver {
  String _selectedDeviceType = 'All Types';
  late DeviceViewModel _deviceViewModel;
  late PlantViewModel _plantViewModel;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _collectors = [];
  List<Device> _standaloneDevices = [];
  Map<String, List<Device>> _collectorDevices = {};
  Set<String> _expandedCollectors = {};

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Get view models from service locator instead of context
    _deviceViewModel = getIt<DeviceViewModel>();
    _plantViewModel = getIt<PlantViewModel>();

    // Initial data load
    _loadDevices();
  }

  @override
  void dispose() {
    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload when app is resumed
    if (state == AppLifecycleState.resumed) {
      _loadDevices();
    }
  }

  void _toggleCollectorExpansion(String collectorPn) {
    setState(() {
      if (_expandedCollectors.contains(collectorPn)) {
        _expandedCollectors.remove(collectorPn);
      } else {
        _expandedCollectors.add(collectorPn);
      }
    });
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First make sure we have plants loaded
      if (_plantViewModel.plants.isEmpty) {
        print('DevicesScreen: No plants loaded, loading plants first');
        await _plantViewModel.loadPlants();
      }

      if (_plantViewModel.plants.isNotEmpty) {
        final plantId = _plantViewModel.plants.first.id;
        print('DevicesScreen: Loading devices for plant $plantId');

        if (plantId.isEmpty) {
          print('DevicesScreen: Plant ID is empty, cannot load devices');
          setState(() {
            _error = 'Invalid plant ID. Please restart the app or try again.';
            _isLoading = false;
          });
          return;
        }

        // Call the public method from the ViewModel
        await _deviceViewModel.loadDevicesAndCollectors(plantId);

        setState(() {
          _standaloneDevices = _deviceViewModel.standaloneDevices;
          _collectors = _deviceViewModel.collectors;
          _collectorDevices = _deviceViewModel.collectorDevices;
          _isLoading = false;
        });

        print(
            'DevicesScreen: Loaded ${_standaloneDevices.length} standalone devices');
        print('DevicesScreen: Loaded ${_collectors.length} collectors');
      } else {
        print('DevicesScreen: No plants available after reload attempt');
        setState(() {
          _error = 'No plants available. Please check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DevicesScreen: Error loading devices: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDevicesWithFilters() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_plantViewModel.plants.isNotEmpty) {
        final plantId = _plantViewModel.plants.first.id;

        if (_selectedDeviceType == 'All Types') {
          await _loadDevices();
          return;
        }

        // Convert filter text to device codes
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

        // Use the public method from the ViewModel
        await _deviceViewModel.loadDevicesWithFilters(
          plantId,
          status: '0101',
          deviceType: deviceType,
        );

        setState(() {
          _standaloneDevices = _deviceViewModel.standaloneDevices;
          _collectors = _deviceViewModel.collectors;
          _collectorDevices = _deviceViewModel.collectorDevices;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DevicesScreen: Error loading filtered devices: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Device> _getSubordinateDevices(String collectorPn) {
    return _collectorDevices[collectorPn] ?? [];
  }

  bool _isCollectorExpanded(String collectorPn) {
    return _expandedCollectors.contains(collectorPn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with refresh button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Devices",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _plantViewModel.loadPlants().then((_) => _loadDevices());
                },
              ),
            ],
          ),
        ),

        // Filter dropdown
        _buildFilterDropdown(),

        // Device list - use Expanded to take remaining space
        Expanded(
          child: _buildDeviceListContent(),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading devices',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDevices,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListContent() {
    final hasStandaloneDevices = _standaloneDevices.isNotEmpty;
    final hasCollectors = _collectors.isNotEmpty;

    if (!hasStandaloneDevices && !hasCollectors) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_other, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No devices found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _plantViewModel.loadPlants().then((_) => _loadDevices());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return _buildDeviceList();
  }

  Widget _buildDeviceList() {
    List<Widget> allDevices = [];
    final hasStandaloneDevices = _standaloneDevices.isNotEmpty;
    final hasCollectors = _collectors.isNotEmpty;

    // Add collectors (dataloggers)
    if (hasCollectors) {
      for (final collector in _collectors) {
        allDevices.add(_buildCollectorCard(collector));

        // Add subordinate devices as separate cards if expanded
        final pn = collector['pn']?.toString() ?? '';
        final isExpanded = _isCollectorExpanded(pn);
        final subordinateDevices = _getSubordinateDevices(pn);

        if (isExpanded && subordinateDevices.isNotEmpty) {
          allDevices.addAll(subordinateDevices
              .map((device) => _buildSubordinateDeviceCard(device)));
        }
      }
    }

    // Add standalone devices
    if (hasStandaloneDevices) {
      allDevices
          .addAll(_standaloneDevices.map((device) => _buildDeviceCard(device)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: allDevices,
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDeviceType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            DropdownMenuItem(value: 'All Types', child: Text('All Types')),
            DropdownMenuItem(value: 'Inverter', child: Text('Inverter')),
            DropdownMenuItem(value: 'Datalogger', child: Text('Datalogger')),
            DropdownMenuItem(value: 'Env-monitor', child: Text('Env-monitor')),
            DropdownMenuItem(value: 'Smart meter', child: Text('Smart meter')),
            DropdownMenuItem(
                value: 'Energy storage', child: Text('Energy storage')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDeviceType = value!;
            });
            _loadDevicesWithFilters();
          },
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final isOnline = device.isOnline;
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);
    final hasSubDevices = _hasSubordinateDevices(device);
    final isExpanded = hasSubDevices ? _isCollectorExpanded(device.pn) : false;

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
              // Animated dropdown arrow on the left
              if (hasSubDevices)
                GestureDetector(
                  onTap: () => _toggleCollectorExpansion(device.pn),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
              if (hasSubDevices) const SizedBox(width: 8),
              // Device Icon with Stack
              Stack(
                children: [
                  Image.asset(
                    'assets/images/device1.png',
                    width: 60,
                    height: 60,
                  ),
                  if (isOnline)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Device Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALIAS: ${device.alias.isNotEmpty ? device.alias : device.pn}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PN: ${device.pn}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LOAD: ${device.load ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
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
                    if (device.signal != null && device.signal! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'SIGNAL: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          RatingBarIndicator(
                            rating: device.signal! / 20.0,
                            itemBuilder: (context, index) => Icon(
                              Icons.circle,
                              color: _getSignalColor(device.signal!),
                              size: 12,
                            ),
                            itemCount: 5,
                            itemSize: 12.0,
                            unratedColor: Colors.grey.withAlpha(50),
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.signal!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSignalColor(device.signal!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Double right arrow icon for navigation
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceDetailScreen(device: device),
                    ),
                  ).then((_) => _loadDevices());
                },
                child: Icon(
                  Icons.keyboard_double_arrow_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
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
    final isExpanded = _isCollectorExpanded(pn);
    final subordinateDevices = _getSubordinateDevices(pn);
    final isOnline = status == 0;
    final statusText = _getDeviceStatusText(status);
    final statusColor = _getStatusColor(status);
    final hasSubDevices = subordinateDevices.isNotEmpty;

    // Create a Device object from collector data for navigation
    final device = Device(
      id: pn,
      pn: pn,
      devcode: collector['devcode'] ?? 0,
      devaddr: collector['devaddr'] ?? 0,
      sn: collector['sn']?.toString() ?? '',
      alias: alias,
      status: status,
      uid: collector['uid'] ?? 0,
      pid: collector['pid'] ?? 0,
      timezone: collector['timezone'] ?? 0,
      name: alias,
      type: 'Datalogger',
      plantId: collector['plantId']?.toString() ?? '',
      lastUpdate: DateTime.now(),
      parameters: {
        'pn': pn,
        'sn': collector['sn']?.toString() ?? '',
        'devcode': collector['devcode']?.toString() ?? '',
        'devaddr': collector['devaddr']?.toString() ?? '',
        'token': '',
        'Secret': '',
      },
      load: load,
      signal: signal,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
          ),
        ).then((_) => _loadDevices());
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
              // Animated dropdown arrow on the left
              if (hasSubDevices)
                GestureDetector(
                  onTap: () => _toggleCollectorExpansion(pn),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
              if (hasSubDevices) const SizedBox(width: 8),
              // Device Icon with Stack
              Stack(
                children: [
                  Image.asset(
                    'assets/images/device1.png',
                    width: 60,
                    height: 60,
                  ),
                  if (isOnline)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Device Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALIAS: $alias',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PN: $pn',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LOAD: $load',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
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
                    if (signal != null && signal > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'SIGNAL: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          RatingBarIndicator(
                            rating: signal / 20.0,
                            itemBuilder: (context, index) => Icon(
                              Icons.circle,
                              color: _getSignalColor(signal),
                              size: 12,
                            ),
                            itemCount: 5,
                            itemSize: 12.0,
                            unratedColor: Colors.grey.withAlpha(50),
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${signal.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSignalColor(signal),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Double right arrow icon for navigation
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceDetailScreen(device: device),
                    ),
                  ).then((_) => _loadDevices());
                },
                child: Icon(
                  Icons.keyboard_double_arrow_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
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
        ).then((_) => _loadDevices());
      },
      child: Container(
        margin: const EdgeInsets.only(left: 24, bottom: 12),
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
              // Device Icon with Stack
              Stack(
                children: [
                  Image.asset(
                    'assets/images/device1.png',
                    width: 50,
                    height: 50,
                  ),
                  if (isOnline)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Device Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALIAS: ${device.alias.isNotEmpty ? device.alias : device.pn}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PN: ${device.pn}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'STATUS: ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow for navigation
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

  bool _hasSubordinateDevices(Device device) {
    return _getSubordinateDevices(device.pn).isNotEmpty;
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
        return 'Fault';
      case 3:
        return 'Standby';
      case 4:
        return 'Warning';
      case 5:
        return 'Error';
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
