import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/data/repositories/alarm_repository.dart';
import 'package:crown_micro_solar/data/models/alarm/alarm_model.dart';

class AlarmViewModel extends ChangeNotifier {
  final AlarmRepository _alarmRepository;
  bool _isLoading = false;
  String? _error;
  List<Alarm> _alarms = [];
  List<Warning> _warnings = [];

  AlarmViewModel(this._alarmRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Alarm> get alarms => _alarms;
  List<Warning> get warnings => _warnings;

  Future<void> loadAlarms(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alarms = await _alarmRepository.getAlarms(plantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWarnings(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warnings = await _alarmRepository.getWarnings(plantId);
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
      final success = await _alarmRepository.acknowledgeAlarm(alarmId);
      if (success) {
        _alarms = _alarms.where((alarm) => alarm.id != alarmId).toList();
      }
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

  Future<bool> acknowledgeWarning(String warningId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _alarmRepository.acknowledgeWarning(warningId);
      if (success) {
        _warnings = _warnings.where((warning) => warning.id != warningId).toList();
      }
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