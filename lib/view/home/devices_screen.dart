import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:crown_micro_solar/view/home/device_detail_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _selectedDeviceType = 'All Types'; // Changed to match the design

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  void _loadDevices() {
    final plantViewModel = context.read<PlantViewModel>();
    final deviceViewModel = context.read<DeviceViewModel>();
    
    if (plantViewModel.plants.isNotEmpty) {
      final plantId = plantViewModel.plants.first.id;
      // Load all devices without filters to show everything
      deviceViewModel.loadDevicesAndCollectors(plantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceViewModel>(
      builder: (context, deviceViewModel, child) {
        if (deviceViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (deviceViewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${deviceViewModel.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDevices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Filter dropdown
              _buildFilterDropdown(deviceViewModel),
              
              // Content
              _buildDeviceList(deviceViewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(DeviceViewModel deviceViewModel) {
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
            DropdownMenuItem(value: 'Energy storage', child: Text('Energy storage')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDeviceType = value!;
            });
            _loadDevicesWithFilters(deviceViewModel);
          },
        ),
      ),
    );
  }

  void _loadDevicesWithFilters(DeviceViewModel deviceViewModel) {
    final plantViewModel = context.read<PlantViewModel>();
    if (plantViewModel.plants.isNotEmpty) {
      final plantId = plantViewModel.plants.first.id;
      
      if (_selectedDeviceType == 'All Types') {
        // Load all devices without filters
        deviceViewModel.loadDevicesAndCollectors(plantId);
      } else {
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
        deviceViewModel.loadDevicesWithFilters(
          plantId,
          status: '0101',
          deviceType: deviceType,
        );
      }
    }
  }

  Widget _buildDeviceList(DeviceViewModel deviceViewModel) {
    final hasStandaloneDevices = deviceViewModel.standaloneDevices.isNotEmpty;
    final hasCollectors = deviceViewModel.collectors.isNotEmpty;

    if (!hasStandaloneDevices && !hasCollectors) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No devices found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    List<Widget> allDevices = [];

    // Add collectors (dataloggers)
    if (hasCollectors) {
      for (final collector in deviceViewModel.collectors) {
        allDevices.add(_buildCollectorCard(collector, deviceViewModel));
        
        // Add subordinate devices as separate cards if expanded
        final pn = collector['pn']?.toString() ?? '';
        final isExpanded = deviceViewModel.isCollectorExpanded(pn);
        final subordinateDevices = deviceViewModel.getSubordinateDevices(pn);
        
        if (isExpanded && subordinateDevices.isNotEmpty) {
          allDevices.addAll(
            subordinateDevices.map((device) => _buildSubordinateDeviceCard(device))
          );
        }
      }
    }

    // Add standalone devices
    if (hasStandaloneDevices) {
      allDevices.addAll(
        deviceViewModel.standaloneDevices.map((device) => _buildDeviceCard(device))
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: allDevices,
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final isOnline = device.isOnline;
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);
    final hasSubDevices = _hasSubordinateDevices(device);
    final deviceViewModel = context.read<DeviceViewModel>();
    final isExpanded = hasSubDevices ? deviceViewModel.isCollectorExpanded(device.pn) : false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: deviceViewModel,
              child: DeviceDetailScreen(device: device),
            ),
          ),
        );
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
                onTap: () => deviceViewModel.toggleCollectorExpansion(device.pn),
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
                      Text(
                        'STATUS: ',
                        style: const TextStyle(
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
                );
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
    ),);
  }

  Widget _buildCollectorCard(Map<String, dynamic> collector, DeviceViewModel deviceViewModel) {
    final pn = collector['pn']?.toString() ?? '';
    final alias = collector['alias']?.toString() ?? 'Datalogger';
    final status = collector['status'] ?? 0;
    final load = collector['load'] ?? 0;
    final signal = collector['signal'] != null ? double.tryParse(collector['signal'].toString()) : null;
    final isExpanded = deviceViewModel.isCollectorExpanded(pn);
    final subordinateDevices = deviceViewModel.getSubordinateDevices(pn);
    final isOnline = status == 0;
    final statusText = deviceViewModel.getStatusText(status);
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
            builder: (context) => ChangeNotifierProvider.value(
              value: deviceViewModel,
              child: DeviceDetailScreen(device: device),
            ),
          ),
        );
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
                onTap: () => deviceViewModel.toggleCollectorExpansion(pn),
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
                      Text(
                        'STATUS: ',
                        style: const TextStyle(
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
                );
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
    ),);
  }

  Widget _buildSubordinateDeviceCard(Device device) {
    final statusText = device.getStatusText();
    final statusColor = _getStatusColor(device.status);
    final isOnline = device.isOnline;
    final deviceViewModel = context.read<DeviceViewModel>();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: deviceViewModel,
              child: DeviceDetailScreen(device: device),
            ),
          ),
        );
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
                if (!isOnline)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange,
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
                    Text(
                      'STATUS: ',
                      style: const TextStyle(
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
    ),)
    ;
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

  Color _getSignalColor(double signal) {
    if (signal <= 20) return Colors.red;
    if (signal <= 60) return Colors.orange;
    return Colors.green;
  }

  bool _hasSubordinateDevices(Device device) {
    // Check if this device is a collector and has subordinate devices
    final deviceViewModel = context.read<DeviceViewModel>();
    return deviceViewModel.getSubordinateDevices(device.pn).isNotEmpty;
  }
} 