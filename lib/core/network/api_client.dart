import 'package:http/http.dart' as http;
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _token;
  String? _secret;

  // Public getters for accessing private members
  String? get token => _token;
  String? get secret => _secret;
  http.Client get client => _client;

  void setCredentials(String token, String secret) {
    _token = token;
    _secret = secret;
  }

  // Sync credentials from SharedPreferences
  Future<void> syncCredentialsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _secret = prefs.getString('Secret');
  }

  // Get token with fallback to SharedPreferences
  Future<String?> getToken() async {
    if (_token == null) {
      await syncCredentialsFromStorage();
    }
    return _token;
  }

  // Get secret with fallback to SharedPreferences
  Future<String?> getSecret() async {
    if (_secret == null) {
      await syncCredentialsFromStorage();
    }
    return _secret;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await _client.get(uri);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await _client.post(uri, body: body);
  }

  // Method to make signed POST requests
  Future<http.Response> signedPost(String url, {Map<String, dynamic>? body}) async {
    return await _client.post(Uri.parse(url), 
      headers: {'Content-Type': 'application/json'},
      body: body
    );
  }

  void dispose() {
    _client.close();
  }
} 