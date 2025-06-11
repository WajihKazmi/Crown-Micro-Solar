import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/data/models/alarm/alarm_model.dart';

class AlarmRepository {
  final ApiClient _apiClient;

  AlarmRepository(this._apiClient);

  Future<List<Alarm>> getAlarms(String plantId) async {
    final response = await _apiClient.get('${ApiEndpoints.getAlarms}&plantId=$plantId');
    final data = json.decode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> alarmsJson = data['data'];
      return alarmsJson.map((json) => Alarm.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Warning>> getWarnings(String plantId) async {
    final response = await _apiClient.get('${ApiEndpoints.webQueryPlantsWarning}&plantid=$plantId');
    final data = json.decode(response.body);
    if (data['dat'] != null && data['dat']['warning'] != null) {
      final List<dynamic> warningsJson = data['dat']['warning'];
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