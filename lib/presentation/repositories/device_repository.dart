import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crown_micro_solar/presentation/models/device/device_data_one_day_query_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_key_parameter_model.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  // Main method to fetch devices and collectors for a plant (matching old app)
  Future<Map<String, dynamic>> getDevicesAndCollectors(String plantId) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    print('DeviceRepository: Fetching devices and collectors for plant $plantId');

    // 1. Fetch all devices for the plant
    final deviceAction = '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
    final deviceData = salt + secret + token + deviceAction + postaction;
    final deviceSign = sha1.convert(utf8.encode(deviceData)).toString();
    final deviceUrl = 'http://api.dessmonitor.com/public/?sign=$deviceSign&salt=$salt&token=$token$deviceAction$postaction';
    
    print('DeviceRepository: Device URL: $deviceUrl');
    final deviceResponse = await _apiClient.signedPost(deviceUrl);
    final deviceJson = json.decode(deviceResponse.body);
    print('DeviceRepository: Device response: $deviceJson');

    List<Device> devices = [];
    if (deviceJson['err'] == 0 && deviceJson['dat']?['device'] != null) {
      devices = (deviceJson['dat']['device'] as List).map((d) => Device.fromJson(d)).toList();
      print('DeviceRepository: Found ${devices.length} devices');
    } else {
      print('DeviceRepository: No devices found or error: ${deviceJson['err']} - ${deviceJson['desc']}');
    }

    // 2. Fetch all collectors for the plant
    final collectorAction = '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
    final collectorData = salt + secret + token + collectorAction + postaction;
    final collectorSign = sha1.convert(utf8.encode(collectorData)).toString();
    final collectorUrl = 'http://api.dessmonitor.com/public/?sign=$collectorSign&salt=$salt&token=$token$collectorAction$postaction';
    
    print('DeviceRepository: Collector URL: $collectorUrl');
    final collectorResponse = await _apiClient.signedPost(collectorUrl);
    final collectorJson = json.decode(collectorResponse.body);
    print('DeviceRepository: Collector response: $collectorJson');

    List<Map<String, dynamic>> collectors = [];
    if (collectorJson['err'] == 0 && collectorJson['dat']?['collector'] != null) {
      collectors = List<Map<String, dynamic>>.from(collectorJson['dat']['collector']);
      print('DeviceRepository: Found ${collectors.length} collectors');
    } else {
      print('DeviceRepository: No collectors found or error: ${collectorJson['err']} - ${collectorJson['desc']}');
    }

    // 3. For each collector, fetch subordinate devices
    Map<String, List<Device>> collectorDevices = {};
    Set<String> subordinateSNs = {};
    
    for (final collector in collectors) {
      final pn = collector['pn']?.toString() ?? '';
      if (pn.isNotEmpty) {
        final subDevices = await getDevicesForCollector(pn);
        collectorDevices[pn] = subDevices;
        subordinateSNs.addAll(subDevices.map((d) => d.sn));
        print('DeviceRepository: Collector $pn has ${subDevices.length} subordinate devices');
      }
    }

    // 4. Standalone devices = all devices not under any collector
    final standaloneDevices = devices.where((d) => !subordinateSNs.contains(d.sn)).toList();
    print('DeviceRepository: Found ${standaloneDevices.length} standalone devices');

    return {
      'standaloneDevices': standaloneDevices,
      'collectors': collectors,
      'collectorDevices': collectorDevices,
      'allDevices': devices,
    };
  }

  // Fetch subordinate devices for a collector (by PN) - matching old app
  Future<List<Device>> getDevicesForCollector(String collectorPn) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    
    final action = '&action=webQueryDeviceEs&pn=$collectorPn&page=0&pagesize=20';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    print('DeviceRepository: Fetching devices for collector $collectorPn');
    final response = await _apiClient.signedPost(url);
    final jsonData = json.decode(response.body);
    
    if (jsonData['err'] == 0 && jsonData['dat']?['device'] != null) {
      final devices = (jsonData['dat']['device'] as List).map((d) => Device.fromJson(d)).toList();
      print('DeviceRepository: Found ${devices.length} devices for collector $collectorPn');
      return devices;
    }
    
    print('DeviceRepository: No devices found for collector $collectorPn');
    return [];
  }

  // Fetch devices with specific status and device type (matching old app)
  Future<List<Device>> getDevicesWithFilters(String plantId, {String status = '0101', String deviceType = '0101'}) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    String action;
    if (status == '0101' && deviceType == '0101') {
      // All devices
      action = '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
    } else if (status == '0101' && deviceType != '0101' && deviceType != '0110') {
      // Specific device type
      action = '&action=webQueryDeviceEs&devtype=$deviceType&page=0&pagesize=100&plantid=$plantId';
    } else if (status == '0101' && deviceType == '0110') {
      // Collectors
      action = '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
    } else if (status != '0101' && deviceType == '0110') {
      // Collectors with status
      action = '&action=webQueryCollectorsEs&status=$status&page=0&pagesize=100&plantid=$plantId';
    } else {
      // Devices with status and device type
      action = '&action=webQueryDeviceEs&status=$status&page=0&pagesize=100&plantid=$plantId';
    }

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    print('DeviceRepository: Fetching devices with filters - status: $status, deviceType: $deviceType');
    final response = await _apiClient.signedPost(url);
    final jsonData = json.decode(response.body);
    
    if (jsonData['err'] == 0) {
      if (jsonData['dat']?['device'] != null) {
        final devices = (jsonData['dat']['device'] as List).map((d) => Device.fromJson(d)).toList();
        print('DeviceRepository: Found ${devices.length} devices with filters');
        return devices;
      } else if (jsonData['dat']?['collector'] != null) {
        // Convert collectors to devices for consistency
        final collectors = jsonData['dat']['collector'] as List;
        final devices = collectors.map((c) => Device.fromJson(c)).toList();
        print('DeviceRepository: Found ${devices.length} collectors with filters');
        return devices;
      }
    }
    
    print('DeviceRepository: No devices found with filters');
    return [];
  }

  // Legacy method for backward compatibility
  Future<List<Device>> getDevices(String plantId) async {
    final result = await getDevicesAndCollectors(plantId);
    return result['allDevices'] ?? [];
  }

  // Fetch real-time device data (separate call for detailed info)
  Future<Map<String, dynamic>> getDeviceRealTimeData(String pn, String sn, int devcode, int devaddr) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryDeviceCtrlField&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';
    
    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    
    if (dataJson['err'] == 0 && dataJson['dat'] != null) {
      return dataJson['dat'];
    }
    
    throw Exception('Failed to get device real-time data: ${dataJson['desc']}');
  }

  // Fetch device daily data
  Future<Map<String, dynamic>> getDeviceDailyData(String pn, String sn, int devcode, int devaddr, String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date&page=0&pagesize=200&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';
    
    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    
    if (dataJson['err'] == 0 && dataJson['dat'] != null) {
      return dataJson['dat'];
    }
    
    throw Exception('Failed to get device daily data: ${dataJson['desc']}');
  }

  // Fetch device data for one day (for device detail page)
  Future<DeviceDataOneDayQueryModel?> fetchDeviceDataOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
    int page = 0,
  }) async {
    // TODO: Implement real API call
    // This is a stub for integration
    // Use the old app's logic as reference
    // Return a dummy model for now
    return null;
  }

  // Fetch live device signal/current/voltage/flow data (for device detail page)
  Future<DeviceLiveSignalModel?> fetchDeviceLiveSignal({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
  }) async {
    // TODO: Implement real API call
    // This is a stub for integration
    // Return a dummy model for now
    return DeviceLiveSignalModel(
      inputVoltage: 230.0,
      inputCurrent: 5.0,
      outputVoltage: 220.0,
      outputCurrent: 4.8,
      inputPower: 1150.0,
      outputPower: 1056.0,
      signalStrength: 98.0,
      timestamp: DateTime.now(),
    );
  }

  // Fetch key parameter data for one day (e.g., PV_OUTPUT_POWER, current, voltage)
  Future<DeviceKeyParameterModel?> fetchDeviceKeyParameterOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String parameter,
    required String date,
  }) async {
    // TODO: Implement real API call
    // This is a stub for integration
    // Use the old app's logic as reference
    // Return a dummy model for now
    return DeviceKeyParameterModel(
      err: 0,
      desc: 'Success',
      dat: DeviceKeyParameterData(
        total: 1,
        row: [DeviceKeyParameterRow(field: ["100.0"])],
        title: [DeviceKeyParameterTitle(title: parameter, unit: "V")],
      ),
    );
  }
} 