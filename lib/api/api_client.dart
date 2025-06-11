import 'package:http/http.dart' as http;
import 'package:crown_micro_solar/api/api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _token;
  String? _secret;

  void setCredentials(String token, String secret) {
    _token = token;
    _secret = secret;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await _client.get(uri);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await _client.post(uri, body: body);
  }

  void dispose() {
    _client.close();
  }
} 