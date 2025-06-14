import 'package:flutter/foundation.dart';

class DeviceViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _devices = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get devices => _devices;

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock loading devices
      await Future.delayed(const Duration(seconds: 1));
      _devices = [
        {'id': '1', 'name': 'Device 1', 'status': 'online'},
        {'id': '2', 'name': 'Device 2', 'status': 'offline'},
      ];
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