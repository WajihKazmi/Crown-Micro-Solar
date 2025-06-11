// To parse this JSON data, do
//
//     final activeOuputPowerOneDay = activeOuputPowerOneDayFromJson(jsonString);
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

ActiveOuputPowerOneDay activeOuputPowerOneDayFromJson(String str) =>
    ActiveOuputPowerOneDay.fromJson(json.decode(str));
String activeOuputPowerOneDayToJson(ActiveOuputPowerOneDay data) =>
    json.encode(data.toJson());

//////////////////////////////////////**ActiveOuputPowerOneDay REquest   *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> ActiveOuputPowerOneDayQuery(
    {required String Date, required String PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";

  ///date format YYYY-MM-DD

  ////power generation of all power sations on current date
  ///
  String action;
  // if (PID == 'all') {
  //   action = "&action=queryPlantsActiveOuputPowerOneDay&date=$Date&lang=zh_CN";
  // } else {
  //   action =
  //       "&action=queryPlantActiveOuputPowerOneDay&plantid=$PID&date=$Date"; //Ref # 1.4.17 in docs
  // }
  action = "&action=queryPlantsActiveOuputPowerOneDay&date=$Date";
  // action = "&action=queryPlantActiveOuputPowerOneDay&plantid=$PID&date=$Date";

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
  print('URL: $url');
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('ActiveOuputPowerOneDay Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** ActiveOuputPowerOneDay REquest   *//////END///////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

class ActiveOuputPowerOneDay {
  ActiveOuputPowerOneDay({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory ActiveOuputPowerOneDay.fromJson(Map<String, dynamic> json) =>
      ActiveOuputPowerOneDay(
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
    this.outputPower,
    this.activePowerSwitch,
  });

  final List<OutputPower>? outputPower;
  final bool? activePowerSwitch;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        outputPower: json["outputPower"] == null
            ? null
            : List<OutputPower>.from(
                json["outputPower"].map((x) => OutputPower.fromJson(x))),
        activePowerSwitch: json["activePowerSwitch"] == null
            ? null
            : json["activePowerSwitch"],
      );

  Map<String, dynamic> toJson() => {
        "outputPower": outputPower == null
            ? null
            : List<dynamic>.from(outputPower!.map((x) => x.toJson())),
        "activePowerSwitch":
            activePowerSwitch == null ? null : activePowerSwitch,
      };
}

class OutputPower {
  OutputPower({
    this.val,
    this.ts,
  });

  final String? val;
  final DateTime? ts;

  factory OutputPower.fromJson(Map<String, dynamic> json) => OutputPower(
        val: json["val"] == null ? null : json["val"],
        ts: json["ts"] == null ? null : DateTime.parse(json["ts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "ts": ts == null ? null : ts?.toIso8601String(),
      };
}
