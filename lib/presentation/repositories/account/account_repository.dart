import 'package:dio/dio.dart';
import '../../models/account/account_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:simple_rc4/simple_rc4.dart';

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

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString('Secret') ?? '';
    const salt = '12345678';
    // Hash old password
    var oldpass = utf8.encode(oldPassword);
    var sha1_conv_oldpass = sha1.convert(oldpass).toString();
    // Hash new password
    var newpass = utf8.encode(newPassword);
    var sha1_conv_newpass = sha1.convert(newpass).toString();
    // RC4 encode new password with old password hash
    var rc4 = RC4.fromBytes(utf8.encode(sha1_conv_oldpass));
    var rc4encoded = rc4.encodeBytes(utf8.encode(sha1_conv_newpass));
    var sha1newpass = hex.encode(rc4encoded);
    // Build action and URL
    String action = "&action=updatePassword&newpwd=" + sha1newpass;
    String postaction = '';
    var data = salt + secret + action + postaction;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    String url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt' +
        action +
        postaction;
    try {
      final response = await Dio().post(url);
      if (response.statusCode == 200 && response.data['err'] == 0) {
        return true;
      }
    } catch (e) {
      print('Error changing password: $e');
    }
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/ForgotPassword',
        data: {"Email": email},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 &&
          response.data['ResponseCode'] == "00";
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
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (e) {
      print('Error in forgotUserId: $e');
    }
    return null;
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/Register',
        data: {"Email": email, "Password": password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 &&
          response.data['ResponseCode'] == "00";
    } catch (e) {
      print('Error in register: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    try {
      final response = await Dio().post(
        'https://apis.crown-micro.net/api/MonitoringApp/VerifyShortCode',
        data: {"Email": email, "ShortCode": code},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 &&
          response.data['ResponseCode'] == "00";
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
  Future<bool> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('UserID');
      if (userIdStr == null || userIdStr.isEmpty) {
        print('deleteAccount: No UserID found in storage');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C',
      };
      final body = {
        'UserID': int.parse(userIdStr),
      };

      // Try DeleteAccount first, then DeactivateAccount as fallback
      final endpoints = <String>[
        'https://apis.crown-micro.net/api/MonitoringApp/DeleteAccount',
        'https://apis.crown-micro.net/api/MonitoringApp/DeactivateAccount',
      ];

      for (final url in endpoints) {
        try {
          final resp = await Dio().post(
            url,
            data: body,
            options: Options(
              headers: headers,
              validateStatus: (s) => s != null && s < 500,
            ),
          );
          if (resp.statusCode == 200) {
            final data = resp.data;
            if (data is Map<String, dynamic>) {
              final rc = data['ResponseCode']?.toString();
              final desc = data['Description']?.toString().toLowerCase();
              if (rc == '00' ||
                  (desc != null &&
                      (desc.contains('success') ||
                          desc.contains('deleted') ||
                          desc.contains('deactivated')))) {
                return true;
              }
            }
            // If 200 but unexpected payload, treat as failure and try next
            print(
                'deleteAccount: 200 but unexpected payload from $url: ${resp.data}');
          } else if (resp.statusCode == 404) {
            // Endpoint not found; try next candidate
            continue;
          } else {
            print('deleteAccount: HTTP ${resp.statusCode} from $url');
          }
        } catch (e) {
          print('deleteAccount: Error calling $url -> $e');
        }
      }

      return false;
    } catch (e) {
      print('Error in deleteAccount: $e');
      return false;
    }
  }
}
