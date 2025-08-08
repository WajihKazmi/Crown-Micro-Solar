// This is a modified version of the test.dart file for running with `dart run`
// It does not include Flutter dependencies and uses a simpler approach to testing the API

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

// Removed path_provider import as it depends on Flutter

/// This file contains all API calls made in the Crown Micro Solar app
/// It can be used to test and understand the API responses for better integration

class ApiTester {
  // API Constants
  static const String _apiBaseUrl = 'http://api.dessmonitor.com/public/';
  static const String _crownApiBaseUrl =
      'https://apis.crown-micro.net/api/MonitoringApp/';
  static const String _salt = '12345678';
  static const String _apiKey = 'C5BFF7F0-B4DF-475E-A331-F737424F013C';

  // Post-action params
  static const String _postAction =
      '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

  // API Client
  final Dio _dio = Dio();

  // For storing credentials
  String? _token;
  String? _secret;
  bool _isLoggedIn = false;

  // Constructor
  ApiTester();

  // Helper to generate signature for DESS Monitor API
  String _generateSign(String salt, String secret, String token, String action,
      [String? postaction]) {
    final data = salt + secret + token + action + (postaction ?? '');
    final bytes = utf8.encode(data);
    return sha1.convert(bytes).toString();
  }

  // --------------------------------
  // 1. Authentication APIs
  // --------------------------------

