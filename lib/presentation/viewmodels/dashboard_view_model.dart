import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/alarm_repository.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';

class DashboardViewModel extends ChangeNotifier {
  late final PlantRepository _plantRepository;
  late final DeviceRepository _deviceRepository;
  late final AlarmRepository _alarmRepository;

  bool _isLoading = false;
  String? _error;
  int _totalPlants = 0;
  int _totalDevices = 0;
  int _totalAlarms = 0;

  DashboardViewModel() {
    _plantRepository = getIt<PlantRepository>();
    _deviceRepository = getIt<DeviceRepository>();
    _alarmRepository = getIt<AlarmRepository>();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalPlants => _totalPlants;
  int get totalDevices => _totalDevices;
  int get totalAlarms => _totalAlarms;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load plants first
      final plants = await _plantRepository.getPlants();
      _totalPlants = plants.length;

      // Aggregate device and alarm counts from all plants
      int deviceCount = 0;
      int alarmCount = 0;

      for (final plant in plants) {
        try {
          // Get devices for this plant
          final devices = await _deviceRepository.getDevices(plant.id);
          deviceCount += devices.length;

          // Get alarms for this plant
          final alarms = await _alarmRepository.getAlarms(plant.id);
          alarmCount += alarms.length;
        } catch (e) {
          // Continue with other plants if one fails
          print('Error loading data for plant ${plant.id}: $e');
        }
      }

      _totalDevices = deviceCount;
      _totalAlarms = alarmCount;

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
