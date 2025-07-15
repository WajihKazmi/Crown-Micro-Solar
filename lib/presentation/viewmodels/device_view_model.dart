import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';

class DeviceViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Device> _devices = [];
  final DeviceRepository _deviceRepository = DeviceRepository(ApiClient());

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Device> get devices => _devices;

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

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 