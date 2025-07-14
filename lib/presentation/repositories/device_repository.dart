import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  Future<List<Device>> getDevices(String plantId) async {
    // Parameters as in api_test.dart
    const salt = '12345678';
    // Fetch credentials from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    print('DeviceRepository: Using token: $token');
    print('DeviceRepository: Using secret: $secret');
    
    final action = '&action=webQueryDeviceEs&status=0101&page=0&pagesize=100&plantid=$plantId';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    print('DeviceRepository: Fetching devices for plant $plantId');
    final response = await _apiClient.signedPost(url);
    print('Device list raw response: \n${response.body}');
    
    if (response.body.isEmpty) {
      throw Exception('Empty response from device list API');
    }
    
    Map<String, dynamic> dataJson;
    try {
      dataJson = json.decode(response.body);
    } catch (e) {
      throw Exception('Malformed JSON from device list API: $e');
    }
    
    if (dataJson['dat'] != null && dataJson['dat']['device'] != null) {
      final List<dynamic> devicesJson = dataJson['dat']['device'];
      return devicesJson.map((json) => Device.fromJson(json)).toList();
    }
    return [];
  }

  Future<Device> getDeviceStatus(String pn, String sn, int devcode, int devaddr) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryDeviceCtrlField&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://web.shinemonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';
    
    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      return Device.fromJson(dataJson['dat']);
    }
    throw Exception('Failed to get device status');
  }

  Future<Map<String, dynamic>> getDeviceData(String pn, String sn, int devcode, int devaddr, String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date&page=0&pagesize=200&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://web.shinemonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';
    
    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      return dataJson['dat'];
    }
    throw Exception('Failed to get device data');
  }

  Future<bool> updateDeviceParameters(String deviceId, Map<String, dynamic> parameters) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.getDeviceData}&deviceId=$deviceId',
      body: parameters,
    );
    
    final data = json.decode(response.body);
    return data['success'] == true;
  }
} 