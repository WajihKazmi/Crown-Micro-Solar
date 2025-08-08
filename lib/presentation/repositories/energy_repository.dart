import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/energy/energy_data_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnergyRepository {
  final ApiClient _apiClient;

  EnergyRepository(this._apiClient);

  Future<EnergySummary> getDailyEnergy(String plantId, String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryPlantActiveOuputPowerOneDay&plantid=$plantId&date=$date';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      print('Daily energy data: ${dataJson['dat']}');
      return EnergySummary.fromJson(dataJson['dat']);
    }
    throw Exception('Failed to get daily energy data');
  }

  Future<EnergySummary> getMonthlyEnergy(String deviceId, String year, String month) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.getMonthlyGeneration}&deviceId=$deviceId&year=$year&month=$month',
    );
    final data = json.decode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      return EnergySummary.fromJson(data['data']);
    }
    throw Exception('Failed to get monthly energy data');
  }

  Future<EnergySummary> getYearlyEnergy(String deviceId, String year) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.getYearlyGeneration}&deviceId=$deviceId&year=$year',
    );
    final data = json.decode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      print('Yearly energy data: ${data['data']}');
      return EnergySummary.fromJson(data['data']);
    }
    throw Exception('Failed to get yearly energy data');
  }

  Future<List<EnergyData>> getRealTimeData(String deviceId) async {
    final response = await _apiClient.get('${ApiEndpoints.getDeviceData}&deviceId=$deviceId');
    final data = json.decode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> energyDataJson = data['data'];
      print('Real-time energy data: $energyDataJson');
      return energyDataJson.map((json) => EnergyData.fromJson(json)).toList();
    }
    return [];
  }

  Future<EnergySummary> getProfitStatistic(String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    final action = '&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$date';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    
    print('EnergyRepository: Fetching profit statistics for date $date');
    final response = await _apiClient.signedPost(url);
    print('Profit statistics raw response: \n${response.body}');
    
    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      return EnergySummary.fromJson(dataJson['dat']);
    }
    throw Exception('Failed to get profit statistic');
  }
} 