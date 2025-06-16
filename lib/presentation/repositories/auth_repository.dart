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
      if (isAgent) {
        // Use Crown Micro API for installer mode
        final url = 'https://apis.crown-micro.net/api/MonitoringApp/Login';
        final headers = {
          'Content-Type': 'application/json',
          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
        };
        final body = {
          "Username": userId,
          "Password": password,
          "IsAgent": true
        };

        print('Attempting Crown Micro login for user: $userId');
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
      } else {
        // Use DESS Monitor API for regular users
        // First authenticate with username/password
        final authAction = "&action=authenticate&usr=${userId}&pwd=${password}";
        final authSign = _generateSign(_defaultSalt, _defaultSecret, _defaultToken, authAction);
        
        final authUrl = 'http://api.dessmonitor.com/public/';
        final authQueryParams = {
          'sign': authSign,
          'salt': _defaultSalt,
          'token': _defaultToken,
          'action': 'authenticate',
          'usr': userId,
          'pwd': password
        };

        final authUri = Uri.parse(authUrl).replace(queryParameters: authQueryParams);
        print('Attempting DESS Monitor authentication with URL: $authUri');

        final authResponse = await _apiService.get(
          authUri.toString(),
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );
        print('DESS Monitor authentication response: ${authResponse.data}');

        if (authResponse.statusCode == 200) {
          final authData = authResponse.data;
          if (authData['err'] != null && authData['err'] != 0) {
            return AuthResponse(
              isSuccess: false,
              description: authData['desc'] ?? 'Authentication failed',
            );
          }

          // If authentication successful, get collector info
          final collectorAction = "&action=queryCollectorInfo&pn=Q0819510312095";
          final collectorSign = _generateSign(_defaultSalt, _defaultSecret, _defaultToken, collectorAction);
          
          final collectorQueryParams = {
            'sign': collectorSign,
            'salt': _defaultSalt,
            'token': _defaultToken,
            'action': 'queryCollectorInfo',
            'pn': 'Q0819510312095'
          };

          final collectorUri = Uri.parse(authUrl).replace(queryParameters: collectorQueryParams);
          print('Querying collector info with URL: $collectorUri');

          final collectorResponse = await _apiService.get(
            collectorUri.toString(),
            options: Options(
              validateStatus: (status) => status! < 500,
            ),
          );
          print('Collector info response: ${collectorResponse.data}');

          if (collectorResponse.statusCode == 200) {
            final data = collectorResponse.data;
            if (data['err'] != null && data['err'] != 0) {
              return AuthResponse(
                isSuccess: false,
                description: data['desc'] ?? 'Failed to get collector info',
              );
            }

            final authResponse = AuthResponse.fromJson(data);
            if (authResponse.isSuccess) {
              await _saveAuthData(data);
            }
            return authResponse;
          } else {
            return AuthResponse(
              isSuccess: false,
              description: 'Failed to get collector info: ${collectorResponse.statusCode}',
            );
          }
        } else {
          return AuthResponse(
            isSuccess: false,
            description: 'Authentication failed: ${authResponse.statusCode}',
          );
        }
      }
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
        "Username": username,
        "Password": password,
      };

      print('Attempting agent login for user: $username');
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
      print('Agent login response: ${response.data}');

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
          description: 'Agent login failed',
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
    await _prefs.setString(_tokenKey, data['Token']);
    await _prefs.setString(_secretKey, data['Secret']);
    await _prefs.setString(_userIdKey, data['UserID'].toString());
    await _prefs.setBool(_loggedInKey, true);
  }

  Future<void> saveCredentials(String username, String password) async {
    await _prefs.setString(_usernameKey, username);
    await _prefs.setString(_passwordKey, password);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return {
      'username': _prefs.getString(_usernameKey),
      'password': _prefs.getString(_passwordKey),
    };
  }

  Future<void> clearCredentials() async {
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_passwordKey);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_secretKey);
    await _prefs.remove(_userIdKey);
    await _prefs.setBool(_loggedInKey, false);
  }

  String? getToken() => _prefs.getString(_tokenKey);
  String? getUserId() => _prefs.getString(_userIdKey);
  String? getSecret() => _prefs.getString(_secretKey);
  bool isInstaller() => _prefs.getBool(_isInstallerKey) ?? false;
  List<dynamic>? getAgentsList() {
    final agentsListStr = _prefs.getString(_agentsListKey);
    if (agentsListStr != null) {
      final jsonResponse = json.decode(agentsListStr);
      return jsonResponse['Agentslist'];
    }
    return null;
  }
}
