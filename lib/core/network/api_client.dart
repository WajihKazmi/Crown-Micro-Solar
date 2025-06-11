import 'package:http/http.dart' as http;
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/auth/auth_response_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _token;
  String? _secret;

  late Dio _authClient;
  late Dio _monitorClient;
  static const String _authBaseUrl = 'https://apis.crown-micro.net/api/MonitoringApp';
  static const String _monitorBaseUrl = 'http://api.dessmonitor.com/public';
  static const String _defaultSalt = '12345678'; // Default salt from old app

  ApiClient() {
    _authClient = Dio(BaseOptions(
      baseUrl: _authBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
      },
    ));

    _monitorClient = Dio(BaseOptions(
      baseUrl: _monitorBaseUrl,
    ));
  }

  void setCredentials(String token, String secret) {
    _token = token;
    _secret = secret;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      final response = await _client.get(uri);
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ApiException(message: 'Failed to perform GET request: $e');
    }
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      final response = await _client.post(uri, body: body);
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ApiException(message: 'Failed to perform POST request: $e');
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: 'API request failed with status code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() {
    _client.close();
  }

  // Authentication API calls
  Future<AuthResponse> login(String username, String password, {bool isAgent = false}) async {
    try {
      final response = await _authClient.post('/Login', data: {
        'Username': username,
        'Password': password,
        'IsAgent': isAgent
      });

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        if (authResponse.isSuccess && authResponse.token != null) {
          // Store credentials in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', authResponse.token!);
          await prefs.setString('Secret', authResponse.secret!);
          await prefs.setString('UserID', authResponse.userId!);
          await prefs.setBool('loggedin', true);
        }
        return authResponse;
      }
      throw Exception('Login failed');
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    try {
      final response = await _authClient.post('/Register', data: userData);
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    }
  }

  Future<bool> verifyShortCode(String email, String code) async {
    try {
      final response = await _authClient.post('/VerifyShortCode', data: {
        'Email': email,
        'ShortCode': code
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Verification failed: ${e.message}');
    }
  }

  Future<bool> pushShortCode(String email) async {
    try {
      final response = await _authClient.post('/PushShortCode', data: {
        'Email': email
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Failed to send verification code: ${e.message}');
    }
  }

  Future<bool> updatePassword(String userId, String newPassword) async {
    try {
      final response = await _authClient.post('/UpdatePassword', data: {
        'UserID': userId,
        'Password': newPassword
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Password update failed: ${e.message}');
    }
  }

  // Monitor API calls
  Future<Response> monitorRequest(String action, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    // Use default salt from old app
    final salt = _defaultSalt;

    // Create sign string exactly as in old app
    final signString = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(signString)).toString();

    // Build URL with parameters
    final queryParams = {
      'sign': sign,
      'salt': salt,
      'token': token,
      ...params
    };

    return await _monitorClient.get('', queryParameters: queryParams);
  }

  // Helper method for monitor API calls
  String generateSign(String salt, String secret, String token, String action) {
    final signString = salt + secret + token + action;
    return sha1.convert(utf8.encode(signString)).toString();
  }

  // Method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedin') ?? false;
  }

  // Method to logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedin', false);
    await prefs.remove('token');
    await prefs.remove('Secret');
    await prefs.remove('UserID');
  }
} 