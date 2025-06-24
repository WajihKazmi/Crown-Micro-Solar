import 'package:dio/dio.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
      },
    );
    
    // Add logging interceptor to see what URLs are being called
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('API Request: ${options.method} ${options.uri}');
        print('API Request Headers: ${options.headers}');
        print('API Request Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        print('API Error URL: ${error.requestOptions.uri}');
        handler.next(error);
      },
    ));
  }

  // Generic GET request
  Future<Response> get(String url, {Options? options}) async {
    try {
      final response = await _dio.get(
        url,
        options: options,
      );
      return response;
    } catch (e) {
      print('GET request failed: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<Response> post(String url, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: options,
      );
      return response;
    } catch (e) {
      print('POST request failed: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      print('PUT request failed: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during PUT request: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      print('DELETE request failed: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during DELETE request: $e');
      rethrow;
    }
  }

  // Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
} 