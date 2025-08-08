import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Simple test to check stored credentials
void main() async {
  print('=== Checking Stored Credentials ===\n');

  try {
    final prefs = await SharedPreferences.getInstance();

    print('Available keys in SharedPreferences:');
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is String && value.length > 20) {
        print('  $key: ${value.substring(0, 20)}...');
      } else {
        print('  $key: $value');
      }
    }

    print('\nAlarm Repository Required Keys:');
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final appkey = prefs.getString('appkey');

    print(
        '  token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');
    print('  username: $username');
    print(
        '  appkey: ${appkey != null ? '${appkey.substring(0, 20)}...' : 'NULL'}');

    print('\nDevice Repository Required Keys:');
    final secret = prefs.getString('Secret');
    print(
        '  Secret: ${secret != null ? '${secret.substring(0, 20)}...' : 'NULL'}');

    print('\nAuth Status:');
    final loggedIn = prefs.getBool('loggedin');
    print('  loggedin: $loggedIn');

    if (token == null || username == null || appkey == null) {
      print('\n❌ Alarm Repository missing credentials');
      print('   Solutions:');
      print('   1. Log out and log back in to refresh credentials');
      print('   2. Or manually set the appkey in auth repository');
    } else {
      print('\n✅ Alarm Repository has all required credentials');
    }
  } catch (e) {
    print('Error checking credentials: $e');
  }
}
