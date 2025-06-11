import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:crown_micro_solar/api/api_client.dart';
import 'package:crown_micro_solar/api/api_endpoints.dart';
import 'package:crown_micro_solar/models/auth/auth_response.dart';
import 'package:crown_micro_solar/models/plant/plant_list_response.dart';
import 'package:crown_micro_solar/models/device/device_list_response.dart';
import 'package:crown_micro_solar/models/energy/energy_data_response.dart';

class ApiService {
  final ApiClient _client = ApiClient();
  
  String _getSign(String action, String secret, String token) {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final signString = salt + secret + token + action;
    return sha1.convert(utf8.encode(signString)).toString();
  }

  Future<AuthResponse> login(String username, String password) async {
    final action = ApiEndpoints.login;
    final sign = _getSign(action, password, username);
    final response = await _client.get('$sign$action&usr=$username&pwd=$password');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<AuthResponse> register(String username, String password, String email) async {
    final action = ApiEndpoints.register;
    final sign = _getSign(action, password, username);
    final response = await _client.get('$sign$action&usr=$username&pwd=$password&email=$email');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<PlantListResponse> getPlants() async {
    final action = ApiEndpoints.getPlants;
    final response = await _client.get(action);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PlantListResponse.fromJson(data);
    } else {
      throw Exception('Failed to get plants');
    }
  }

  Future<DeviceListResponse> getDevices(String plantId) async {
    final action = ApiEndpoints.getDevices;
    final response = await _client.get('$action&plantId=$plantId');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DeviceListResponse.fromJson(data);
    } else {
      throw Exception('Failed to get devices');
    }
  }

  Future<EnergyDataResponse> getDailyEnergy(String deviceId, String date) async {
    final action = ApiEndpoints.getDailyGeneration;
    final response = await _client.get('$action&deviceId=$deviceId&date=$date');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return EnergyDataResponse.fromJson(data);
    } else {
      throw Exception('Failed to get daily energy data');
    }
  }
} 