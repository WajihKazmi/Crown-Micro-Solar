import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_exception.dart';
import 'package:crown_micro_solar/core/models/api_response.dart';

// abstract class BaseRepository<T> {
//   Future<T> get(String id);
//   Future<List<T>> getAll();
//   Future<T> create(T data);
//   Future<T> update(String id, T data);
//   Future<void> delete(String id);
// }

abstract class BaseLocalRepository<T> {
  Future<T?> get(String id);
  Future<List<T>> getAll();
  Future<void> save(T data);
  Future<void> saveAll(List<T> data);
  Future<void> delete(String id);
  Future<void> deleteAll();
}

abstract class BaseRepository {
  final ApiClient _apiClient;

  BaseRepository(this._apiClient);

  Future<T> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _apiClient.get(endpoint);
      final data = json.decode(response.body);
      return ApiResponse<T>.fromJson(data, fromJson).data!;
    } catch (e) {
      throw ApiException(message: 'Failed to perform GET request: $e');
    }
  }

  Future<T> post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _apiClient.post(endpoint, body: body);
      final data = json.decode(response.body);
      return ApiResponse<T>.fromJson(data, fromJson).data!;
    } catch (e) {
      throw ApiException(message: 'Failed to perform POST request: $e');
    }
  }

  Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _apiClient.get(endpoint);
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> items = data['data'];
        return items.map((item) => fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      throw ApiException(message: 'Failed to perform GET request: $e');
    }
  }
}
