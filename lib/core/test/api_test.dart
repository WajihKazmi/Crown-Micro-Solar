import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiTest {
  static const String baseUrl = 'http://api.dessmonitor.com/public/';
  static const String salt = '12345678';
  static const String appId = 'test.app';
  static const String appVersion = '1.0.0';
  static const String appClient = 'android';
  static const String source = '1';

  static String? _token;
  static String? _secret;

  static List<ApiTestResult> _results = [];
  static int _totalApis = 0;
  static int _successfulApis = 0;
  static int _failedApis = 0;

  static Future<void> runAllTests() async {
    print('🚀 Starting API Tests...');
    print('=' * 50);
    
    _results.clear();
    _totalApis = 0;
    _successfulApis = 0;
    _failedApis = 0;

    // Load credentials
    await _loadCredentials();
    
    if (_token == null || _secret == null) {
      print('❌ No valid credentials found. Please login first.');
      return;
    }

    print('✅ Credentials loaded successfully');
    print('Token: ${_token!.substring(0, 20)}...');
    print('Secret: ${_secret!.substring(0, 20)}...');
    print('');

    // Test all APIs
    await _testLoginApi();
    await _testPlantApis();
    await _testDeviceApis();
    await _testEnergyApis();
    await _testAlarmApis();
    await _testAccountApis();
    await _testRealtimeApis();

    // Print final results
    _printFinalResults();
  }

  static Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _secret = prefs.getString('secret');
  }

  static Future<void> _testLoginApi() async {
    print('🔐 Testing Login APIs...');
    
    // Test login
    await _testApi(
      'Login',
      'login',
      {
        'username': 'test_user',
        'password': 'test_password',
      },
    );
  }

  static Future<void> _testPlantApis() async {
    print('🌱 Testing Plant APIs...');
    
    // Test plant list
    await _testApi(
      'Plant List',
      'webQueryPlant',
      {
        'page': '0',
        'pagesize': '10',
      },
    );

    // Test plant active output power
    await _testApi(
      'Plant Active Output Power',
      'queryPlantActiveOuputPowerOneDay',
      {
        'plantid': '5134877',
        'date': '2025-01-28',
      },
    );

    // Test plant energy data
    await _testApi(
      'Plant Energy Data',
      'queryPlantEnergyOneDay',
      {
        'plantid': '5134877',
        'date': '2025-01-28',
      },
    );
  }

  static Future<void> _testDeviceApis() async {
    print('📱 Testing Device APIs...');
    
    // Test device list
    await _testApi(
      'Device List',
      'webQueryDeviceEs',
      {
        'page': '0',
        'pagesize': '100',
        'plantid': '5134877',
      },
    );

    // Test collector list
    await _testApi(
      'Collector List',
      'webQueryCollectorEs',
      {
        'page': '0',
        'pagesize': '100',
        'plantid': '5134877',
      },
    );

    // Test device data one day
    await _testApi(
      'Device Data One Day',
      'queryDeviceDataOneDay',
      {
        'sn': 'TEST_SN',
        'pn': 'TEST_PN',
        'devcode': '512',
        'devaddr': '1',
        'date': '2025-01-28',
      },
    );

    // Test device live signal
    await _testApi(
      'Device Live Signal',
      'queryDeviceCtrlFieldse',
      {
        'sn': 'TEST_SN',
        'pn': 'TEST_PN',
        'devcode': '512',
        'devaddr': '1',
      },
    );

    // Test device key parameter
    await _testApi(
      'Device Key Parameter',
      'querySPDeviceKeyParameterOneDay',
      {
        'sn': 'TEST_SN',
        'pn': 'TEST_PN',
        'devcode': '512',
        'devaddr': '1',
        'parameter': 'PV_OUTPUT_POWER',
        'date': '2025-01-28',
      },
    );
  }

  static Future<void> _testEnergyApis() async {
    print('⚡ Testing Energy APIs...');
    
    // Test energy summary
    await _testApi(
      'Energy Summary',
      'queryPlantEnergySummary',
      {
        'plantid': '5134877',
      },
    );

    // Test energy data
    await _testApi(
      'Energy Data',
      'queryPlantEnergyData',
      {
        'plantid': '5134877',
        'date': '2025-01-28',
      },
    );
  }

  static Future<void> _testAlarmApis() async {
    print('🚨 Testing Alarm APIs...');
    
    // Test alarm list
    await _testApi(
      'Alarm List',
      'webQueryAlarmEs',
      {
        'page': '0',
        'pagesize': '50',
        'plantid': '5134877',
      },
    );

    // Test alarm count
    await _testApi(
      'Alarm Count',
      'queryAlarmCount',
      {
        'plantid': '5134877',
      },
    );
  }

  static Future<void> _testAccountApis() async {
    print('👤 Testing Account APIs...');
    
    // Test account info
    await _testApi(
      'Account Info',
      'queryAccountInfo',
      {},
    );

    // Test change password
    await _testApi(
      'Change Password',
      'changePassword',
      {
        'oldPassword': 'old_pass',
        'newPassword': 'new_pass',
      },
    );
  }

  static Future<void> _testRealtimeApis() async {
    print('🔄 Testing Realtime APIs...');
    
    // Test realtime plant data
    await _testApi(
      'Realtime Plant Data',
      'queryPlantActiveOuputPowerOneDay',
      {
        'plantid': '5134877',
        'date': '2025-01-28',
      },
    );

    // Test realtime device data
    await _testApi(
      'Realtime Device Data',
      'queryDeviceCtrlFieldse',
      {
        'sn': 'TEST_SN',
        'pn': 'TEST_PN',
        'devcode': '512',
        'devaddr': '1',
      },
    );
  }

  static Future<void> _testApi(String name, String action, Map<String, String> params) async {
    _totalApis++;
    
    try {
      print('  Testing: $name...');
      
      // Build URL with parameters
      final allParams = {
        ...params,
        'action': action,
        'source': source,
        'app_id': appId,
        'app_version': appVersion,
        'app_client': appClient,
      };

      // Create postaction string
      final postaction = allParams.entries
          .where((entry) => entry.key != 'action')
          .map((entry) => '&${entry.key}=${entry.value}')
          .join('');

      // Generate signature
      final signData = salt + _secret! + _token! + action + postaction;
      final sign = sha1.convert(utf8.encode(signData)).toString();

      // Build final URL
      final url = '$baseUrl?sign=$sign&salt=$salt&token=$_token$action$postaction';

      print('    URL: ${url.substring(0, 100)}...');
      
      // Make request
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout after 10 seconds');
        },
      );

      // Parse response
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final err = responseData['err'];
        if (err == 0) {
          _successfulApis++;
          _results.add(ApiTestResult(
            name: name,
            success: true,
            response: responseData,
            error: null,
          ));
          print('    ✅ Success');
        } else {
          _failedApis++;
          final error = responseData['desc'] ?? 'Unknown error';
          _results.add(ApiTestResult(
            name: name,
            success: false,
            response: responseData,
            error: 'API Error: $error',
          ));
          print('    ❌ API Error: $error');
        }
      } else {
        _failedApis++;
        _results.add(ApiTestResult(
          name: name,
          success: false,
          response: null,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        ));
        print('    ❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _failedApis++;
      _results.add(ApiTestResult(
        name: name,
        success: false,
        response: null,
        error: e.toString(),
      ));
      print('    ❌ Exception: ${e.toString()}');
    }
    
    print('');
  }

  static void _printFinalResults() {
    print('=' * 50);
    print('📊 FINAL TEST RESULTS');
    print('=' * 50);
    print('Total APIs Tested: $_totalApis');
    print('✅ Successful: $_successfulApis');
    print('❌ Failed: $_failedApis');
    print('📈 Success Rate: ${((_successfulApis / _totalApis) * 100).toStringAsFixed(1)}%');
    print('');

    if (_failedApis > 0) {
      print('❌ FAILED APIS:');
      print('-' * 30);
      for (final result in _results.where((r) => !r.success)) {
        print('• ${result.name}: ${result.error}');
      }
      print('');
    }

    if (_successfulApis > 0) {
      print('✅ SUCCESSFUL APIS:');
      print('-' * 30);
      for (final result in _results.where((r) => r.success)) {
        print('• ${result.name}');
      }
      print('');
    }

    print('🔍 DETAILED RESPONSES:');
    print('-' * 30);
    for (final result in _results) {
      print('${result.name}:');
      print('  Status: ${result.success ? "✅ Success" : "❌ Failed"}');
      if (result.error != null) {
        print('  Error: ${result.error}');
      }
      if (result.response != null) {
        print('  Response: ${json.encode(result.response).substring(0, 200)}...');
      }
      print('');
    }
  }
}

class ApiTestResult {
  final String name;
  final bool success;
  final Map<String, dynamic>? response;
  final String? error;

  ApiTestResult({
    required this.name,
    required this.success,
    this.response,
    this.error,
  });
}

// Main function to run tests
void main() async {
  await ApiTest.runAllTests();
}
