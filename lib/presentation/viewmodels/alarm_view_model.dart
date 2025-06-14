import 'package:flutter/foundation.dart';

class AlarmViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _alarms = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get alarms => _alarms;

  Future<void> loadAlarms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock loading alarms
      await Future.delayed(const Duration(seconds: 1));
      _alarms = [
        {
          'id': '1',
          'type': 'warning',
          'message': 'Low battery level',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'active'
        },
        {
          'id': '2',
          'type': 'error',
          'message': 'Connection lost',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'status': 'resolved'
        },
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acknowledgeAlarm(String alarmId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock acknowledging alarm
      await Future.delayed(const Duration(seconds: 1));
      _alarms = _alarms.map((alarm) {
        if (alarm['id'] == alarmId) {
          return {...alarm, 'status': 'acknowledged'};
        }
        return alarm;
      }).toList();
      _isLoading = false;
      notifyListeners();
      return true;
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