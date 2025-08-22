// Manual exploratory test for real-time and key parameter API calls.
// Run with: flutter test test/realtime_api_test.dart --plain-name=RealtimeAPI (or simply flutter test)
// This is NOT a golden/unit assertion test yet; it logs outputs so you can verify mapping.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart' as di;
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeAPI', () {
    setUpAll(() async {
      di.setupLocator();
      // Ensure some dummy prefs exist (replace with real values when running locally)
      final prefs = await SharedPreferences.getInstance();
      // If token/Secret already stored from login flow they will be reused.
      if (!(prefs.containsKey('token') && prefs.containsKey('Secret'))) {
        print(
            'WARNING: token/Secret missing in SharedPreferences; login first in app.');
      }
    });

    test('Fetch plant/device realtime aggregates', () async {
      final realtime = di.getIt<RealtimeDataService>();
      await realtime.start();
      // Allow some time for first update cycle (in real test you might mock timers)
      await Future.delayed(const Duration(seconds: 2));
      print('Plants loaded: ${realtime.plants.length}');
      print('Total current power: ${realtime.totalCurrentPower} kW');
      print('Total daily generation: ${realtime.totalDailyGeneration} kWh');
      if (realtime.devices.isNotEmpty) {
        final d = realtime.devices.first;
        print(
            'Sample device: pn=${d.pn} devcode=${d.devcode} currentPower=${d.currentPower}');
      }
      realtime.stop();
    });

    test('Key parameter one-day fetch (battery/grid) for first inverter',
        () async {
      final deviceRepo = di.getIt<DeviceRepository>();
      final plantRepo = di.getIt<PlantRepository>();
      final plants = await plantRepo.getPlants();
      if (plants.isEmpty) {
        print('No plants available.');
        return;
      }
      final plantId = plants.first.id;
      final devicesResult = await deviceRepo.getDevicesAndCollectors(plantId);
      final allDevices =
          (devicesResult['allDevices'] as List).whereType().toList();
      if (allDevices.isEmpty) {
        print('No devices for plant');
        return;
      }
      // Find an inverter-like device (devcode heuristic) else first
      dynamic target = allDevices.first;
      for (final d in allDevices) {
        final dc = d.devcode?.toString() ?? ''; // ignore if null
        if (dc.contains('512') || d.isInverter) {
          // 512 example devcode from earlier filtering
          target = d;
          break;
        }
      }
      print(
          'Target device pn=${target.pn} sn=${target.sn} devcode=${target.devcode}');
      final batteryParam = await deviceRepo.fetchDeviceKeyParameterOneDay(
        pn: target.pn,
        sn: target.sn,
        devcode: target.devcode,
        devaddr: target.devaddr,
        parameter: 'BATTERY_SOC',
      );
      final gridParam = await deviceRepo.fetchDeviceKeyParameterOneDay(
        pn: target.pn,
        sn: target.sn,
        devcode: target.devcode,
        devaddr: target.devaddr,
        parameter: 'GRID_POWER',
      );
      print('Battery SOC rows: ${batteryParam?.dat?.row?.length}');
      print('Grid POWER rows: ${gridParam?.dat?.row?.length}');
      if (batteryParam?.dat?.row?.isNotEmpty == true) {
        final latest = batteryParam!.dat!.row!.first.field?.first;
        print('Latest BATTERY_SOC raw: $latest');
      }
      if (gridParam?.dat?.row?.isNotEmpty == true) {
        final latest = gridParam!.dat!.row!.first.field?.first;
        print('Latest GRID_POWER raw: $latest');
      }
    });
  });
}
