import 'dart:convert';
import 'package:crown_micro_solar/presentation/models/auth/auth_response_model.dart';
import 'package:crypto/crypto.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  String _getSign(String action, String secret, String token) {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final signString = salt + secret + token + action;
    return sha1.convert(utf8.encode(signString)).toString();
  }

  Future<AuthResponse> login(String username, String password) async {
    final action = ApiEndpoints.login;
    final sign = _getSign(action, password, username);
    final response =
        await _apiClient.get('$sign$action&usr=$username&pwd=$password');
    return AuthResponse.fromJson(json.decode(response.body));
  }

  Future<AuthResponse> register(
      String username, String password, String email) async {
    final action = ApiEndpoints.register;
    final sign = _getSign(action, password, username);
    final response = await _apiClient
        .get('$sign$action&usr=$username&pwd=$password&email=$email');
    return AuthResponse.fromJson(json.decode(response.body));
  }

  Future<AuthResponse> verify(String username, String code) async {
    final action = ApiEndpoints.verify;
    final response = await _apiClient.get('$action&usr=$username&code=$code');
    return AuthResponse.fromJson(json.decode(response.body));
  }
}
