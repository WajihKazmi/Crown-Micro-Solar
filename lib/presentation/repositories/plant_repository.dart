import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';

class PlantRepository {
  final ApiClient _apiClient;

  PlantRepository(this._apiClient);

  Future<List<Plant>> getPlants() async {
    final response = await _apiClient.get(ApiEndpoints.webQueryPlants);
    final data = json.decode(response.body);
    if (data['dat'] != null && data['dat']['plant'] != null) {
      final List<dynamic> plantsJson = data['dat']['plant'];
      return plantsJson.map((json) => Plant.fromJson(json)).toList();
    }
    return [];
  }

  Future<Plant> getPlantDetails(String plantId) async {
    final response = await _apiClient.get('${ApiEndpoints.getPlantDetails}&plantid=$plantId');
    final data = json.decode(response.body);
    if (data['dat'] != null) {
      return Plant.fromJson(data['dat']);
    }
    throw Exception('Failed to get plant details');
  }

  Future<bool> createPlant({
    required String name,
    required String location,
    required double capacity,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.createPowerStation,
      body: {
        'name': name,
        'location': location,
        'capacity': capacity.toString(),
      },
    );
    
    final data = json.decode(response.body);
    return data['success'] == true;
  }
} 