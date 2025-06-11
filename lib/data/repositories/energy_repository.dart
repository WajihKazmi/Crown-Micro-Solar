import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/data/models/energy/energy_data_model.dart';

class EnergyRepository {
  final ApiClient _apiClient;

  EnergyRepository(this._apiClient);

  Future<EnergySummary> getDailyEnergy(String plantId, String date) async {
    final response = await _apiClient.get('${ApiEndpoints.queryPlantActiveOuputPowerOneDay}&plantid=$plantId&date=$date');
    final data = json.decode(response.body);
    if (data['dat'] != null) {
      return EnergySummary.fromJson(data['dat']);
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
      return EnergySummary.fromJson(data['data']);
    }
    throw Exception('Failed to get yearly energy data');
  }

  Future<List<EnergyData>> getRealTimeData(String deviceId) async {
    final response = await _apiClient.get('${ApiEndpoints.getDeviceData}&deviceId=$deviceId');
    final data = json.decode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> energyDataJson = data['data'];
      return energyDataJson.map((json) => EnergyData.fromJson(json)).toList();
    }
    return [];
  }

  Future<EnergySummary> getProfitStatistic(String date) async {
    final response = await _apiClient.get('${ApiEndpoints.queryPlantsProfitStatisticOneDay}&date=$date');
    final data = json.decode(response.body);
    if (data['dat'] != null) {
      return EnergySummary.fromJson(data['dat']);
    }
    throw Exception('Failed to get profit statistic');
  }
} 