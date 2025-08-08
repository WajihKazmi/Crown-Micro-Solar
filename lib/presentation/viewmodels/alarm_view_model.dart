import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/alarm/alarm_model.dart';
import 'package:crown_micro_solar/presentation/repositories/alarm_repository.dart';

class AlarmViewModel extends ChangeNotifier {
  final AlarmRepository _alarmRepository;

  AlarmViewModel(this._alarmRepository);

  // State management
  bool _isLoading = false;
  String? _error;
  List<Alarm> _alarms = [];
  List<Warning> _warnings = [];

  // Filters
  String _selectedPeriod = 'Week';
  String _selectedAlarmType = 'All Type';
  String _selectedDevice = 'All Devices';
  String _selectedStatus = 'All Status';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Alarm> get alarms => _alarms;
  List<Warning> get warnings => _warnings;
  String get selectedPeriod => _selectedPeriod;
  String get selectedAlarmType => _selectedAlarmType;
  String get selectedDevice => _selectedDevice;
  String get selectedStatus => _selectedStatus;

  // Combined list of all alarm items for display
  List<Warning> get allAlarmItems {
    return _warnings;
  }

  // Filter options
  List<String> get periodOptions => ['Week', 'Month', 'Year'];
  List<String> get alarmTypeOptions => ['All Type', 'FAULT', 'WARNING'];
  List<String> get deviceOptions {
    Set<String> devices = {'All Devices'};

    // Get unique device IDs from alarms and warnings
    for (final alarm in _alarms) {
      if (alarm.deviceId.isNotEmpty) {
        devices.add(alarm.deviceId);
      }
      if (alarm.parameters['devicePn'] != null) {
        devices.add(alarm.parameters['devicePn'].toString());
      }
    }

    for (final warning in _warnings) {
      if (warning.sn.isNotEmpty) {
        devices.add(warning.sn);
      }
      if (warning.pn.isNotEmpty) {
        devices.add(warning.pn);
      }
    }

    // Ensure current selection is always present to avoid DropdownButton assertion
    if (_selectedDevice != 'All Devices') {
      devices.add(_selectedDevice);
    }
    return devices.toList();
  }

  List<String> get statusOptions => ['All Status', 'Untreated', 'Processed'];

  // Statistics
  int get totalAlarms => _alarms.length + _warnings.length;
  int get faultCount => _warnings.where((warning) => warning.level == 2).length;
  int get warningCount =>
      _warnings.where((warning) => warning.level == 0).length;
  int get untreatedCount =>
      _warnings.where((warning) => !warning.handle).length;
  int get processedCount => _warnings.where((warning) => warning.handle).length;

  /// Load alarms and warnings for a plant
  Future<void> loadAlarms(String plantId) async {
    _setLoading(true);
    _setError(null);

    try {
      print('AlarmViewModel: Loading alarms for plant $plantId');
      print(
          'AlarmViewModel: Current filters - period: $_selectedPeriod, type: $_selectedAlarmType, device: $_selectedDevice, status: $_selectedStatus');

      // Map filters to API parameters
      String? startDate, endDate;
      if (_selectedPeriod != 'Week') {
        // Calculate date range based on period
        final now = DateTime.now();
        switch (_selectedPeriod) {
          case 'Month':
            startDate =
                DateTime(now.year, now.month, 1).toString().split(' ')[0];
            endDate =
                DateTime(now.year, now.month + 1, 0).toString().split(' ')[0];
            break;
          case 'Year':
            startDate = DateTime(now.year, 1, 1).toString().split(' ')[0];
            endDate = DateTime(now.year, 12, 31).toString().split(' ')[0];
            break;
        }
      }

      // Load warnings using the new API
      _warnings = await _alarmRepository.getWarnings(
        plantId,
        startDate: startDate,
        endDate: endDate,
        deviceType: _selectedDevice != 'All Devices' ? _selectedDevice : null,
        status: _selectedStatus != 'All Status' ? _selectedStatus : null,
        alarmType: _selectedAlarmType != 'All Type' ? _selectedAlarmType : null,
        sn: (_selectedDevice != 'All Devices' &&
                !_isKnownDeviceType(_selectedDevice))
            ? _selectedDevice
            : null,
      );

      print('AlarmViewModel: Loaded ${_warnings.length} warnings');

      // If selected device is not present in the new warnings set, reset to All Devices
      if (_selectedDevice != 'All Devices') {
        final hasSelected = _warnings.any((w) =>
            w.sn == _selectedDevice ||
            w.pn == _selectedDevice ||
            w.deviceType == _selectedDevice);
        if (!hasSelected) {
          _selectedDevice = 'All Devices';
        }
      }

      _setLoading(false);
    } catch (e) {
      print('AlarmViewModel: Error loading alarms: $e');
      _setError('Failed to load alarms: $e');
      _setLoading(false);
    }
  }

  bool _isKnownDeviceType(String value) {
    const known = {
      'Inverter',
      'Env-monitor',
      'Smart meter',
      'Combining manifolds',
      'Battery',
      'Charger',
      'Energy storage machine',
    };
    return known.contains(value);
  }

