import 'package:dio/dio.dart';
import '../../models/account/account_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:simple_rc4/simple_rc4.dart';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

class AccountRepository {
  // final ApiService _apiService;
  // AccountRepository(this._apiService);

  Future<AccountInfo?> fetchAccountInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const salt = '12345678';
    const action = '&action=queryAccountInfo';
    // You may need to add app version/platform logic if required by backend
    final postaction = '';
    final data = salt + secret + token + action + postaction;
    final sign = _sha1(data);
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    try {
      final response = await Dio().post(url);
      if (response.statusCode == 200 && response.data['err'] == 0) {
        return AccountInfo.fromJson(response.data['dat']);
      }
    } catch (e) {
      print('Error fetching account info: $e');
    }
    return null;
  }

  String _sha1(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString('Secret') ?? '';
    const salt = '12345678';

    print('=== Password Change Debug ===');
    print('Secret: $secret');

    // Build postaction metadata like the old app: source/app/version/platform
    String postaction = '';
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      const source = '1';
      postaction =
          '&source=$source&app_id=${info.packageName}&app_version=${info.version}&app_client=$platform';
    } catch (e) {
      // Fallback: no postaction if package info unavailable
      postaction = '';
    }

    print('Postaction: $postaction');

    // Hash old password
    var oldpass = utf8.encode(oldPassword);
    var sha1_conv_oldpass = sha1.convert(oldpass).toString();
    print('Old password SHA1: $sha1_conv_oldpass');

    // Hash new password
    var newpass = utf8.encode(newPassword);
    var sha1_conv_newpass = sha1.convert(newpass).toString();
    print('New password SHA1: $sha1_conv_newpass');

    // RC4 encode new password with old password hash
    var rc4 = RC4.fromBytes(utf8.encode(sha1_conv_oldpass));
    var rc4encoded = rc4.encodeBytes(utf8.encode(sha1_conv_newpass));
    var sha1newpass = hex.encode(rc4encoded);
    print('RC4 encoded password: $sha1newpass');

    // Build action and URL - NOTE: old app does NOT include token in sign calculation for password change!
    String action = "&action=updatePassword&newpwd=" + sha1newpass;
    print('Action: $action');

    // Sign calculation: salt + secret + action + postaction (NO TOKEN like old app!)
    var data = salt + secret + action + postaction;
    print('Sign data: $data');

    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    print('Sign: $sign');

    // URL does NOT include token parameter for password change
    String url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt' +
        action +
        postaction;
    print('URL: $url');
    try {
      final response = await Dio().post(url);
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final err = response.data['err'];
        final desc = response.data['desc']?.toString();
        print('Error code: $err');
        print('Description: $desc');

        if (err == 0) {
          return {'success': true, 'message': 'Password changed successfully'};
        } else {
          return {
            'success': false,
            'message': desc ?? 'Password change failed'
          };
        }
      }
      // Log backend description when available for easier diagnostics
      try {
        final desc = response.data?['desc']?.toString();
        if (desc != null) {
          print('ChangePassword failed: $desc');
        } else {
          print(
              'ChangePassword failed: HTTP ${response.statusCode}, body=${response.data}');
        }
      } catch (_) {}
    } catch (e) {
      print('Error changing password: $e');
    }
    return {'success': false, 'message': 'Network error'};
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = {"Email": email};

      // Use PushShortCode endpoint like the old working app
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/PushShortCode',
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      print(
          'forgotPassword response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        // Old app treats 200 as success
        return true;
      }

      print('forgotPassword: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error in forgotPassword: $e');
      return false;
    }
  }

  Future<String?> forgotUserId(String email) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/GetUserID',
        data: {"Email": email},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
        }),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (e) {
      print('Error in forgotUserId: $e');
    }
    return null;
  }

  /// Updates password for a specific user (forgot password flow)
  /// Matches old app: POST MonitoringApp/UpdatePassword with { UserID, Password }
  Future<bool> updatePasswordForUserId(int userId, String password) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/UpdatePassword',
        data: {"UserID": userId, "Password": password},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final code = data is Map<String, dynamic>
            ? data['ResponseCode']?.toString()
            : null;
        return code == '00';
      }
      return false;
    } catch (e) {
      print('Error in updatePasswordForUserId: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobileNo,
    required String username,
    required String password,
    required String sn,
  }) async {
    try {
      print('Registration attempt for email: $email');
      // Normalize SN similar to legacy expectations
      final normalizedSn = sn.trim().toUpperCase();
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/Register',
        data: {
          "Name": name, // User's full name
          "Email": email,
          "MobileNo": mobileNo,
          "Username": username,
          "Password": password,
          "SN": normalizedSn,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final code = data is Map<String, dynamic>
            ? data['ResponseCode']?.toString()
            : null;
        final description = data is Map<String, dynamic>
            ? data['Description']?.toString()
            : null;
        print('Registration description: $description, code: $code');
        final ok = code == '00' ||
            description == 'Success' ||
            (description?.toLowerCase().contains('success') ?? false);
        if (ok) {
          return {'success': true, 'message': 'Registration successful'};
        }
        return {
          'success': false,
          'message': description ?? 'Registration failed'
        };
      }
      return {
        'success': false,
        'message': 'Server error (${response.statusCode})'
      };
    } catch (e) {
      print('Error in register: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/VerifyShortCode',
        data: {"Email": email, "ShortCode": code},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      print('verifyOtp response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        // Old app treats 200 as success without checking ResponseCode
        return true;
      }

      return false;
    } catch (e) {
      print('Error in verifyOtp: $e');
      return false;
    }
  }

  /// Adds/links an installer (agent) to the current user via Crown Micro API.
  ///
  /// Legacy reference: newtemp/lib/pages/user.dart -> UpdateAgentCode
  /// Returns true if backend accepts the code; false otherwise.
  Future<bool> addInstallerCode(String agentCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('UserID');
      if (userIdStr == null || userIdStr.isEmpty) {
        print('addInstallerCode: No UserID found in storage');
        return false;
      }

      final url =
          'https://apis.crown-micro.net/api/MonitoringApp/UpdateAgentCode';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = {
        'UserID': int.parse(userIdStr),
        'AgentCode': agentCode.trim(),
      };

      final response = await Dio().post(
        url,
        data: body,
        options: Options(
            headers: headers, validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode == 200) {
        // Some environments return { ResponseCode: "00", Description: "Success" }
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final rc = data['ResponseCode']?.toString();
          final desc = data['Description']?.toString().toLowerCase();
          if (rc == '00' ||
              (desc != null &&
                  (desc.contains('success') || desc.contains('added')))) {
            return true;
          }
        }
        // Fallback: treat 200 as success like legacy app did
        return true;
      }
      print(
          'addInstallerCode failed: HTTP ${response.statusCode}, data=${response.data}');
      return false;
    } catch (e) {
      print('Error in addInstallerCode: $e');
      return false;
    }
  }

  /// Attempts to delete/deactivate the current user's account using Crown Micro API.
  /// Tries known endpoint candidates and returns true on success.
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('UserID');
      final token = prefs.getString('token');

      print('====== DELETE ACCOUNT DEBUG ======');
      print('UserID from storage: $userIdStr');
      print('Token available: ${token != null && token.isNotEmpty}');

      if (userIdStr == null || userIdStr.isEmpty) {
        print('deleteAccount: No UserID found in storage');
        return {'success': false, 'message': 'No user id in session'};
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Parse UserID - try as int first, fallback to string if parse fails
      dynamic userId;
      try {
        userId = int.parse(userIdStr);
        print('Parsed UserID as int: $userId');
      } catch (e) {
        userId = userIdStr; // Keep as string if not a valid integer
        print('Using UserID as string: $userId');
      }

      final body = {
        'UserID': userId,
      };

      print('Request body: $body');
      print('Request headers: ${headers.keys.toList()}');

      // Try DeactivateAccount first (old app uses this), then DeleteAccount as fallback
      final endpoints = <String>[
        'https://apis.crown-micro.net/api/MonitoringApp/DeactivateAccount',
        'https://apis.crown-micro.net/api/MonitoringApp/DeleteAccount',
      ];

      for (final url in endpoints) {
        try {
          print('Attempting endpoint: $url');

          final resp = await Dio().post(
            url,
            data: body,
            options: Options(
              headers: headers,
              validateStatus: (s) => s != null && s < 500,
            ),
          );

          print('Response status: ${resp.statusCode}');
          print('Response data: ${resp.data}');
          print('Response type: ${resp.data.runtimeType}');

          if (resp.statusCode == 200) {
            final data = resp.data;

            // Old app behavior: if we get 200, consider it success
            // This matches the old working app which doesn't check response body
            print('Got 200 response - treating as success (old app behavior)');
            return {'success': true, 'message': 'Account deleted successfully'};
          } else if (resp.statusCode == 404) {
            // Endpoint not found; try next candidate
            print('Endpoint not found (404), trying next...');
            continue;
          } else if (resp.statusCode == 400) {
            print('Bad request (400) - may indicate invalid UserID format');
            final msg = resp.data is Map<String, dynamic>
                ? (resp.data['Description']?.toString() ??
                    resp.data['message']?.toString() ??
                    'Invalid request')
                : 'Bad request';
            return {'success': false, 'message': msg};
          } else {
            print('deleteAccount: HTTP ${resp.statusCode} from $url');
            return {
              'success': false,
              'message': 'Server error: ${resp.statusCode}'
            };
          }
        } catch (e, stackTrace) {
          print('deleteAccount: Error calling $url -> $e');
          print('Stack trace: $stackTrace');
          // Continue to next endpoint
        }
      }

      print('All endpoints tried, none succeeded');
      return {'success': false, 'message': 'Delete endpoint not available'};
    } catch (e, stackTrace) {
      print('deleteAccount: Outer error -> $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('====== DELETE ACCOUNT END ======');
    }
  }
}
