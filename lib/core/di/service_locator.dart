import 'package:get_it/get_it.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/energy_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  try {
    // Reset all registrations
    await getIt.reset();
    
    // Register ViewModels
    getIt.registerFactory(() => AuthViewModel());
    getIt.registerFactory(() => PlantViewModel());
    getIt.registerFactory(() => DeviceViewModel());
    getIt.registerFactory(() => EnergyViewModel());
    getIt.registerFactory(() => AlarmViewModel());

  } catch (e) {
    print('Failed to setup service locator: $e');
    rethrow;
  }
} 