import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

DailyPGinMonth dailyPGinMonthFromJson(String str) =>
    DailyPGinMonth.fromJson(json.decode(str));
String dailyPGinMonthToJson(DailyPGinMonth data) => json.encode(data.toJson());

//////////////////////////////////////** Daily PowerGeneration in a month Queries *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DailyPGinMonthQuery(
    {required String yearmonth, required String PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  if (PID == 'all') {
    action = "&action=queryPlantsEnergyMonthPerDay&date=$yearmonth";
  } else {
    action = "&action=queryPlantEnergyMonthPerDay&plantid=$PID&date=$yearmonth";
  }
  //print('action: $action');
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
          action +
          postaction;
  print('DailyPGinMonth URL:  $url');
  // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('DailyPGinMonth Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('DailyPGinMonth APIrequest response : ${jsonResponse}');
      print('DailyPGinMonth APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> DailyPGinMonthQuery2({
  required String yearmonth,
  required String PID,
  required String PN,
  required String SN,
  required String devcode,
  required String devaddr,
  required String parameter,
}) async {
  var jsonResponse;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('Token: $token');
  print('Secret: $Secret');
  String salt = "12345678";

  // Determine the action based on the parameters
  String action;
  // if (PID == 'all') {
  //   action = "&action=querySPDeviceKeyParameterMonthPerDay"
  //       "&source=1"
  //       "&pn=$PN"
  //       "&sn=$SN"
  //       "&devcode=$devcode"
  //       "&devaddr=$devaddr"
  //       "&i18n=en_US"
  //       "&parameter=$parameter"
  //       "&chartStatus=false"
  //       "&date=$yearmonth";
  // } else {
  action = "&action=querySPDeviceKeyParameterMonthPerDay"
      "&source=1"
      "&pn=$PN"
      "&sn=$SN"
      "&devcode=$devcode"
      "&devaddr=$devaddr"
      "&i18n=en_US"
      "&parameter=$parameter"
      "&chartStatus=false"
      "&date=$yearmonth";

  // App and platform information
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";

  // Generate the sign
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();

  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token' +
          action +
          postaction;
  print('DailyPGinMonth URL:  $url');

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('DailyPGinMonth Query Response Success! No Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('DailyPGinMonth API Response: ${jsonResponse}');
      print('DailyPGinMonth API Status Code: ${response.statusCode}');
    });
  } catch (e) {
    print('Error: ${e.toString()}');
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Daily PowerGeneration in a month Queries  *//////END///////////////////////////

class DailyPGinMonth {
  DailyPGinMonth({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory DailyPGinMonth.fromJson(Map<String, dynamic> json) => DailyPGinMonth(
        err: json["err"] == null ? null : json["err"],
        desc: json["desc"] == null ? null : json["desc"],
        dat: json["dat"] == null ? null : Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err == null ? null : err,
        "desc": desc == null ? null : desc,
        "dat": dat == null ? null : dat!.toJson(),
      };
}

class Dat {
  Dat({
    this.perday,
  });

  final List<Perday>? perday;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        perday: json["perday"] == null
            ? null
            : List<Perday>.from(json["perday"].map((x) => Perday.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "perday": perday == null
            ? null
            : List<dynamic>.from(perday!.map((x) => x.toJson())),
      };
}

class Perday {
  Perday({
    this.val,
    this.ts,
  });

  final String? val;
  final DateTime? ts;

  factory Perday.fromJson(Map<String, dynamic> json) => Perday(
        val: json["val"] == null ? null : json["val"],
        ts: json["ts"] == null ? null : DateTime.parse(json["ts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "ts": ts == null ? null : ts!.toIso8601String(),
      };
}
