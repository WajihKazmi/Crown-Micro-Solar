import 'package:get_it/get_it.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/energy_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/dashboard_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_info_view_model.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/presentation/models/device/device_data_one_day_query_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_key_parameter_model.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  try {
    // Reset all registrations
    await getIt.reset();
    
    // Register core services
    getIt.registerLazySingleton(() => ApiClient());
    
    // Register repositories
    getIt.registerLazySingleton(() => PlantRepository(getIt<ApiClient>()));
    getIt.registerLazySingleton(() => DeviceRepository(getIt<ApiClient>()));
    // Register models for device detail
    getIt.registerFactory(() => DeviceDataOneDayQueryModel());
    getIt.registerFactory(() => DeviceLiveSignalModel());
    getIt.registerFactory(() => DeviceKeyParameterModel());
    
    // Register ViewModels (AuthViewModel is handled by Provider in main.dart)
    getIt.registerFactory(() => PlantViewModel(getIt<PlantRepository>()));
    getIt.registerFactory(() => DeviceViewModel(getIt<DeviceRepository>()));
    getIt.registerFactory(() => EnergyViewModel());
    getIt.registerFactory(() => AlarmViewModel());
    getIt.registerFactory(() => DashboardViewModel());
    getIt.registerFactory(() => PlantInfoViewModel());
    
    // Register RealtimeDataService as singleton
    getIt.registerLazySingleton(() => RealtimeDataService(
      getIt<ApiClient>(),
      getIt<DeviceRepository>(),
      getIt<PlantRepository>(),
    ));

  } catch (e) {
    print('Failed to setup service locator: $e');
    rethrow;
  }
} 