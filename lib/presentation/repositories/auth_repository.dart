import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_service.dart';
import 'package:crown_micro_solar/presentation/models/auth/auth_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';

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
  // Legacy defaults removed (unused)

  AuthRepository(this._apiService, this._prefs);

  // Legacy sign method removed (unused)

  Future<AuthResponse> login(
    String userId,
    String password, {
    bool isAgent = false,
  }) async {
    try {
      // Always clear previous auth/session state before a new login to avoid stale leakage
      await clearAllPersistedAuth();
      // Use Crown Micro API for all logins
      final url = 'https://apis.crown-micro.net/api/MonitoringApp/Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = {
        "UserName": userId,
        "Password": password,
        "IsAgent": isAgent,
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
          // Save username before saving auth data
          await _prefs.setString(_usernameKey, userId);
          await _prefs.setBool(_isInstallerKey, isAgent);
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
          return AuthResponse(isSuccess: true, agentsList: data['Agentslist']);
        }
        return AuthResponse(isSuccess: false, description: 'User not found');
      }
      return AuthResponse(
        isSuccess: false,
        description: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      print('Login error: $e');
      return AuthResponse(isSuccess: false, description: 'Network error: $e');
    }
  }

  Future<AuthResponse> loginAgent(String username, String password) async {
    try {
      // Clear previous session fully before agent login to prevent cross-account leakage
      await clearAllPersistedAuth();
      final url = 'https://apis.crown-micro.net/api/MonitoringApp/Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = {"UserName": username, "Password": password};

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
        return AuthResponse(isSuccess: false, description: 'User not found');
      }
      return AuthResponse(
        isSuccess: false,
        description: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      print('Agent login error: $e');
      return AuthResponse(isSuccess: false, description: 'Network error: $e');
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

    // Set a hardcoded appkey for Growatt API integration
    // This appears to be needed for alarm queries in the Growatt API
    await _prefs.setString('appkey', 'bff8a1bef5a20e8c95b4eae6a509f84b');

    // Also set username for alarm repository
    await _prefs.setString('username', _prefs.getString(_usernameKey) ?? '');

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

    // Clear device repository caches FIRST to ensure no stale data persists
    try {
      final deviceRepo = getIt<DeviceRepository>();
      await deviceRepo.clearAllCaches();
      print('AuthRepository: Device caches cleared');
    } catch (e) {
      print('AuthRepository: Error clearing device caches: $e');
    }

    // Clear realtime data service cache
    try {
      final realtimeService = getIt<RealtimeDataService>();
      realtimeService.stop(); // Stop any running timers
      realtimeService.clearAllData(); // Clear all cached data
      print('AuthRepository: Realtime service cleared');
    } catch (e) {
      print('AuthRepository: Error clearing realtime service: $e');
    }

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

  // Force-remove every auth-related key (used before new logins and externally on logout flows)
  Future<void> clearAllPersistedAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_secretKey);
    await _prefs.remove(_loggedInKey);
    await _prefs.remove(_isInstallerKey);
    await _prefs.remove(_agentsListKey);
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_passwordKey);
    await _prefs.remove('appkey');
    await _prefs.remove('username');
  }

  Future<void> clearInstallerState() async {
    await _prefs.remove(_isInstallerKey);
    await _prefs.remove(_agentsListKey);
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

  Future<bool> register({
    required String email,
    required String mobileNo,
    required String username,
    required String password,
    required String sn,
  }) async {
    try {
      final url = 'https://apis.crown-micro.net/api/MonitoringApp/Register';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = jsonEncode({
        "Email": email,
        "MobileNo": mobileNo,
        "Username": username,
        "Password": password,
        "SN": sn,
      });
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Description'] == "Success";
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}
