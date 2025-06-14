import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  Future<List<Device>> getDevices(String plantId) async {
    final response = await _apiClient.get('${ApiEndpoints.webQueryDeviceEs}&plantid=$plantId');
    final data = json.decode(response.body);
    if (data['dat'] != null && data['dat']['device'] != null) {
      final List<dynamic> devicesJson = data['dat']['device'];
      return devicesJson.map((json) => Device.fromJson(json)).toList();
    }
    return [];
  }

  Future<Device> getDeviceStatus(String pn, String sn, int devcode, int devaddr) async {
    final response = await _apiClient.get('${ApiEndpoints.queryDeviceCtrlField}&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US');
    final data = json.decode(response.body);
    if (data['dat'] != null) {
      return Device.fromJson(data['dat']);
    }
    throw Exception('Failed to get device status');
  }

  Future<Map<String, dynamic>> getDeviceData(String pn, String sn, int devcode, int devaddr, String date) async {
    final response = await _apiClient.get('${ApiEndpoints.queryDeviceDataOneDayPaging}&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date&page=0&pagesize=200&i18n=en_US');
    final data = json.decode(response.body);
    if (data['dat'] != null) {
      return data['dat'];
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