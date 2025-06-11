// To parse this JSON data, do
//
//     final deviceEnergyDay = deviceEnergyDayFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

DeviceEnergyDay deviceEnergyDayFromJson(String str) =>
    DeviceEnergyDay.fromJson(json.decode(str));

String deviceEnergyDayToJson(DeviceEnergyDay data) =>
    json.encode(data.toJson());

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DeviceActiveOuputPowerMonthQuery(
    {required String Date,
    required String PN,
    required String SN,
    required String devcode,
    required String devaddr}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";

  ///date format YYYY-MM

  ////power generation of all power sations on current date
  ///
  String action;
  
   //old
  // action =
  //     "&action=queryDeviceEnergyMonthPerDay&pn=$PN&devcode=$devcode&devaddr=$devaddr&sn=$SN&date=$Date"; 

  //new
    
  action =
      "&action=querySPDeviceKeyParameterMonthPerDay&i18n=en_US&parameter=ENERGY_TODAY&pn=$PN&devcode=$devcode&devaddr=$devaddr&sn=$SN&date=$Date"; 

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
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  print('DeviceActiveOuputPowerMonth URL: $url');
  //var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DeviceActiveOuputPowerMonth Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'DeviceActiveOuputPowerMonth APIrequest response : ${jsonResponse}');
      print(
          'DeviceActiveOuputPowerMonth APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

class DeviceEnergyDay {
  DeviceEnergyDay({
    this.err,
    this.desc,
    this.dat,
  });

  int? err;
  String? desc;
  Dat? dat;

  factory DeviceEnergyDay.fromJson(Map<String, dynamic> json) =>
      DeviceEnergyDay(
        err: json["err"] == null ? null : json["err"],
        desc: json["desc"] == null ? null : json["desc"],
        dat: json["dat"] == null ? null : Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err == null ? null : err,
        "desc": desc == null ? null : desc,
        "dat": dat == null ? null : dat?.toJson(),
      };
}

class Dat {
  Dat({
    this.option,
  });

  List<Perday>? option;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        option: json["option"] == null
            ? null
            : List<Perday>.from(json["option"].map((x) => Perday.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "option": option == null
            ? null
            : List<dynamic>.from(option!.map((x) => x.toJson())),
      };
}

class Perday {
  Perday({
    this.val,
    this.gts,
  });

  String? val;
  DateTime? gts;

  factory Perday.fromJson(Map<String, dynamic> json) => Perday(
        val: json["val"] == null ? null : json["val"],
        gts: json["gts"] == null ? null : DateTime.parse(json["gts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "gts": gts == null ? null : gts?.toIso8601String(),
      };
}