  /// Login with Crown Micro API
  Future<Map<String, dynamic>> loginWithCrownMicro(
      String username, String password,
      {bool isAgent = false}) async {
    try {
      print('API Tester: Attempting Crown Micro login for user: $username');
      print('API Tester: Installer mode: $isAgent');

      final url = '${_crownApiBaseUrl}Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey
      };
      final body = {
        "UserName": username,
        "Password": password,
        "IsAgent": isAgent
      };

      print('API Tester: URL: $url');
      print('API Tester: Headers: $headers');
      print('API Tester: Body: $body');

      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('API Tester: Crown Micro login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (!isAgent && data['Token'] != null) {
          _token = data['Token'];
          _secret = data['Secret'];
          _isLoggedIn = true;
          print('API Tester: Login successful, saved credentials');
        } else if (isAgent && data['Agentslist'] != null) {
          // For agent login, we'd need to pick one and then login with it
          print(
              'API Tester: Agent login successful, found ${data['Agentslist'].length} agents');
        }

        return data;
      } else {
        print(
            'API Tester: Login failed with status code: ${response.statusCode}');
        return {'error': 'Login failed', 'status': response.statusCode};
      }
    } catch (e) {
      print('API Tester: Exception during login: $e');
      return {'error': e.toString()};
    }
  }

  /// Login with agent account after selecting from list
  Future<Map<String, dynamic>> loginWithAgentAccount(
      Map<String, dynamic> agentData) async {
    try {
      print(
          'API Tester: Attempting Agent login with: ${agentData['Username']}');

      final url = '${_crownApiBaseUrl}Login';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey
      };
      final body = {
        "Username": agentData['Username'],
        "Password": agentData['Password'],
        "SNNumber": agentData['SNNumber'],
        "IsAgent": true
      };

      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('API Tester: Agent login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['Token'] != null) {
          _token = data['Token'];
          _secret = data['Secret'];
          _isLoggedIn = true;
          print('API Tester: Agent login successful, saved credentials');
        }

        return data;
      } else {
        print(
            'API Tester: Agent login failed with status code: ${response.statusCode}');
        return {'error': 'Login failed', 'status': response.statusCode};
      }
    } catch (e) {
      print('API Tester: Exception during agent login: $e');
      return {'error': e.toString()};
    }
  }

  // --------------------------------
  // 2. Plant APIs
  // --------------------------------

  /// Query all plants for a user
  Future<Map<String, dynamic>> queryPlants() async {
    try {
      await _checkLoginStatus();

      const action =
          '&action=webQueryPlants&orderBy=ascPlantName&page=0&pagesize=100';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying plants with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plants response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved ${data['dat']['total']} plants');
          return data;
        } else {
          print('API Tester: Error retrieving plants: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plants with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plants: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query plant details by ID
  Future<Map<String, dynamic>> queryPlantDetails(String plantId) async {
    try {
      await _checkLoginStatus();

      // Changed from webQueryPlantDetailEs to QueryPlantDetail which might work better
      final action = '&action=QueryPlantDetail&plantid=$plantId';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying plant details with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plant details response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved details for plant $plantId');
          return data;
        } else {
          print('API Tester: Error retrieving plant details: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plant details with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plant details: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query plant current active output power
  Future<Map<String, dynamic>> queryPlantActiveOutputPowerOneDay(String plantId,
      {String? date}) async {
    try {
      await _checkLoginStatus();

      final currentDate = date ?? _getCurrentDate();
      // Fixed typo in the action name: queryPlantActiveOuputPowerOneDay -> queryPlantActiveOutputPowerOneDay
      final action =
          '&action=queryPlantActiveOutputPowerOneDay&plantid=$plantId&date=$currentDate';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying plant active output power with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plant active output power response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved active output power for plant $plantId');
          return data;
        } else {
          print(
              'API Tester: Error retrieving plant active output power: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plant active output power with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plant active output power: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query plant energy data for a specific time range
  Future<Map<String, dynamic>> queryPlantEnergyByDay(String plantId,
      {String? startDate, String? endDate}) async {
    try {
      await _checkLoginStatus();

      final today = _getCurrentDate();
      final start = startDate ?? today;
      final end = endDate ?? today;

      final action =
          '&action=queryPlantEnergyByDay&plantid=$plantId&sdate=$start&edate=$end';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying plant energy data with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plant energy data response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved energy data for plant $plantId');
          return data;
        } else {
          print(
              'API Tester: Error retrieving plant energy data: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plant energy data with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plant energy data: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  // --------------------------------
  // 3. Device APIs
  // --------------------------------

  /// Query all devices for a plant
  Future<Map<String, dynamic>> queryDevices(String plantId,
      {String status = '0101', String deviceType = '0101'}) async {
    try {
      await _checkLoginStatus();

      String action;
      if (status == '0101' && deviceType == '0101') {
        // All devices
        action =
            '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
      } else if (status == '0101' &&
          deviceType != '0101' &&
          deviceType != '0110') {
        // Specific device type
        action =
            '&action=webQueryDeviceEs&devtype=$deviceType&page=0&pagesize=100&plantid=$plantId';
      } else if (status == '0101' && deviceType == '0110') {
        // Collectors
        action =
            '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
      } else if (status != '0101' && deviceType == '0110') {
        // Collectors with status
        action =
            '&action=webQueryCollectorsEs&status=$status&page=0&pagesize=100&plantid=$plantId';
      } else {
        // Devices with status and device type
        action =
            '&action=webQueryDeviceEs&status=$status&page=0&pagesize=100&plantid=$plantId';
      }

      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying devices with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Devices response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          if (data['dat']?['device'] != null) {
            print(
                'API Tester: Successfully retrieved ${data['dat']['device'].length} devices');
          } else if (data['dat']?['collector'] != null) {
            print(
                'API Tester: Successfully retrieved ${data['dat']['collector'].length} collectors');
          }
          return data;
        } else {
          print('API Tester: Error retrieving devices: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query devices with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying devices: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query all collectors (dataloggers) for a plant
  Future<Map<String, dynamic>> queryCollectors(String plantId,
      {String status = '0101'}) async {
    try {
      await _checkLoginStatus();

      String action;
      if (status == '0101') {
        // All collectors
        action =
            '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
      } else {
        // Collectors with status
        action =
            '&action=webQueryCollectorsEs&status=$status&page=0&pagesize=100&plantid=$plantId';
      }

      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying collectors with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Collectors response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved ${data['dat']['collector']?.length ?? 0} collectors');
          return data;
        } else {
          print('API Tester: Error retrieving collectors: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query collectors with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying collectors: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query devices under a specific collector
  Future<Map<String, dynamic>> queryDevicesForCollector(
      String collectorPn) async {
    try {
      await _checkLoginStatus();

      final action =
          '&action=webQueryDeviceEs&pn=$collectorPn&page=0&pagesize=20';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print(
          'API Tester: Querying devices for collector $collectorPn with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Devices for collector response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved ${data['dat']['device']?.length ?? 0} devices for collector $collectorPn');
          return data;
        } else {
          print(
              'API Tester: Error retrieving devices for collector: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query devices for collector with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying devices for collector: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query collector info by PN
  Future<Map<String, dynamic>> queryCollectorInfo(String collectorPn) async {
    try {
      await _checkLoginStatus();

      final action = '&action=queryCollectorInfo&pn=$collectorPn';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print(
          'API Tester: Querying collector info for $collectorPn with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Collector info response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved info for collector $collectorPn');
          return data;
        } else {
          print('API Tester: Error retrieving collector info: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query collector info with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying collector info: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query device live signal/control fields
  Future<Map<String, dynamic>> queryDeviceCtrlField({
    required String pn,
    required String sn,
    required int devcode,
    required int devaddr,
  }) async {
    try {
      await _checkLoginStatus();

      final action =
          '&action=queryDeviceCtrlField&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying device control fields with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Device control fields response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved control fields for device PN: $pn, SN: $sn');

          // Print available fields for reference
          if (data['dat']?['field'] != null && data['dat']['field'] is List) {
            print('API Tester: Available parameters for this device:');
            for (var field in data['dat']['field']) {
              if (field is Map && field['name'] != null) {
                print('  - ${field['name']} (id: ${field['id']})');
              }
            }
          }

          return data;
        } else {
          print(
              'API Tester: Error retrieving device control fields: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query device control fields with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying device control fields: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query device data for one day
  Future<Map<String, dynamic>> queryDeviceDataOneDay({
    required String pn,
    required String sn,
    required int devcode,
    required int devaddr,
    String? date,
    int page = 0,
    int pageSize = 200,
  }) async {
    try {
      await _checkLoginStatus();

      final currentDate = date ?? _getCurrentDate();
      final action =
          '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&date=$currentDate&page=$page&pagesize=$pageSize&i18n=en_US';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying device data for one day with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Device data for one day response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved data for device PN: $pn, SN: $sn on $currentDate');
          return data;
        } else {
          print('API Tester: Error retrieving device data: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query device data with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying device data: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query device key parameter for one day (e.g., PV_OUTPUT_POWER, BATTERY_SOC)
  Future<Map<String, dynamic>> queryDeviceKeyParameterOneDay({
    required String pn,
    required String sn,
    required int devcode,
    required int devaddr,
    required String parameter,
    String? date,
  }) async {
    try {
      await _checkLoginStatus();

      final currentDate = date ?? _getCurrentDate();
      final action =
          '&action=queryDeviceKeyParameterOneDay&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&parameter=$parameter&date=$currentDate&i18n=en_US';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print(
          'API Tester: Querying device key parameter for one day with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Device key parameter response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved $parameter data for device PN: $pn, SN: $sn on $currentDate');
          return data;
        } else {
          print(
              'API Tester: Error retrieving device key parameter: ${data['desc']}');
          // Try to extract parameter name from error message
          final errorDesc = data['desc']?.toString() ?? '';
          if (errorDesc.contains('can not found parameter')) {
            final paramRegExp = RegExp(r'can not found parameter: ([^)]+)');
            final match = paramRegExp.firstMatch(errorDesc);
            if (match != null && match.groupCount >= 1) {
              final requestedParam = match.group(1);
              print('API Tester: API rejected parameter: $requestedParam');

              // Try to suggest alternative parameters based on device type
              print(
                  'API Tester: For device type $devcode, try these alternative parameters:');

              if (devcode >= 2400 && devcode < 2500) {
                // Energy storage machine
                print(
                    '  - For battery level: SOC, BAT_SOC, BATTERY_LEVEL, BATTERY_SOC, BAT_LEVEL');
                print(
                    '  - For PV power: PV_POWER, PV_OUTPUT_POWER, PV_INPUT_POWER, SOLAR_POWER');
                print(
                    '  - For load power: LOAD_POWER, AC_OUTPUT_POWER, AC_OUTPUT_ACTIVE_POWER');
                print(
                    '  - For grid power: GRID_POWER, GRID_INPUT_POWER, AC_INPUT_POWER');
                print(
                    '  - For temperatures: BATTERY_TEMP, HEATSINK_TEMP, TRANSFORMER_TEMP');
              } else if (devcode >= 1000 && devcode < 2000) {
                // Inverter
                print('  - For PV power: PV_POWER, DC_POWER, DC_INPUT_POWER');
                print(
                    '  - For output power: OUTPUT_POWER, AC_OUTPUT_POWER, ACTIVE_POWER');
                print(
                    '  - For voltage: AC_VOLTAGE, OUTPUT_VOLTAGE, DC_VOLTAGE, INPUT_VOLTAGE');
                print(
                    '  - For current: AC_CURRENT, OUTPUT_CURRENT, DC_CURRENT, INPUT_CURRENT');
                print('  - For temperatures: INVERTER_TEMP, MODULE_TEMP');
              }
            }
          }
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query device key parameter with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying device key parameter: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Try to find working parameters for a device by testing multiple options
  Future<List<String>> discoverWorkingParameters({
    required String pn,
    required String sn,
    required int devcode,
    required int devaddr,
  }) async {
    print(
        'API Tester: Attempting to discover working parameters for device type $devcode');

    // Common parameter combinations to test based on device type
    List<String> parametersToTest = [];

    if (devcode >= 2400 && devcode < 2500) {
      // Energy storage parameters
      parametersToTest = [
        // Battery related
        'SOC', 'BATTERY_SOC', 'BAT_SOC', 'BATTERY_LEVEL', 'BAT_LEVEL',
        // PV related
        'PV_POWER', 'PV_INPUT_POWER', 'SOLAR_POWER', 'PV_INPUT', 'PV_VOLTAGE',
        'PV_CURRENT',
        // AC output related
        'AC_OUTPUT_POWER', 'OUTPUT_POWER', 'LOAD_POWER',
        'AC_OUTPUT_ACTIVE_POWER',
        'AC_OUTPUT_VOLTAGE', 'AC_OUTPUT_CURRENT', 'AC_OUTPUT_FREQUENCY',
        // AC input related
        'AC_INPUT_POWER', 'GRID_POWER', 'AC_INPUT_VOLTAGE', 'AC_INPUT_CURRENT',
        'AC_INPUT_FREQUENCY',
        // Temperatures
        'TEMPERATURE', 'BATTERY_TEMPERATURE', 'INVERTER_TEMPERATURE'
      ];
    } else if (devcode >= 1000 && devcode < 2000) {
      // Inverter parameters
      parametersToTest = [
        // DC related
        'DC_POWER', 'DC_INPUT_POWER', 'DC_VOLTAGE', 'DC_CURRENT',
        // AC related
        'AC_POWER', 'AC_OUTPUT_POWER', 'AC_VOLTAGE', 'AC_CURRENT',
        'AC_FREQUENCY',
        // General
        'OUTPUT_POWER', 'INPUT_POWER', 'TEMPERATURE', 'EFFICIENCY'
      ];
    } else {
      // Generic parameters for other device types
      parametersToTest = [
        'POWER',
        'VOLTAGE',
        'CURRENT',
        'ENERGY',
        'TEMPERATURE'
      ];
    }

    List<String> workingParameters = [];

    for (final parameter in parametersToTest) {
      final result = await queryDeviceKeyParameterOneDay(
          pn: pn,
          sn: sn,
          devcode: devcode,
          devaddr: devaddr,
          parameter: parameter);

      if (result['err'] == 0) {
        print(
            'API Tester: Parameter $parameter WORKS for device type $devcode');
        workingParameters.add(parameter);
      } else {
        print(
            'API Tester: Parameter $parameter does NOT work for device type $devcode');
      }

      // Small delay to avoid overwhelming the API
      await Future.delayed(Duration(milliseconds: 200));
    }

    print(
        'API Tester: Found ${workingParameters.length} working parameters: ${workingParameters.join(', ')}');
    return workingParameters;
  }

  // --------------------------------
  // 6. Alarm Management APIs
  // --------------------------------

  /// Query alarms for all plants
  Future<Map<String, dynamic>> queryAlarms(
      {int page = 0, int pageSize = 20}) async {
    try {
      await _checkLoginStatus();

      // Changed from QueryAlarmList to webQueryAlarm which might work better
      final action = '&action=webQueryAlarm&page=$page&pagesize=$pageSize';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying alarms with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Alarms response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved ${data['dat']['alarm']?.length ?? 0} alarms');
          return data;
        } else {
          print('API Tester: Error retrieving alarms: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query alarms with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying alarms: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query alarms for a specific plant
  Future<Map<String, dynamic>> queryPlantAlarms(String plantId,
      {int page = 0, int pageSize = 20}) async {
    try {
      await _checkLoginStatus();

      // Changed from QueryAlarmList to webQueryAlarm with plantid which might work better
      final action =
          '&action=webQueryAlarm&plantid=$plantId&page=$page&pagesize=$pageSize';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying alarms for plant $plantId with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plant alarms response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved ${data['dat']['alarm']?.length ?? 0} alarms for plant $plantId');
          return data;
        } else {
          print('API Tester: Error retrieving plant alarms: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plant alarms with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plant alarms: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  /// Query plant energy generation distribution for a period
  Future<Map<String, dynamic>> queryPlantPowerDistribution(String plantId,
      {String? date, String type = 'day'}) async {
    try {
      await _checkLoginStatus();

      final currentDate = date ?? _getCurrentDate();

      final action =
          '&action=queryPlantPowerDistribution&plantid=$plantId&date=$currentDate&type=$type';
      final sign = _generateSign(_salt, _secret!, _token!, action, _postAction);
      final url =
          '${_apiBaseUrl}?sign=$sign&salt=$_salt&token=$_token$action$_postAction';

      print('API Tester: Querying plant power distribution with URL: $url');

      final response = await http.post(Uri.parse(url));
      print('API Tester: Plant power distribution response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['err'] == 0) {
          print(
              'API Tester: Successfully retrieved power distribution for plant $plantId');
          return data;
        } else {
          print(
              'API Tester: Error retrieving plant power distribution: ${data['desc']}');
          return data;
        }
      } else {
        print(
            'API Tester: Failed to query plant power distribution with status code: ${response.statusCode}');
        return {'err': response.statusCode, 'desc': 'HTTP error'};
      }
    } catch (e) {
      print('API Tester: Exception querying plant power distribution: $e');
      return {'err': -1, 'desc': e.toString()};
    }
  }

  // --------------------------------
  // Helper Methods
  // --------------------------------

  /// Check if logged in and throw exception if not
  Future<void> _checkLoginStatus() async {
    if (_token == null || _secret == null) {
      throw Exception('Not logged in. Call loginWithCrownMicro() first.');
    }
  }

  /// Get current date in YYYY-MM-DD format
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Print all available device types and their codes
  void printDeviceTypes() {
    print('API Tester: Available device types:');
    print('  - Inverters: 1000-1999');
    print('  - Energy Storage Machines: 2400-2499');
    print('  - Collectors/Dataloggers: 2304');
    print('  - Smart Meters: 3000-3999');
    print('  - Environmental Monitors: 4000-4999');
  }

  /// Print common parameters for energy storage devices
  void printEnergyStorageParameters() {
    print('API Tester: Common parameters for energy storage devices:');
    print('  - Battery Level: SOC, BAT_SOC, BATTERY_LEVEL, BATTERY_SOC');
    print('  - PV Power: PV_POWER, PV_OUTPUT_POWER, PV_GEN_POWER');
    print('  - Load Power: LOAD_POWER, AC_OUTPUT_POWER, LOAD_ACTIVE_POWER');
    print('  - Grid Power: GRID_POWER, GRID_ACTIVE_POWER');
    print('  - Output Voltage: OUTPUT_VOLTAGE, AC_VOLTAGE');
    print('  - Output Current: OUTPUT_CURRENT, AC_CURRENT');
  }

  /// Print common parameters for inverters
  void printInverterParameters() {
    print('API Tester: Common parameters for inverters:');
    print('  - PV Power: PV_POWER, DC_POWER');
    print('  - Output Power: OUTPUT_POWER, AC_OUTPUT_POWER');
    print('  - Output Voltage: OUTPUT_VOLTAGE, AC_VOLTAGE');
    print('  - Output Current: OUTPUT_CURRENT, AC_CURRENT');
  }
}

void main() async {
  // Initialize
  print('API Tester: Starting test...');

  final apiTester = ApiTester();

  // 1. Login test
  print('\n=== 1. TESTING LOGIN ===');
  final loginResult = await apiTester.loginWithCrownMicro(
      'aatif100', // Replace with your actual username
      'hamza1', // Replace with your actual password
      isAgent: false);
  print(
      'Login result: ${loginResult.toString().substring(0, min(100, loginResult.toString().length))}...');

  // If login failed, wait 3 seconds and exit
  if (loginResult['Token'] == null) {
    print('Login failed. Please check your credentials.');
    await Future.delayed(Duration(seconds: 3));
    return;
  }

  // 2. Query plants
  print('\n=== 2. TESTING QUERY PLANTS ===');
  final plantsResult = await apiTester.queryPlants();

  // If plants query succeeded, get the first plant ID
  String? firstPlantId;
  if (plantsResult['err'] == 0 &&
      plantsResult['dat'] != null &&
      plantsResult['dat']['plant'] != null &&
      plantsResult['dat']['plant'].isNotEmpty) {
    firstPlantId = plantsResult['dat']['plant'][0]['pid'].toString();
    print('Found first plant ID: $firstPlantId');
  } else {
    print('No plants found or error in query');
  }

  // Only continue if we have a plant ID
  if (firstPlantId != null) {
    // 3. Query plant details
    print('\n=== 3. TESTING QUERY PLANT DETAILS ===');
    await apiTester.queryPlantDetails(firstPlantId);

    // 4. Query plant active output power
    print('\n=== 4. TESTING QUERY PLANT ACTIVE OUTPUT POWER ===');
    await apiTester.queryPlantActiveOutputPowerOneDay(firstPlantId);

    // 5. Query plant energy by day
    print('\n=== 5. TESTING QUERY PLANT ENERGY BY DAY ===');
    // Get data for last 7 days
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    final formattedDate =
        '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
    await apiTester.queryPlantEnergyByDay(firstPlantId,
        startDate: formattedDate);

    // 6. Query plant power distribution
    print('\n=== 6. TESTING QUERY PLANT POWER DISTRIBUTION ===');
    await apiTester.queryPlantPowerDistribution(firstPlantId);

    // 7. Query devices
    print('\n=== 7. TESTING QUERY DEVICES ===');
    final devicesResult = await apiTester.queryDevices(firstPlantId);

    // If devices query succeeded, get the first device
    if (devicesResult['err'] == 0 &&
        devicesResult['dat'] != null &&
        devicesResult['dat']['device'] != null &&
        devicesResult['dat']['device'].isNotEmpty) {
      final firstDevice = devicesResult['dat']['device'][0];
      final devicePn = firstDevice['pn']?.toString() ?? '';
      final deviceSn = firstDevice['sn']?.toString() ?? '';
      final deviceCode =
          int.tryParse(firstDevice['devcode']?.toString() ?? '0') ?? 0;
      final deviceAddr =
          int.tryParse(firstDevice['devaddr']?.toString() ?? '1') ?? 1;

      print(
          'Found first device: PN=$devicePn, SN=$deviceSn, Code=$deviceCode, Addr=$deviceAddr');

      // 8. Query device live signal
      print('\n=== 8. TESTING QUERY DEVICE LIVE SIGNAL ===');
      await apiTester.queryDeviceCtrlField(
          pn: devicePn, sn: deviceSn, devcode: deviceCode, devaddr: deviceAddr);

      // 9. Query device data for one day
      print('\n=== 9. TESTING QUERY DEVICE DATA FOR ONE DAY ===');
      await apiTester.queryDeviceDataOneDay(
          pn: devicePn, sn: deviceSn, devcode: deviceCode, devaddr: deviceAddr);

      // 10. Discover working device parameters
      print('\n=== 10. TESTING DISCOVER WORKING PARAMETERS ===');
      await apiTester.discoverWorkingParameters(
          pn: devicePn, sn: deviceSn, devcode: deviceCode, devaddr: deviceAddr);
    } else {
      print('No devices found or error in query');
    }

    // 11. Query collectors
    print('\n=== 11. TESTING QUERY COLLECTORS ===');
    final collectorsResult = await apiTester.queryCollectors(firstPlantId);

    // If collectors query succeeded, get the first collector
    if (collectorsResult['err'] == 0 &&
        collectorsResult['dat'] != null &&
        collectorsResult['dat']['collector'] != null &&
        collectorsResult['dat']['collector'].isNotEmpty) {
      final firstCollector = collectorsResult['dat']['collector'][0];
      final collectorPn = firstCollector['pn']?.toString() ?? '';

      print('Found first collector: PN=$collectorPn');

      // 12. Query devices for collector
      print('\n=== 12. TESTING QUERY DEVICES FOR COLLECTOR ===');
      await apiTester.queryDevicesForCollector(collectorPn);

      // 13. Query collector info
      print('\n=== 13. TESTING QUERY COLLECTOR INFO ===');
      await apiTester.queryCollectorInfo(collectorPn);
    } else {
      print('No collectors found or error in query');
    }

    // 14. Query alarms
    print('\n=== 14. TESTING QUERY ALARMS ===');
    await apiTester.queryAlarms();

    // 15. Query plant alarms
    print('\n=== 15. TESTING QUERY PLANT ALARMS ===');
    await apiTester.queryPlantAlarms(firstPlantId);
  }

  print('\n=== API TEST COMPLETED ===');
  print('Please check the console output for API responses');
  print('You can now use this information to improve the app\'s data parsing');

  // Print reference information
  apiTester.printDeviceTypes();
  apiTester.printEnergyStorageParameters();
  apiTester.printInverterParameters();
}
