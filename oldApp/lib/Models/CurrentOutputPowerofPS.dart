// To parse this JSON data, do
//
//     final currentOutputPowerofPs = currentOutputPowerofPsFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

//////////////////////////////////////** Total Output Power of Powerstation Queries  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> TotalOuputPowerofPSQuery({required int PID}) async {
  double Totaloutputpower = 0;
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  // print('token: $token');
  // print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantEnergyTotal&plantid=" + PID.toString();
  //print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  print('Total output power URL: $url');
  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Total output power Response Success!! no Error');
          Totaloutputpower = double.parse(jsonResponse['dat']['energy']);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('Total output power APIrequest response : ${jsonResponse}');
      print('Total output power APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return Totaloutputpower.toStringAsFixed(2);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Total Output Power of Powerstation Queries  *//////END///////////////////////////

//////////////////////////////////////** Total Output Power of ALL Powerstation Queries  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> TotalOuputPowerof_ALLPSQuery() async {
  double Totaloutputpower = 0;
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  // print('token: $token');
  // print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantsEnergyTotal";
  //print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  //print('Total output powerOF ALL URL: $url');
  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Total output power of ALL PS Response Success!! no Error');
          Totaloutputpower = double.parse(jsonResponse['dat']['energy']);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'Total output power of ALL PS APIrequest response : ${jsonResponse}');
      print(
          'Total output power of ALL PS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return Totaloutputpower.toStringAsFixed(2);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Total Output Power of ALL Powerstation Queries  *//////END///////////////////////////

//////////////////////////////////////** Current Output Power of ALL Powerstation Queries  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> CurrentOuputPowerof_ALLPSQuery() async {
  double Currentoutputpower_ALLPS = 0;
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  // print('token: $token');
  // print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantsActiveOuputPowerCurrent";

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////
  
  
  //print('action: $action');
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  //print('Total output powerOF ALL URL: $url');
 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Current Output Power of ALL PS Response Success!! no Error');
          Currentoutputpower_ALLPS =
              double.parse(jsonResponse['dat']['outputPower']);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'Current Output Power of ALL PS APIrequest response : ${jsonResponse}');
      print(
          'Current Output Power of ALL PS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return Currentoutputpower_ALLPS.toStringAsFixed(2);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Current Output Power of ALL Powerstation Queries  *//////END///////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Current Output Power of Powerstation Queries  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> CurrentActivePowerofPSQuery({required int PID}) async {
  String Currentoutputpower = '0';

  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=queryPlantActiveOuputPowerCurrent&plantid=" + PID.toString() ;
      ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////

  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  print('Current output power URL: $url');
 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('CurrentActivePowerofPS Response Success!! no Error');
          Currentoutputpower = jsonResponse['dat']['outputPower'];
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('CurrentActivePowerofPS APIrequest response : ${jsonResponse}');
      print(
          'CurrentActivePowerofPS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return Currentoutputpower;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Current Output Power of Powerstation Queries  *//////END///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////** installed capacity (design power) of all power plants Queries   *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> InstalledCapacity_ALLPSQuery() async {
  double installedcapacity_all = 0;
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  // print('token: $token');
  // print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantsNominalPower";

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////
  
  //print('action: $action');
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  //print('Total output powerOF ALL URL: $url');
//  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(' installed capacity of ALL PS Response Success!! no Error');
          installedcapacity_all =
              double.parse(jsonResponse['dat']['nominalPower']);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          ' installed capacity of ALL PS APIrequest response : ${jsonResponse}');
      print(
          ' installed capacity of ALL PS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return installedcapacity_all.toStringAsFixed(2);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** installed capacity (design power) of all power plants Queries  *//////END///////////////////////////

//////////////////////////////////////** power generation of the power station on a certain day Queries  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<String> PowerGenerationTodayQuery({required int PID}) async {
  double powergenerated_today = 0;
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  // print('token: $token');
  // print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantEnergyDay&plantid=" + PID.toString();
  //print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  //print('Power Generation Today URL: $url');
  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Power Generation Today Response Success!! no Error');
          powergenerated_today = double.parse(jsonResponse['dat']['energy']);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('Power Generation Today APIrequest response : ${jsonResponse}');
      print(
          'Power Generation Today APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return powergenerated_today.toStringAsFixed(2);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** power generation of the power station on a certain day Queries  *//////END///////////////////////////
