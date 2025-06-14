import 'package:dio/dio.dart';
import '../../models/power_station/power_station_query_response_model.dart';
import '../../../core/network/api_client.dart';

class PowerStationRepository {
  final ApiClient _apiClient;

  PowerStationRepository(this._apiClient);

  Future<PowerStationQueryResponse> getPowerStationInfo(
      String stationId) async {
    try {
      final response =
          await _apiClient.get('/power-station/$stationId') as Response;
      return PowerStationQueryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get power station info: ${e.message}');
    }
  }

  Future<List<PowerStationQueryResponse>> getAllPowerStations() async {
    try {
      final response = await _apiClient.get('/power-stations') as Response;
      return (response.data as List)
          .map((station) => PowerStationQueryResponse.fromJson(station))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to get all power stations: ${e.message}');
    }
  }

  Future<PowerStationStatus> getPowerStationStatus(String stationId) async {
    try {
      final response =
          await _apiClient.get('/power-station/$stationId/status') as Response;
      return PowerStationStatus.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get power station status: ${e.message}');
    }
  }

  Future<List<PowerStationDevice>> getPowerStationDevices(
      String stationId) async {
    try {
      final response =
          await _apiClient.get('/power-station/$stationId/devices') as Response;
      return (response.data as List)
          .map((device) => PowerStationDevice.fromJson(device))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to get power station devices: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getPowerStationMetrics(String stationId) async {
    try {
      final response =
          await _apiClient.get('/power-station/$stationId/metrics') as Response;
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get power station metrics: ${e.message}');
    }
  }
}
