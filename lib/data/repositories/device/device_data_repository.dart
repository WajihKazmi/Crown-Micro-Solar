import 'package:dio/dio.dart';
import '../../models/device/device_data_one_day_query_model.dart';
import '../../../core/network/api_client.dart';

class DeviceDataRepository {
  final ApiClient _apiClient;

  DeviceDataRepository(this._apiClient);

  Future<DeviceDataOneDayQuery> getDeviceDataForDay(String deviceId, DateTime date) async {
    try {
      final response = await _apiClient.get(
        '/device/$deviceId/data',
        queryParameters: {
          'date': date.toIso8601String(),
        },
      );
      return DeviceDataOneDayQuery.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get device data: ${e.message}');
    }
  }

  Future<List<DeviceDataPoint>> getDeviceDataRange(
    String deviceId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        '/device/$deviceId/data/range',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return (response.data as List)
          .map((point) => DeviceDataPoint.fromJson(point))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to get device data range: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getDeviceMetrics(String deviceId) async {
    try {
      final response = await _apiClient.get('/device/$deviceId/metrics');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get device metrics: ${e.message}');
    }
  }
} 