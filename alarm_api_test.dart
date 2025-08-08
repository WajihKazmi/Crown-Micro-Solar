import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// Standalone alarm API test without Flutter dependencies
void main() async {
  final tester = AlarmApiTester();
  await tester.runTests();
}

class AlarmApiTester {
  final String baseUrl = 'https://openapi.growatt.com/v1';

  // Add your credentials here manually from SharedPreferences
  final String token = '6b3ab1e3-af66-4af7-ac5a-7ad00b7ca6a8';
  final String username = 'crownmicrosolar@gmail.com';
  final String appkey = 'bff8a1bef5a20e8c95b4eae6a509f84b';

  List<dynamic> plants = [];

  Future<void> runTests() async {
    print('=== Starting Alarm API Tests ===\n');

    try {
      await testPlantList();
      if (plants.isNotEmpty) {
        await testPlantAlarms();
      }
    } catch (e) {
      print('Test error: $e');
    }
  }

  Future<void> testPlantList() async {
    print('1. Testing Plant List...');

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    String queryString =
        'action=queryPlantList&timeStamp=$timestamp&token=$token';

    // Generate signature
    final signatureInput = queryString + appkey;
    final bytes = utf8.encode(signatureInput);
    final digest = md5.convert(bytes);
    final sign = digest.toString();

    queryString += '&sign=$sign';

    final response = await http.get(
      Uri.parse('$baseUrl/plant/list?$queryString'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('Plant List Status: ${response.statusCode}');
    print('Plant List Response: ${response.body}\n');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['dat'] != null && data['dat']['plants'] != null) {
        plants = data['dat']['plants'] as List<dynamic>;
        print('✓ Found ${plants.length} plants');
        for (int i = 0; i < plants.length; i++) {
          final plant = plants[i];
          print(
              '  Plant $i: ID=${plant['plantId']}, Name=${plant['plantName']}');
        }
      } else {
        print('✗ Plant list response structure: ${data}');
      }
    } else {
      print('✗ Plant list HTTP error: ${response.statusCode}');
    }
    print('');
  }

  Future<void> testPlantAlarms() async {
    print('2. Testing Plant Alarms...');

    for (int i = 0; i < plants.length; i++) {
      final plant = plants[i];
      final plantId = plant['plantId'].toString();

      print('  Testing alarms for Plant $plantId...');

      // Test basic alarm query using the old app's format
      await _testAlarmQuery(plantId, 'Basic Query', {});

      // Test with device type filters
      await _testAlarmQuery(plantId, 'Inverter devices', {
        'deviceType': '512',
      });

      await _testAlarmQuery(plantId, 'All devices', {
        'deviceType': '0101',
      });

      // Test with alarm type filters
      await _testAlarmQuery(plantId, 'Warning alarms', {
        'alarmType': '0',
      });

      await _testAlarmQuery(plantId, 'Error alarms', {
        'alarmType': '1',
      });

      // Test with status filters
      await _testAlarmQuery(plantId, 'Untreated alarms', {
        'isHandle': 'false',
      });

      await _testAlarmQuery(plantId, 'Processed alarms', {
        'isHandle': 'true',
      });

      print('');
    }
  }

  Future<void> _testAlarmQuery(
      String plantId, String testName, Map<String, String> params) async {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    String queryString =
        'action=queryPlantWarning&plantId=$plantId&toPageNum=1&toPageSize=50';

    // Add optional parameters
    for (final entry in params.entries) {
      queryString += '&${entry.key}=${entry.value}';
    }

    queryString += '&timeStamp=$timestamp&token=$token';

    // Generate signature like old app
    final signatureInput = queryString + appkey;
    final bytes = utf8.encode(signatureInput);
    final digest = md5.convert(bytes);
    final sign = digest.toString();

    queryString += '&sign=$sign';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plant/warning?$queryString'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('    $testName Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('    $testName Response: ${response.body}');

        if (data['dat'] != null && data['dat']['warning'] != null) {
          final warnings = data['dat']['warning'] as List<dynamic>;
          print('    ✓ $testName: Found ${warnings.length} warnings');

          if (warnings.isNotEmpty) {
            print('    Sample warning: ${warnings.first}');
          }
        } else if (data['err'] != null) {
          print('    ✗ $testName error code: ${data['err']}');
          switch (data['err']) {
            case 11:
              print('    Error: No permission to operate power station');
              break;
            case 12:
              print('    Error: No record found');
              break;
            case 260:
              print('    Error: Power station not found');
              break;
            case 264:
              print('    Error: Device alarm not found');
              break;
            case 404:
              print('    Error: No response from server');
              break;
            default:
              print('    Error: Unknown error code ${data['err']}');
          }
        } else {
          print('    ✗ $testName: Unexpected response structure');
        }
      } else {
        print('    ✗ $testName HTTP error: ${response.statusCode}');
        print('    Response: ${response.body}');
      }
    } catch (e) {
      print('    ✗ $testName error: $e');
    }

    print('');
  }
}
