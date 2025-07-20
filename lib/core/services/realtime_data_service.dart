import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class RealtimeDataService extends ChangeNotifier {
  final ApiClient _apiClient;
  final DeviceRepository _deviceRepository;
  final PlantRepository _plantRepository;
  
  Timer? _updateTimer;
  bool _isRunning = false;
  
  // Current data
  List<Plant> _plants = [];
  List<Device> _devices = [];
  Map<String, double> _devicePowerData = {};
  Map<String, Map<String, dynamic>> _deviceRealTimeData = {};
  
  // Update intervals (in seconds)
  static const int _plantUpdateInterval = 30; // Update plants every 30 seconds
  static const int _deviceUpdateInterval = 15; // Update devices every 15 seconds
  
  RealtimeDataService(this._apiClient, this._deviceRepository, this._plantRepository);

  // Getters
  List<Plant> get plants => _plants;
  List<Device> get devices => _devices;
  Map<String, double> get devicePowerData => _devicePowerData;
  Map<String, Map<String, dynamic>> get deviceRealTimeData => _deviceRealTimeData;
  bool get isRunning => _isRunning;

  // Start real-time data updates
  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    print('RealtimeDataService: Starting real-time data updates');
    
    // Initial data load
    await _loadInitialData();
    
    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: _deviceUpdateInterval), (timer) {
      _updateRealTimeData();
    });
    
    notifyListeners();
  }

  // Stop real-time data updates
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _updateTimer?.cancel();
    _updateTimer = null;
    print('RealtimeDataService: Stopped real-time data updates');
    
    notifyListeners();
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    try {
      print('RealtimeDataService: Loading initial data');
      
      // Load plants
      _plants = await _plantRepository.getPlants();
      
      // Load devices for each plant
      for (final plant in _plants) {
        final result = await _deviceRepository.getDevicesAndCollectors(plant.id);
        final allDevices = result['allDevices'] ?? [];
        _devices.addAll(allDevices);
      }
      
      print('RealtimeDataService: Loaded ${_plants.length} plants and ${_devices.length} devices');
      
      // Initial real-time data update
      await _updateRealTimeData();
      
    } catch (e) {
      print('RealtimeDataService: Error loading initial data: $e');
    }
  }

  // Update real-time data
  Future<void> _updateRealTimeData() async {
    if (!_isRunning) return;
    
    try {
      print('RealtimeDataService: Updating real-time data');
      
      // Update plant data (less frequent)
      if (_plants.isNotEmpty) {
        await _updatePlantData();
      }
      
      // Update device data (more frequent)
      if (_devices.isNotEmpty) {
        await _updateDeviceData();
      }
      
      notifyListeners();
      
    } catch (e) {
      print('RealtimeDataService: Error updating real-time data: $e');
    }
  }

  // Update plant real-time data
  Future<void> _updatePlantData() async {
    try {
      for (final plant in _plants) {
        final updatedPlant = await _getPlantRealTimeData(plant.id);
        if (updatedPlant != null) {
          final index = _plants.indexWhere((p) => p.id == plant.id);
          if (index != -1) {
            _plants[index] = updatedPlant;
          }
        }
      }
    } catch (e) {
      print('RealtimeDataService: Error updating plant data: $e');
    }
  }

  // Update device real-time data
  Future<void> _updateDeviceData() async {
    try {
      for (final device in _devices) {
        // Get real-time power data for the device
        final powerData = await _getDevicePowerData(device);
        if (powerData != null) {
          _devicePowerData[device.pn] = powerData;
        }
        
        // Get detailed real-time data for important devices (inverters, etc.)
        if (device.isInverter || device.isCollector) {
          final realTimeData = await _getDeviceDetailedRealTimeData(device);
          if (realTimeData != null) {
            _deviceRealTimeData[device.pn] = realTimeData;
          }
        }
      }
    } catch (e) {
      print('RealtimeDataService: Error updating device data: $e');
    }
  }

  // Get plant real-time data
  Future<Plant?> _getPlantRealTimeData(String plantId) async {
    try {
      const salt = '12345678';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final secret = prefs.getString('Secret') ?? '';
      
      final action = '&action=queryPlantActiveOuputPowerOneDay&plantid=$plantId&date=${_getCurrentDate()}';
      final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
      final data = salt + secret + token + action + postaction;
      final sign = sha1.convert(utf8.encode(data)).toString();
      final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
      
      final response = await _apiClient.signedPost(url);
      final dataJson = json.decode(response.body);
      
      if (dataJson['err'] == 0 && dataJson['dat'] != null) {
        final plantData = dataJson['dat'];
        return Plant.fromJson({
          'id': plantId,
          'name': plantData['plantName'] ?? '',
          'capacity': plantData['capacity'] ?? 0.0,
          'currentPower': plantData['currentPower'] ?? 0.0,
          'dailyGeneration': plantData['dailyGeneration'] ?? 0.0,
          'monthlyGeneration': plantData['monthlyGeneration'] ?? 0.0,
          'yearlyGeneration': plantData['yearlyGeneration'] ?? 0.0,
          'lastUpdate': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('RealtimeDataService: Error getting plant real-time data: $e');
    }
    return null;
  }

  // Get device power data
  Future<double?> _getDevicePowerData(Device device) async {
    try {
      const salt = '12345678';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final secret = prefs.getString('Secret') ?? '';
      
      final action = '&action=queryDeviceDataOneDayPaging&pn=${device.pn}&sn=${device.sn}&devcode=${device.devcode}&devaddr=${device.devaddr}&date=${_getCurrentDate()}&page=0&pagesize=1';
      final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
      final data = salt + secret + token + action + postaction;
      final sign = sha1.convert(utf8.encode(data)).toString();
      final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
      
      final response = await _apiClient.signedPost(url);
      final dataJson = json.decode(response.body);
      
      if (dataJson['err'] == 0 && dataJson['dat'] != null && dataJson['dat']['data'] != null) {
        final deviceData = dataJson['dat']['data'] as List;
        if (deviceData.isNotEmpty) {
          final latestData = deviceData.first;
          return double.tryParse(latestData['outputPower']?.toString() ?? '0') ?? 0.0;
        }
      }
    } catch (e) {
      print('RealtimeDataService: Error getting device power data: $e');
    }
    return null;
  }

  // Get detailed device real-time data
  Future<Map<String, dynamic>?> _getDeviceDetailedRealTimeData(Device device) async {
    try {
      return await _deviceRepository.getDeviceRealTimeData(
        device.pn,
        device.sn,
        device.devcode,
        device.devaddr,
      );
    } catch (e) {
      print('RealtimeDataService: Error getting device detailed real-time data: $e');
    }
    return null;
  }

  // Get current date in required format
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Get total current power generation
  double get totalCurrentPower {
    return _plants.fold<double>(0, (sum, plant) => sum + plant.currentPower);
  }

  // Get total daily generation
  double get totalDailyGeneration {
    return _plants.fold<double>(0, (sum, plant) => sum + plant.dailyGeneration);
  }

  // Get total monthly generation
  double get totalMonthlyGeneration {
    return _plants.fold<double>(0, (sum, plant) => sum + plant.monthlyGeneration);
  }

  // Get total yearly generation
  double get totalYearlyGeneration {
    return _plants.fold<double>(0, (sum, plant) => sum + plant.yearlyGeneration);
  }

  // Get device by PN
  Device? getDeviceByPn(String pn) {
    try {
      return _devices.firstWhere((device) => device.pn == pn);
    } catch (e) {
      return null;
    }
  }

  // Get plant by ID
  Plant? getPlantById(String id) {
    try {
      return _plants.firstWhere((plant) => plant.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
} 