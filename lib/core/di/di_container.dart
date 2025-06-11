import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/device/device_data_repository.dart';
import '../../data/repositories/power_station/power_station_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register API Client
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // Register Repositories
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<DeviceDataRepository>(
    () => DeviceDataRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PowerStationRepository>(
    () => PowerStationRepository(getIt<ApiClient>()),
  );
} 