  /// Update period filter
  void updatePeriodFilter(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  /// Update alarm type filter
  void updateAlarmTypeFilter(String alarmType) {
    if (_selectedAlarmType != alarmType) {
      _selectedAlarmType = alarmType;
      notifyListeners();
    }
  }

  /// Update device filter
  void updateDeviceFilter(String device) {
    if (_selectedDevice != device) {
      _selectedDevice = device;
      notifyListeners();
    }
  }

  /// Update status filter
  void updateStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  /// Get filtered alarm items based on current filters (client-side fallback)
  List<Warning> getFilteredAlarmItems() {
    Iterable<Warning> items = _warnings;

    // Alarm type filter
    if (_selectedAlarmType != 'All Type') {
      items = items.where((w) {
        switch (_selectedAlarmType.toUpperCase()) {
          case 'WARNING':
            return w.level == 0;
          case 'ERROR':
            return w.level == 1;
          case 'FAULT':
            return w.level == 2;
          default:
            return true;
        }
      });
    }

    // Status filter
    if (_selectedStatus != 'All Status') {
      final wantHandled = _selectedStatus == 'Processed';
      items = items.where((w) => w.handle == wantHandled);
    }

    // Device filter (matches SN, PN, or device type string)
    if (_selectedDevice != 'All Devices') {
      final sel = _selectedDevice.trim();
      items = items.where((w) {
        return w.sn == sel || w.pn == sel || w.deviceType == sel;
      });
    }

    // Period filter fallback (if server didn’t filter)
    if (_selectedPeriod != 'Week') {
      final now = DateTime.now();
      DateTime start;
      DateTime end;
      switch (_selectedPeriod) {
        case 'Month':
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Year':
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        default:
          start = DateTime.fromMillisecondsSinceEpoch(0);
          end = DateTime.now();
      }
      items = items.where((w) => !w.gts.isBefore(start) && !w.gts.isAfter(end));
    }

    return items.toList();
  }

  /// Mark an alarm as processed
  Future<bool> markAsProcessed(String alarmId, bool isWarning) async {
    try {
      bool success;
      if (isWarning) {
        success = await _alarmRepository.acknowledgeWarning(alarmId);
      } else {
        success = await _alarmRepository.acknowledgeAlarm(alarmId);
      }

      if (success) {
        // Update local state
        if (isWarning) {
          final warningIndex = _warnings.indexWhere((w) => w.id == alarmId);
          if (warningIndex != -1) {
            _warnings[warningIndex] = Warning(
              id: _warnings[warningIndex].id,
              sn: _warnings[warningIndex].sn,
              pn: _warnings[warningIndex].pn,
              devcode: _warnings[warningIndex].devcode,
              desc: _warnings[warningIndex].desc,
              level: _warnings[warningIndex].level,
              code: _warnings[warningIndex].code,
              gts: _warnings[warningIndex].gts,
              handle: true, // Mark as processed
            );
          }
        } else {
          final alarmIndex = _alarms.indexWhere((a) => a.id == alarmId);
          if (alarmIndex != -1) {
            _alarms[alarmIndex] = Alarm(
              id: _alarms[alarmIndex].id,
              deviceId: _alarms[alarmIndex].deviceId,
              plantId: _alarms[alarmIndex].plantId,
              type: _alarms[alarmIndex].type,
              severity: _alarms[alarmIndex].severity,
              message: _alarms[alarmIndex].message,
              timestamp: _alarms[alarmIndex].timestamp,
              isActive: false, // Mark as processed
              parameters: _alarms[alarmIndex].parameters,
            );
          }
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('AlarmViewModel: Error marking alarm as processed: $e');
      return false;
    }
  }

  /// Delete an alarm
  Future<bool> deleteAlarm(String alarmId, bool isWarning) async {
    try {
      // For now, just remove from local state since we don't have a delete endpoint
      if (isWarning) {
        _warnings.removeWhere((w) => w.id == alarmId);
      } else {
        _alarms.removeWhere((a) => a.id == alarmId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('AlarmViewModel: Error deleting alarm: $e');
      return false;
    }
  }

  /// Refresh alarms
  Future<void> refresh(String plantId) async {
    await loadAlarms(plantId);
  }

  /// Reset all filters
  void resetFilters() {
    _selectedPeriod = 'Week';
    _selectedAlarmType = 'All Type';
    _selectedDevice = 'All Devices';
    _selectedStatus = 'All Status';
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> acknowledgeAlarm(String alarmId) async {
    try {
      bool success = await _alarmRepository.acknowledgeAlarm(alarmId);

      if (success) {
        // Update local state - find and update the alarm
        final alarmIndex = _alarms.indexWhere((a) => a.id == alarmId);
        if (alarmIndex != -1) {
          final alarm = _alarms[alarmIndex];
          _alarms[alarmIndex] = Alarm(
            id: alarm.id,
            deviceId: alarm.deviceId,
            plantId: alarm.plantId,
            type: alarm.type,
            severity: alarm.severity,
            message: alarm.message,
            timestamp: alarm.timestamp,
            isActive: false, // Mark as acknowledged
            parameters: alarm.parameters,
          );
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to acknowledge alarm: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
