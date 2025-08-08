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

    // Get view models from service locator
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

        String deviceType = '0101';

        switch (_selectedDeviceType) {
          case 'All Types':
            deviceType = '0101';
            break;
          case 'Inverter':
            deviceType = '1010';
            break;
          case 'Datalogger':
            deviceType = '1020';
            break;
          case 'Env-monitor':
            deviceType = '1030';
            break;
          case 'Smart meter':
            deviceType = '1060';
            break;
          case 'Energy storage':
            deviceType = '2452';
            break;
        }

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

  void _toggleCollectorExpansion(String collectorPn) {
    setState(() {
      if (_expandedCollectors.contains(collectorPn)) {
        _expandedCollectors.remove(collectorPn);
      } else {
        _expandedCollectors.add(collectorPn);
      }
    });
  }

  List<Device> _getSubordinateDevices(String collectorPn) {
    return _collectorDevices[collectorPn] ?? [];
  }

  bool _isCollectorExpanded(String collectorPn) {
    return _expandedCollectors.contains(collectorPn);
  }

  bool _hasSubordinateDevices(Device device) {
    if (device.pn == null || device.pn!.isEmpty) return false;
    return _getSubordinateDevices(device.pn!).isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Custom header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Devices',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDevices,
                ),
              ],
            ),
          ),

          // Filter dropdown
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _selectedDeviceType,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: const [
                DropdownMenuItem(value: 'All Types', child: Text('All Types')),
                DropdownMenuItem(value: 'Inverter', child: Text('Inverter')),
                DropdownMenuItem(
                    value: 'Datalogger', child: Text('Datalogger')),
                DropdownMenuItem(
                    value: 'Env-monitor', child: Text('Env-monitor')),
                DropdownMenuItem(
                    value: 'Smart meter', child: Text('Smart meter')),
                DropdownMenuItem(
                    value: 'Energy storage', child: Text('Energy storage')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedDeviceType = value;
                });
                _loadDevicesWithFilters();
              },
            ),
          ),

          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

    final hasDevices = _collectors.isNotEmpty || _standaloneDevices.isNotEmpty;

    if (!hasDevices) {
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
              onPressed: _loadDevices,
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

    // Build device list
    List<Widget> deviceWidgets = [];

    // Add collectors
    for (final collector in _collectors) {
      deviceWidgets.add(_buildCollectorCard(collector));
    }

    // Add standalone devices
    for (final device in _standaloneDevices) {
      deviceWidgets.add(_buildDeviceCard(device));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: deviceWidgets,
    );
  }

  Widget _buildCollectorCard(Map<String, dynamic> collector) {
    final String pn = collector['pn'] ?? '';
    final String alias = collector['alias'] ?? 'Unknown';
    final int status = collector['status'] ?? 0;
    final String firmware = collector['fireware'] ?? '';
    final int signal = collector['signal'] ?? 0;

    final statusColor = _getStatusColor(status);
    final statusText = _getDeviceStatusText(status);
    final isExpanded = _isCollectorExpanded(pn);
    final subordinateDevices = _getSubordinateDevices(pn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Collector card
        Card(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: InkWell(
            onTap: () => _toggleCollectorExpansion(pn),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.devices_other),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alias,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'S/N: $pn',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.wifi,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '$signal%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (firmware.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Firmware: $firmware',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${subordinateDevices.length} connected device${subordinateDevices.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subordinate devices
        if (isExpanded)
          ...subordinateDevices
              .map((device) => _buildSubordinateDeviceCard(device)),
      ],
    );
  }

  Widget _buildDeviceCard(Device device) {
    final bool isOnline = device.isOnline;
    final String statusText = device.getStatusText();
    final Color statusColor = _getStatusColor(device.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(device: device),
            ),
          ).then((_) => _loadDevices());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.solar_power),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.alias.isNotEmpty
                          ? device.alias
                          : device.pn ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/N: ${device.pn ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubordinateDeviceCard(Device device) {
    return Card(
      margin: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
      color: Colors.grey[50],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(device: device),
            ),
          ).then((_) => _loadDevices());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.solar_power, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.alias.isNotEmpty
                          ? device.alias
                          : device.pn ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'S/N: ${device.pn ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(device.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  device.getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(device.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
