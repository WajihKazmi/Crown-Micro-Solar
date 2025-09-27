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

      // Aggregate device and alarm counts from all plants in parallel
      int deviceCount = 0;
      int alarmCount = 0;

      final futures = plants.map((plant) async {
        try {
          // Fetch devices and alarms concurrently for this plant
          final res = await Future.wait([
            _deviceRepository.getDevices(plant.id),
            _alarmRepository.getAlarms(plant.id),
          ]);
          final devices = res[0] as List;
          final alarms = res[1] as List;
          deviceCount += devices.length;
          alarmCount += alarms.length;
        } catch (e) {
          print('Error loading data for plant ${plant.id}: $e');
        }
      }).toList();
      await Future.wait(futures);

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
