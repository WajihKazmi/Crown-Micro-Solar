import 'package:get_it/get_it.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/data/repositories/auth_repository.dart';
import 'package:crown_micro_solar/data/repositories/plant_repository.dart';
import 'package:crown_micro_solar/data/repositories/device_repository.dart';
import 'package:crown_micro_solar/data/repositories/energy_repository.dart';
import 'package:crown_micro_solar/data/repositories/alarm_repository.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/energy_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // Core
  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient());

  // Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(serviceLocator<ApiClient>()),
  );
  serviceLocator.registerLazySingleton<PlantRepository>(
    () => PlantRepository(serviceLocator<ApiClient>()),
  );
  serviceLocator.registerLazySingleton<DeviceRepository>(
    () => DeviceRepository(serviceLocator<ApiClient>()),
  );
  serviceLocator.registerLazySingleton<EnergyRepository>(
    () => EnergyRepository(serviceLocator<ApiClient>()),
  );
  serviceLocator.registerLazySingleton<AlarmRepository>(
    () => AlarmRepository(serviceLocator<ApiClient>()),
  );

  // ViewModels
  serviceLocator.registerFactory<AuthViewModel>(
    () => AuthViewModel(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerFactory<PlantViewModel>(
    () => PlantViewModel(serviceLocator<PlantRepository>()),
  );
  serviceLocator.registerFactory<DeviceViewModel>(
    () => DeviceViewModel(serviceLocator<DeviceRepository>()),
  );
  serviceLocator.registerFactory<EnergyViewModel>(
    () => EnergyViewModel(serviceLocator<EnergyRepository>()),
  );
  serviceLocator.registerFactory<AlarmViewModel>(
    () => AlarmViewModel(serviceLocator<AlarmRepository>()),
  );
} 