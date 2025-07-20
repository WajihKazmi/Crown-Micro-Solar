import 'package:flutter/material.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceViewModel extends ChangeNotifier {
  final DeviceRepository _deviceRepository;
  
  List<Device> _standaloneDevices = [];
  List<Map<String, dynamic>> _collectors = [];
  Map<String, List<Device>> _collectorDevices = {};
  List<Device> _allDevices = [];
  
  bool _isLoading = false;
  String? _error;
  Set<String> _expandedCollectors = {};

  DeviceViewModel(this._deviceRepository);

  // Getters
  List<Device> get standaloneDevices => _standaloneDevices;
  List<Map<String, dynamic>> get collectors => _collectors;
  Map<String, List<Device>> get collectorDevices => _collectorDevices;
  List<Device> get allDevices => _allDevices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get expandedCollectors => _expandedCollectors;

  // Load devices and collectors for a plant
  Future<void> loadDevicesAndCollectors(String plantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('DeviceViewModel: Loading devices and collectors for plant $plantId');
      
      final result = await _deviceRepository.getDevicesAndCollectors(plantId);
      
      _standaloneDevices = result['standaloneDevices'] ?? [];
      _collectors = result['collectors'] ?? [];
      _collectorDevices = result['collectorDevices'] ?? {};
      _allDevices = result['allDevices'] ?? [];
      
      print('DeviceViewModel: Loaded ${_standaloneDevices.length} standalone devices');
      print('DeviceViewModel: Loaded ${_collectors.length} collectors');
      print('DeviceViewModel: Loaded ${_allDevices.length} total devices');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DeviceViewModel: Error loading devices: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load devices with filters (matching old app functionality)
  Future<void> loadDevicesWithFilters(String plantId, {String status = '0101', String deviceType = '0101'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('DeviceViewModel: Loading devices with filters - status: $status, deviceType: $deviceType');
      
      final devices = await _deviceRepository.getDevicesWithFilters(plantId, status: status, deviceType: deviceType);
      
      // Clear previous data
      _standaloneDevices = [];
      _collectors = [];
      _collectorDevices = {};
      _allDevices = devices;
      
      // Separate collectors and devices
      for (final device in devices) {
        if (device.isCollector) {
          _collectors.add({
            'pn': device.pn,
            'alias': device.alias,
            'status': device.status,
            'load': device.load,
            'signal': device.signal,
            'firmware': device.firmware,
          });
        } else {
          _standaloneDevices.add(device);
        }
      }
      
      print('DeviceViewModel: Loaded ${_standaloneDevices.length} standalone devices with filters');
      print('DeviceViewModel: Loaded ${_collectors.length} collectors with filters');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DeviceViewModel: Error loading devices with filters: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle collector expansion
  void toggleCollectorExpansion(String collectorPn) {
    if (_expandedCollectors.contains(collectorPn)) {
      _expandedCollectors.remove(collectorPn);
    } else {
      _expandedCollectors.add(collectorPn);
    }
    notifyListeners();
  }

  // Get subordinate devices for a collector
  List<Device> getSubordinateDevices(String collectorPn) {
    return _collectorDevices[collectorPn] ?? [];
  }

  // Check if collector is expanded
  bool isCollectorExpanded(String collectorPn) {
    return _expandedCollectors.contains(collectorPn);
  }

  // Get device type text (matching old app)
  String getDeviceTypeText(int devcode) {
    switch (devcode) {
      case 512:
        return 'Inverter';
      case 768:
        return 'Env-monitor';
      case 1024:
        return 'Smart meter';
      case 1280:
        return 'Combining manifolds';
      case 1536:
        return 'Camera';
      case 1792:
        return 'Battery';
      case 2048:
        return 'Charger';
      case 2304:
      case 2452:
      case 2449:
      case 2400:
        return 'Energy storage machine';
      case 2560:
        return 'Anti-islanding';
      case -1:
        return 'Datalogger';
      default:
        return 'Device $devcode';
    }
  }

  // Get status text (matching old app)
  String getStatusText(int status) {
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

  // Get status color (matching old app)
  Color getStatusColor(int status) {
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

  // Get signal strength color (for collectors)
  Color getSignalColor(double? signal) {
    if (signal == null || signal == 0) return Colors.grey;
    if (signal <= 20) return Colors.red;
    if (signal <= 60) return Colors.orange;
    return Colors.green;
  }

  // Get signal strength rating (for collectors)
  double getSignalRating(double? signal) {
    if (signal == null || signal == 0) return 0.0;
    return signal / 20.0; // Normalize to 0-5 scale
  }

  // Clear all data
  void clear() {
    _standaloneDevices.clear();
    _collectors.clear();
    _collectorDevices.clear();
    _allDevices.clear();
    _expandedCollectors.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Get total device count
  int get totalDeviceCount => _allDevices.length;
  
  // Get online device count
  int get onlineDeviceCount => _allDevices.where((d) => d.isOnline).length;
  
  // Get offline device count
  int get offlineDeviceCount => _allDevices.where((d) => !d.isOnline).length;
  
  // Get collector count
  int get collectorCount => _collectors.length;
  
  // Get standalone device count
  int get standaloneDeviceCount => _standaloneDevices.length;
} 