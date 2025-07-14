import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/alarm/alarm_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmRepository {
  final ApiClient _apiClient;

  AlarmRepository(this._apiClient);

  Future<List<Alarm>> getAlarms(String plantId) async {
    // For now, return warnings as alarms since the API returns warnings
    return await getWarnings(plantId).then((warnings) => 
      warnings.map((warning) => Alarm(
        id: warning.id,
        deviceId: warning.deviceId,
        plantId: warning.plantId,
        type: warning.type,
        severity: 'warning',
        message: warning.message,
        timestamp: warning.timestamp,
        isActive: warning.isActive,
        parameters: warning.parameters,
      )).toList()
    );
  }

  Future<List<Warning>> getWarnings(String plantId) async {
    // Parameters as in api_test.dart
    const salt = '12345678';
    // Fetch credentials from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    print('AlarmRepository: Using token: $token');
    print('AlarmRepository: Using secret: $secret');
    
    final action = '&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&plantid=$plantId';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    print('AlarmRepository: Fetching warnings for plant $plantId');
    final response = await _apiClient.signedPost(url);
    print('Warning list raw response: \n${response.body}');
    
    if (response.body.isEmpty) {
      throw Exception('Empty response from warning list API');
    }
    
    Map<String, dynamic> dataJson;
    try {
      dataJson = json.decode(response.body);
    } catch (e) {
      throw Exception('Malformed JSON from warning list API: $e');
    }
    
    if (dataJson['dat'] != null && dataJson['dat']['warning'] != null) {
      final List<dynamic> warningsJson = dataJson['dat']['warning'];
      return warningsJson.map((json) => Warning.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> acknowledgeAlarm(String alarmId) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.getAlarms}&alarmId=$alarmId',
      body: {'action': 'acknowledge'},
    );
    
    final data = json.decode(response.body);
    return data['success'] == true;
  }

  Future<bool> acknowledgeWarning(String warningId) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.getWarnings}&warningId=$warningId',
      body: {'action': 'acknowledge'},
    );
    
    final data = json.decode(response.body);
    return data['success'] == true;
  }
} 