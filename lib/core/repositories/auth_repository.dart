import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<LoginResponse> login(String username, String password) async {
    try {
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final action = ApiEndpoints.login;
      final postAction = "&usr=$username&pwd=$password";

      // Get stored secret if available
      final prefs = await SharedPreferences.getInstance();
      final secret = prefs.getString('Secret') ?? '';

      // Create sign string
      final signString = salt + secret + action + postAction;
      final sign = sha1.convert(signString.codeUnits).toString();

      // Construct URL
      final url = '${ApiEndpoints.baseUrl}$sign&salt=$salt$action$postAction';

      // Make API call
      final response = await _apiService.post(url);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        if (loginResponse.err == 0 && loginResponse.dat != null) {
          // Store token and secret
          await prefs.setString('token', loginResponse.dat!.token);
          await prefs.setString('Secret', loginResponse.dat!.secret);
        }

        return loginResponse;
      } else {
        throw Exception('Failed to login');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('Secret');
  }
}
