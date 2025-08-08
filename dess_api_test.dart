import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// Test DESS Monitor API for alarm data
void main() async {
  final tester = DessApiTester();
  await tester.runTests();
}

class DessApiTester {
  final String baseUrl = 'http://api.dessmonitor.com/public/';

  // Add credentials from the app (from Crown Micro login response)
  final String token = '6b3ab1e3-af66-4af7-ac5a-7ad00b7ca6a8';
  final String secret = 'bff8a1bef5a20e8c95b4eae6a509f84b';
  final String salt = '12345678';

  String? plantId;

  Future<void> runTests() async {
    print('=== Starting DESS Monitor API Tests ===\n');

    try {
      await testPlantList();
      if (plantId != null) {
        await testPlantAlarms();
      }
    } catch (e) {
      print('Test error: $e');
    }
  }

  Future<void> testPlantList() async {
    print('1. Testing Plant List via DESS Monitor API...');

    // Try a working action from device repository first
    const action = '&action=webQueryDeviceEs&page=0&pagesize=10';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        '${baseUrl}?sign=$sign&salt=$salt&token=$token$action$postaction';

    print('URL: $url');

    final response = await http.post(Uri.parse(url));

    print('Device Query Status: ${response.statusCode}');
    print('Device Query Response: ${response.body}\n');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['dat'] != null) {
        print('✓ API is working, device query successful');
        if (data['dat']['devices'] != null) {
          final devices = data['dat']['devices'] as List<dynamic>;
          print('Found ${devices.length} devices');
          if (devices.isNotEmpty) {
            // Try to extract plant ID from device data
            for (final device in devices) {
              if (device['plantId'] != null) {
                plantId = device['plantId'].toString();
                print('Extracted plant ID: $plantId');
                break;
              }
            }
          }
        }
      } else {
        print('✗ Device query response structure: ${data}');
      }
    } else {
      print('✗ Device query HTTP error: ${response.statusCode}');
    }

    // If we don't have a plant ID yet, try a hardcoded one from the working test
    if (plantId == null) {
      plantId = '5134877'; // From the working API tests
      print('Using hardcoded plant ID: $plantId');
    }

    print('');
  }

  Future<void> testPlantAlarms() async {
    if (plantId == null) return;

    print('2. Testing Plant Alarms via DESS Monitor API...');

    // Try various alarm-related actions
    await _testAlarmAction('webQueryPlantWarning');
    await _testAlarmAction('webQueryWarning');
    await _testAlarmAction('webQueryAlarm');
    await _testAlarmAction('webQueryPlantAlarm');
    await _testAlarmAction('queryPlantWarning');
    await _testAlarmAction('queryWarning');
    await _testAlarmAction('queryAlarm');
    await _testAlarmAction('getPlantWarnings');
    await _testAlarmAction('getWarnings');
    await _testAlarmAction('getAlarms');

    // Try plant-specific device and energy queries (these work from device repository)
    await _testAlarmAction('webQueryDeviceEs');
    await _testAlarmAction('webQueryPlantEnergyByDay');
  }

  Future<void> _testAlarmAction(String actionName) async {
    print('  Testing action: $actionName...');

    final action = '&action=$actionName&plantid=$plantId&page=0&pagesize=50';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        '${baseUrl}?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      final response = await http.post(Uri.parse(url));

      print('    Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('    Response: ${response.body}');

        if (data['dat'] != null) {
          print('    ✓ $actionName: Success with data structure');
          if (data['dat'] is Map &&
              (data['dat'] as Map).containsKey('warning')) {
            final warnings = data['dat']['warning'] as List<dynamic>? ?? [];
            print('    Found ${warnings.length} warnings');
          } else if (data['dat'] is Map &&
              (data['dat'] as Map).containsKey('alarm')) {
            final alarms = data['dat']['alarm'] as List<dynamic>? ?? [];
            print('    Found ${alarms.length} alarms');
          } else if (data['dat'] is List) {
            print('    Found ${(data['dat'] as List).length} items');
          }
        } else if (data['err'] != null) {
          print('    ✗ $actionName error code: ${data['err']}');
        } else {
          print('    ✗ $actionName: Unexpected response structure');
        }
      } else {
        print('    ✗ $actionName HTTP error: ${response.statusCode}');
        print('    Response: ${response.body}');
      }
    } catch (e) {
      print('    ✗ $actionName error: $e');
    }

    print('');
  }
}
