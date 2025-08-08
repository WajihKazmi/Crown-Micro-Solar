import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('=== ALARM API TEST ===');
  print('This test will use real stored credentials from the app');
  print('Make sure you have logged in to the app first!');

  await testAlarmAPI();
}

Future<void> testAlarmAPI() async {
  final dio = Dio();

  try {
    print('\n1. Getting stored credentials...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final appkey = prefs.getString('appkey');
    final plantId = prefs.getString('plant_id');

    print('Token: ${token != null ? '${token.substring(0, 10)}...' : 'NULL'}');
    print('Username: $username');
    print(
        'AppKey: ${appkey != null ? '${appkey.substring(0, 10)}...' : 'NULL'}');
    print('Plant ID: $plantId');

    if (token == null ||
        username == null ||
        appkey == null ||
        plantId == null) {
      print('❌ ERROR: Missing authentication credentials');
      print(
          'Please update the mock values with real credentials from your working login');
      return;
    }

    print('\n2. Testing alarm API with different parameters...');

    // Test 1: Basic alarm query
    await testAlarmQuery(dio, plantId, token, appkey, 'Basic Query', {});

    // Test 2: Query with date range (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    final startDate =
        '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await testAlarmQuery(dio, plantId, token, appkey, 'Last 30 Days', {
      'startTime': startDate,
      'endTime': endDate,
    });

    // Test 3: Query with larger page size
    await testAlarmQuery(dio, plantId, token, appkey, 'Larger Page Size', {
      'toPageSize': '100',
    });

    // Test 4: Query all devices and all types
    await testAlarmQuery(dio, plantId, token, appkey, 'All Devices/Types', {
      'deviceType': '0101',
      'alarmType': '0101',
      'isHandle': '0101',
    });

    // Test 5: Query only untreated alarms
    await testAlarmQuery(dio, plantId, token, appkey, 'Untreated Only', {
      'isHandle': 'false',
    });

    // Test 6: Try the old app's endpoint format
    print('\n6. Testing alternative API endpoints...');
    await testAlternativeEndpoints(dio, plantId, token, appkey);
  } catch (e) {
    print('❌ ERROR in main test: $e');
  }
}

Future<void> testAlarmQuery(Dio dio, String plantId, String token,
    String appkey, String testName, Map<String, String> extraParams) async {
  try {
    print('\n--- Testing: $testName ---');

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    String queryString =
        'action=queryPlantWarning&plantId=$plantId&toPageNum=1&toPageSize=50';

    // Add extra parameters
    extraParams.forEach((key, value) {
      queryString += '&$key=$value';
    });

    queryString += '&timeStamp=$timestamp&token=$token';

    // Generate signature
    final signatureInput = queryString + appkey;
    final bytes = utf8.encode(signatureInput);
    final digest = md5.convert(bytes);
    final sign = digest.toString();

    queryString += '&sign=$sign';

    final url = 'https://openapi.growatt.com/v1/plant/warning?$queryString';
    print('URL: $url');

    final response = await dio.get(url);

    print('Status Code: ${response.statusCode}');
    print('Response: ${response.data}');

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      print('Error Code: ${data['err']}');

      if (data['err'] == 0 && data['dat'] != null) {
        if (data['dat']['warning'] != null) {
          final warnings = data['dat']['warning'] as List;
          print('✅ SUCCESS: Found ${warnings.length} warnings');

          if (warnings.isNotEmpty) {
            print('First warning sample:');
            print(json.encode(warnings.first));
          }
        } else {
          print('⚠️  SUCCESS but no warnings found in data');
          print('Available data keys: ${data['dat']?.keys}');
        }
      } else {
        print('❌ API Error: ${getErrorMessage(data['err'])}');
      }
    }
  } catch (e) {
    print('❌ ERROR in $testName: $e');
  }
}

Future<void> testAlternativeEndpoints(
    Dio dio, String plantId, String token, String appkey) async {
  final endpoints = [
    'https://openapi.growatt.com/v1/plant/warning',
    'https://openapi.growatt.com/v1/warning/query',
    'https://openapi.growatt.com/v1/plant/alarm',
    'https://server.growatt.com/v1/plant/warning',
  ];

  for (final endpoint in endpoints) {
    try {
      print('\nTesting endpoint: $endpoint');

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      String queryString =
          'action=queryPlantWarning&plantId=$plantId&toPageNum=1&toPageSize=10&timeStamp=$timestamp&token=$token';

      final signatureInput = queryString + appkey;
      final bytes = utf8.encode(signatureInput);
      final digest = md5.convert(bytes);
      final sign = digest.toString();

      queryString += '&sign=$sign';

      final response = await dio.get('$endpoint?$queryString');
      print('Status: ${response.statusCode}');
      print('Response: ${response.data}');
    } catch (e) {
      print('Failed: $e');
    }
  }
}

String getErrorMessage(int? errorCode) {
  switch (errorCode) {
    case 0:
      return 'Success';
    case 11:
      return 'No permission to operate power station';
    case 12:
      return 'No record found';
    case 260:
      return 'Power station not found';
    case 264:
      return 'Device alarm not found';
    case 404:
      return 'No response from server';
    default:
      return 'Unknown error code: $errorCode';
  }
}
