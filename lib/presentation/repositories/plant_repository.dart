import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

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

    if (token.isEmpty || secret.isEmpty) {
      print('PlantRepository: Token or Secret is empty. Login required.');
      return [];
    }

    final action =
        '&action=webQueryPlants&orderBy=ascPlantName&page=0&pagesize=100';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      final response = await _apiClient.signedPost(url);
      print('Plant list raw response: \n${response.body}');

      if (response.body.isEmpty) {
        print('PlantRepository: Empty response from plant list API');
        return [];
      }

      Map<String, dynamic> dataJson = json.decode(response.body);

      if (dataJson['err'] != 0) {
        print('PlantRepository: API error: ${dataJson['desc']}');
        return [];
      }

      if (dataJson['dat'] != null && dataJson['dat']['plant'] != null) {
        final List<dynamic> plantsJson = dataJson['dat']['plant'];
        final plants = plantsJson.map((json) => Plant.fromJson(json)).toList();

        // Debug each plant to ensure IDs are present
        for (final plant in plants) {
          print('PlantRepository: Plant ID: ${plant.id}, Name: ${plant.name}');
        }

        return plants;
      }
      return [];
    } catch (e) {
      print('PlantRepository: Exception in getPlants: $e');
      return [];
    }
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

  // Legacy DESS API: delete a plant
  Future<bool> deletePlant(String plantId) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    if (token.isEmpty || secret.isEmpty) return false;

    final package = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final postaction =
        '&source=1&app_id=${package.packageName}&app_version=${package.version}&app_client=$platform';
    final action = '&action=delPlant&plantid=$plantId';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    try {
      final resp = await http.post(Uri.parse(url));
      if (resp.statusCode != 200) return false;
      final Map<String, dynamic> jsonBody = json.decode(resp.body);
      return (jsonBody['err'] == 0);
    } catch (e) {
      print('PlantRepository.deletePlant error: $e');
      return false;
    }
  }

  // Legacy DESS API: edit plant name and metadata (minimal: rename)
  Future<bool> editPlant({
    required Plant plant,
    String? newName,
  }) async {
    // Build query parameters similar to EDITPS in legacy app
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    if (token.isEmpty || secret.isEmpty) return false;

    final package = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    // Fill required fields with existing plant data when possible
    final qp = <String, String>{
      'action': 'editPlant',
      'plantid': plant.id,
      'name': newName ?? plant.name,
      'address.country': plant.country ?? '',
      'address.province': plant.province ?? '',
      'address.city': plant.city ?? '',
      'address.county': plant.district ?? '',
      'address.lon': (plant.longitude ?? 0).toString(),
      'address.lat': (plant.latitude ?? 0).toString(),
      'address.timezone': plant.timezone ?? '',
      'address.town': plant.town ?? '',
      'address.village': plant.village ?? '',
      'address.address': plant.address ?? '',
      'profit.unitProfit': '0',
      'profit.currency': 'USD',
      'profit.currencyCountry': plant.country ?? '',
      'profit.coal': '0',
      'profit.co2': '0',
      'profit.so2': '0',
      'nominalPower': (plant.capacity).toString(),
      'energyYearEstimate': (plant.plannedPower ?? 0).toString(),
      'designCompany': plant.company ?? '',
      'install': plant.establishmentDate ?? DateTime.now().toIso8601String(),
      'source': '1',
      'app_id': package.packageName,
      'app_version': package.version,
      'app_client': platform,
    };

    final action = '&' + Uri(queryParameters: qp).query;
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final base = Uri.parse('http://api.dessmonitor.com/public/');
    final fullParams = {'sign': sign, 'salt': salt, 'token': token, ...qp};
    final uri = base.replace(queryParameters: fullParams);
    try {
      final resp = await http.post(uri);
      if (resp.statusCode != 200) return false;
      final Map<String, dynamic> jsonBody = json.decode(resp.body);
      return (jsonBody['err'] == 0);
    } catch (e) {
      print('PlantRepository.editPlant error: $e');
      return false;
    }
  }

  /// Get total current output power across all power stations
  /// Matches old app's CurrentOuputPowerof_ALLPSQuery()
  /// API: action=queryPlantsActiveOuputPowerCurrent
  /// Returns: double (current power in Watts)
  Future<double> getTotalCurrentPower() async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    if (token.isEmpty || secret.isEmpty) {
      print(
          'PlantRepository: Token or Secret is empty for getTotalCurrentPower');
      return 0.0;
    }

    final package = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    const action = '&action=queryPlantsActiveOuputPowerCurrent';
    final postaction =
        '&source=1&app_id=${package.packageName}&app_version=${package.version}&app_client=$platform';

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      final response = await http.post(Uri.parse(url));
      print('getTotalCurrentPower response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          final outputPower = jsonResponse['dat']['outputPower'];
          return double.tryParse(outputPower.toString()) ?? 0.0;
        } else {
          print('getTotalCurrentPower API error: ${jsonResponse['desc']}');
        }
      }
    } catch (e) {
      print('PlantRepository: Exception in getTotalCurrentPower: $e');
    }
    return 0.0;
  }

  /// Get total installed capacity (nominal power) across all power stations
  /// Matches old app's InstalledCapacity_ALLPSQuery()
  /// API: action=queryPlantsNominalPower
  /// Returns: double (installed capacity in kW)
  Future<double> getTotalInstalledCapacity() async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    if (token.isEmpty || secret.isEmpty) {
      print(
          'PlantRepository: Token or Secret is empty for getTotalInstalledCapacity');
      return 0.0;
    }

    final package = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    const action = '&action=queryPlantsNominalPower';
    final postaction =
        '&source=1&app_id=${package.packageName}&app_version=${package.version}&app_client=$platform';

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      final response = await http.post(Uri.parse(url));
      print('getTotalInstalledCapacity response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          final nominalPower = jsonResponse['dat']['nominalPower'];
          return double.tryParse(nominalPower.toString()) ?? 0.0;
        } else {
          print('getTotalInstalledCapacity API error: ${jsonResponse['desc']}');
        }
      }
    } catch (e) {
      print('PlantRepository: Exception in getTotalInstalledCapacity: $e');
    }
    return 0.0;
  }
}
