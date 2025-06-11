import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

MonthlyPGinyear monthlyPGinyearFromJson(String str) =>
    MonthlyPGinyear.fromJson(json.decode(str));
String monthlyPGinyearToJson(MonthlyPGinyear data) =>
    json.encode(data.toJson());

//////////////////////////////////////** Montly PowerGeneration in a year Queries *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> MonthlyPGinyearQuery(
    {required String year, required String PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  if (PID == 'all') {
    action = "&action=queryPlantsEnergyYearPerMonth&date=$year";
  } else {
    action = "&action=queryPlantEnergyYearPerMonth&plantid=$PID&date=$year";
  }

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
          action +
          postaction;
  print('MonthlyPGinyear URL:  $url');
//  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('MonthlyPGinyear Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('MonthlyPGinyear APIrequest response : ${jsonResponse}');
      print('MonthlyPGinyear APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> MonthlyPGinyearQuery2({
  required String date,
  required String PN,
  required String SN,
  required String devaddr,
  required String devcode,
  required String parameter,
}) async {
  var jsonResponse;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String action =
      "&action=querySPDeviceKeyParameterYearPerMonth&source=$Source&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false&date=$date";

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();

  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;

  print('MonthlyPGinyearQuery2 URL: $url');

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('MonthlyPGinyear Query Response Success!! No Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('MonthlyPGinyear API request response: $jsonResponse');
      print('MonthlyPGinyear API request status code: ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Montly PowerGeneration in a year Queries  *//////END///////////////////////////

class MonthlyPGinyear {
  MonthlyPGinyear({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory MonthlyPGinyear.fromJson(Map<String, dynamic> json) =>
      MonthlyPGinyear(
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
    this.permonth,
  });

  final List<Permonth>? permonth;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        permonth: json["permonth"] == null
            ? null
            : List<Permonth>.from(
                json["permonth"].map((x) => Permonth.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "permonth": permonth == null
            ? null
            : List<dynamic>.from(permonth!.map((x) => x.toJson())),
      };
}

class Permonth {
  Permonth({
    this.val,
    this.ts,
  });

  final String? val;
  final DateTime? ts;

  factory Permonth.fromJson(Map<String, dynamic> json) => Permonth(
        val: json["val"] == null ? null : json["val"],
        ts: json["ts"] == null ? null : DateTime.parse(json["ts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "ts": ts == null ? null : ts!.toIso8601String(),
      };
}
