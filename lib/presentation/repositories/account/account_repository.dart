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
      final response = await Dio().post(
        url,
        options: Options(
          // Old app posts query-only; force a permissive content-type
          contentType: 'application/x-www-form-urlencoded',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
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
    // Crown Monitor flow only: MonitoringApp/UpdatePassword using stored UserID
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('UserID');
      if (userIdStr == null || userIdStr.isEmpty) {
        return {
          'success': false,
          'message': 'Session expired. Please log in again.'
        };
      }
      final id = int.tryParse(userIdStr);
      if (id == null) {
        return {
          'success': false,
          'message': 'Invalid session user id. Please re-login.'
        };
      }

      // Call Crown API directly
      final ok = await updatePasswordForUserId(id, newPassword);
      if (ok) {
        return {'success': true, 'message': 'Password changed successfully'};
      }
      return {
        'success': false,
        'message': 'Password change failed. Please try again.'
      };
    } catch (e) {
      print('ChangePassword Crown API error: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.'
      };
    }
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

  /// Delete account identical to old app behavior:
  /// - POST only to MonitoringApp/DeactivateAccount
  /// - Headers: Content-Type + x-api-key (NO Authorization header)
  /// - Body: { "UserID": value from SharedPreferences 'UserID' (unmodified) }
  /// - Treat any HTTP response as success; only network exceptions return failure
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.get('UserID'); // keep exact stored type

      print('====== DELETE ACCOUNT (IDENTICAL) ======');
      print('UserID raw from storage: $userId');

      if (userId == null) {
        return {'success': false, 'message': 'No user id in session'};
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };

      final body = {
        'UserID': userId,
      };

      final url =
          'https://apis.crown-micro.net/api/MonitoringApp/DeactivateAccount';
      print('POST $url');
      print('Headers: ${headers.keys.toList()}');
      print('Body: $body');

      // Do not validate status beyond non-500 to mirror old app's fire-and-forget
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

      // Old app: on any response, navigate to login; we return success regardless of code
      return {'success': true, 'message': 'Account deleted successfully'};
    } catch (e) {
      print('deleteAccount (identical) error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('====== DELETE ACCOUNT END ======');
    }
  }
}
