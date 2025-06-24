import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/core/network/api_service.dart';
import 'package:crown_micro_solar/presentation/models/auth/auth_response_model.dart';
import 'package:crypto/crypto.dart';
import '../models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class AuthRepository {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'UserID';
  static const String _secretKey = 'Secret';
  static const String _usernameKey = 'Username';
  static const String _passwordKey = 'pass';
  static const String _loggedInKey = 'loggedin';
  static const String _isInstallerKey = 'isInstaller';
  static const String _agentsListKey = 'Agentslist';

  // Default values for DESS Monitor API
  static const String _defaultSalt = "12345678";
  static const String _defaultSecret = "e216fe6d765ebbd05393ba598c8d0ac20b4d2122";
  static const String _defaultToken = "4f07ebae2a2cb357608bb1c920924f7dd50536b00c09fb9d973441777ac66b4b";

  AuthRepository(this._apiService, this._prefs);

  String _generateSign(String salt, String secret, String token, String action) {
    final data = salt + secret + token + action;
    final bytes = utf8.encode(data);
    return sha1.convert(bytes).toString();
  }

  Future<AuthResponse> login(String userId, String password,
      {bool isAgent = false}) async {
    try {
      // Use Crown Micro API for all logins
      final url = 'https://apis.crown-micro.net/api/MonitoringApp/Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
      };
      final body = {
        "UserName": userId,
        "Password": password,
        "IsAgent": isAgent
      };

      print('Attempting Crown Micro login for user: $userId');
      print('Installer mode: $isAgent');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await _apiService.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      print('Crown Micro login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Token'] != null) {
          await _saveAuthData(data);
          return AuthResponse(
            isSuccess: true,
            token: data['Token'],
            secret: data['Secret'],
            userId: data['UserID'].toString(),
            agentsList: data['Agentslist'],
          );
        } else if (data['Agentslist'] != null) {
          await _prefs.setBool(_isInstallerKey, true);
          await _prefs.setString(_agentsListKey, jsonEncode(data));
          return AuthResponse(
            isSuccess: true,
            agentsList: data['Agentslist'],
          );
        }
        return AuthResponse(
          isSuccess: false,
          description: 'User not found',
        );
      }
      return AuthResponse(
        isSuccess: false,
        description: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      print('Login error: $e');
      return AuthResponse(
        isSuccess: false,
        description: 'Network error: $e',
      );
    }
  }

  Future<AuthResponse> loginAgent(String username, String password) async {
    try {
      final url = 'https://apis.crown-micro.net/api/MonitoringApp/Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
      };
      final body = {
        "UserName": username,
        "Password": password,
      };

      print('Attempting Crown Micro agent login for user: $username');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await _apiService.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      print('Crown Micro agent login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Token'] != null) {
          await _saveAuthData(data);
          return AuthResponse(
            isSuccess: true,
            token: data['Token'],
            secret: data['Secret'],
            userId: data['UserID'].toString(),
          );
        }
        return AuthResponse(
          isSuccess: false,
          description: 'User not found',
        );
      }
      return AuthResponse(
        isSuccess: false,
        description: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      print('Agent login error: $e');
      return AuthResponse(
        isSuccess: false,
        description: 'Network error: $e',
      );
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    if (data['Token'] != null) {
      await _prefs.setString(_tokenKey, data['Token']);
    }
    if (data['UserID'] != null) {
      await _prefs.setString(_userIdKey, data['UserID'].toString());
    }
    if (data['Secret'] != null) {
      await _prefs.setString(_secretKey, data['Secret']);
    }
    await _prefs.setBool(_loggedInKey, true);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return {
      'username': _prefs.getString(_usernameKey),
      'password': _prefs.getString(_passwordKey),
    };
  }

  Future<void> saveCredentials(String username, String password) async {
    await _prefs.setString(_usernameKey, username);
    await _prefs.setString(_passwordKey, password);
  }

  Future<void> clearCredentials() async {
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_passwordKey);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> logout() async {
    print('AuthRepository: Starting logout...');
    await _prefs.remove(_tokenKey);
    print('AuthRepository: Token removed');
    await _prefs.remove(_userIdKey);
    print('AuthRepository: UserID removed');
    await _prefs.remove(_secretKey);
    print('AuthRepository: Secret removed');
    await _prefs.remove(_loggedInKey);
    print('AuthRepository: LoggedIn flag removed');
    await _prefs.remove(_isInstallerKey);
    print('AuthRepository: Installer flag removed');
    await _prefs.remove(_agentsListKey);
    print('AuthRepository: Agents list removed');
    _apiService.clearAuthToken();
    print('AuthRepository: API service auth token cleared');
    print('AuthRepository: Logout completed');
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  String? getSecret() {
    return _prefs.getString(_secretKey);
  }

  bool getIsInstaller() {
    return _prefs.getBool(_isInstallerKey) ?? false;
  }

  List<dynamic>? getAgentsList() {
    final agentsListString = _prefs.getString(_agentsListKey);
    if (agentsListString != null) {
      try {
        final data = jsonDecode(agentsListString);
        return data['Agentslist'] as List<dynamic>?;
      } catch (e) {
        print('Error parsing agents list: $e');
        return null;
      }
    }
    return null;
  }
}
