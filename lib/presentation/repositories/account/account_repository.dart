import 'package:dio/dio.dart';
import '../../models/account/account_info_model.dart';
import '../../../core/network/api_service.dart';
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
    final url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
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
    final token = prefs.getString('token') ?? '';
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
    String url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt' + action + postaction;
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
      return response.statusCode == 200 && response.data['ResponseCode'] == "00";
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
      return response.statusCode == 200 && response.data['ResponseCode'] == "00";
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
      return response.statusCode == 200 && response.data['ResponseCode'] == "00";
    } catch (e) {
      print('Error in verifyOtp: $e');
      return false;
    }
  }
} 