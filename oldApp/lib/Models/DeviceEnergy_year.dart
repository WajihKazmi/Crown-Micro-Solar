// To parse this JSON data, do
//
//     final deviceEnergyYear = deviceEnergyYearFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

DeviceEnergyYear deviceEnergyYearFromJson(String str) =>
    DeviceEnergyYear.fromJson(json.decode(str));

String deviceEnergyYearToJson(DeviceEnergyYear data) =>
    json.encode(data.toJson());

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DeviceActiveOuputPowerTotalQuery(
    {required String PN,
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

  ////power generation of all power sations on current date
  ///
  String action;
   //old
  // action =
  //     "&action=queryDeviceEnergyTotalPerYear&pn=$PN&devcode=$devcode&devaddr=$devaddr&sn=$SN";

  //new
   action =
      "&action=querySPDeviceKeyParameterTotalPerYear&pn=$PN&devcode=$devcode&devaddr=$devaddr&sn=$SN&parameter=ENERGY_TOTAL";
 
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
  print('DeviceActiveOuputPowerTotal URL: $url');
  //var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DeviceActiveOuputPowerTotal Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'DeviceActiveOuputPowerTotal APIrequest response : ${jsonResponse}');
      print(
          'DeviceActiveOuputPowerTotal APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

class DeviceEnergyYear {
  DeviceEnergyYear({
    this.err,
    this.desc,
    this.dat,
  });

  int? err;
  String? desc;
  Dat? dat;

  factory DeviceEnergyYear.fromJson(Map<String, dynamic> json) =>
      DeviceEnergyYear(
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

  List<Peryear>? option;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        option: json["option"] == null
            ? null
            : List<Peryear>.from(
                json["option"].map((x) => Peryear.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "option": option == null
            ? null
            : List<dynamic>.from(option!.map((x) => x.toJson())),
      };
}

class Peryear {
  Peryear({
    this.val,
    this.gts,
  });

  String? val;
  String? gts;

  factory Peryear.fromJson(Map<String, dynamic> json) => Peryear(
        val: json["val"] == null ? null : json["val"],
        gts: json["gts"] == null ? null : json["gts"],
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "ts": gts == null ? null : gts,
      };
}
