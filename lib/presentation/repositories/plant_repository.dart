import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlantRepository {
  final ApiClient _apiClient;

  PlantRepository(this._apiClient);

  Future<List<Plant>> getPlants() async {
    // Parameters as in api_test.dart
    const salt = '12345678';
    // Fetch credentials from SharedPreferences since ApiClient might not be updated
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    
    print('PlantRepository: Using token: $token');
    print('PlantRepository: Using secret: $secret');
    
    final action = '&action=webQueryPlants&orderBy=ascPlantName&page=0&pagesize=100';
    final postaction = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    final response = await _apiClient.signedPost(url);
    print('Plant list raw response: \n${response.body}');
    if (response.body.isEmpty) {
      throw Exception('Empty response from plant list API');
    }
    Map<String, dynamic> dataJson;
    try {
      dataJson = json.decode(response.body);
    } catch (e) {
      throw Exception('Malformed JSON from plant list API: $e');
    }
    if (dataJson['dat'] != null && dataJson['dat']['plant'] != null) {
      final List<dynamic> plantsJson = dataJson['dat']['plant'];
      return plantsJson.map((json) => Plant.fromJson(json)).toList();
    }
    return [];
  }

  Future<Plant> getPlantDetails(String plantId) async {
    // Since we already have the plant data from getPlants(), 
    // we can find the specific plant from the list
    final plants = await getPlants();
    final plant = plants.firstWhere(
      (plant) => plant.id == plantId,
      orElse: () => throw Exception('Plant not found: $plantId'),
    );
    return plant;
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