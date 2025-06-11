import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/data/repositories/device_repository.dart';
import 'package:crown_micro_solar/data/models/device/device_model.dart';

class DeviceViewModel extends ChangeNotifier {
  final DeviceRepository _deviceRepository;
  bool _isLoading = false;
  String? _error;
  List<Device> _devices = [];
  Device? _selectedDevice;
  Map<String, dynamic>? _deviceData;

  DeviceViewModel(this._deviceRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  Map<String, dynamic>? get deviceData => _deviceData;

  Future<void> loadDevices(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _deviceRepository.getDevices(plantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDeviceStatus(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedDevice = await _deviceRepository.getDeviceStatus(deviceId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDeviceData(String deviceId, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _deviceData = await _deviceRepository.getDeviceData(deviceId, date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDeviceParameters(String deviceId, Map<String, dynamic> parameters) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _deviceRepository.updateDeviceParameters(deviceId, parameters);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 