
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

QueryDeviceCount queryDeviceCountFromJson(String str) => QueryDeviceCount.fromJson(json.decode(str));
String queryDeviceCountToJson(QueryDeviceCount data) => json.encode(data.toJson());

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////**  Query DeviceCount REquest  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DeviceCountQuery() async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryDeviceCount";

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction = "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////
  
  //print('action: $action');
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' + action +postaction;
  //print(url);
//  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) async {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);

        if (jsonResponse['desc'] == 'ERR_NO_AUTH') {
          return jsonResponse['desc'];
        }

        if (jsonResponse['err'] == 0) {
          print('DeviceCount Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('DeviceCountAPIrequest response : ${jsonResponse}');
      print('APIrequest statucode : ${response.statusCode}');
    });
    return jsonResponse;
  } catch (e) {
    print(e.toString());
    return {"error": "404"};
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query DeviceCount REquest   *//////END///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

class QueryDeviceCount {
  QueryDeviceCount({
    required this.err,
    required this.desc,
    required this.dat,
  });

  int err;
  String desc;
  Dat dat;

  factory QueryDeviceCount.fromJson(Map<String, dynamic> json) =>
      QueryDeviceCount(
        err: json["err"] == null ? null : json["err"],
        desc: json["desc"] == null ? null : json["desc"],
        dat: Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err == null ? null : err,
        "desc": desc == null ? null : desc,
        "dat": dat == null ? null : dat.toJson(),
      };
}

class Dat {
  Dat({
    required this.count,
  });

  int count;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        count: json["count"] == null ? null : json["count"],
      );

  Map<String, dynamic> toJson() => {
        "count": count == null ? null : count,
      };
}
