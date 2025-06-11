import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

DeviceEnergyCurrMonDayYear deviceEnergyCurrMonDayYearFromJson(String str) =>
    DeviceEnergyCurrMonDayYear.fromJson(json.decode(str));

String deviceEnergyCurrMonDayYearToJson(DeviceEnergyCurrMonDayYear data) =>
    json.encode(data.toJson());

//////////////////////////////////////**DeviceActiveOuputPowerOneDay REquest   *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DeviceActiveOuputPowerOneDayQuery({
  required String Date,
  required String PN,
  required String SN,
  required String devcode,
  required String devaddr,
  required String parameter,
  // required String plantId,
}) async {
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
  //old
  // action =
  //     "&action=queryDeviceActiveOuputPowerOneDay&pn=$PN&devcode=$devcode&devaddr=$devaddr&sn=$SN&date=$Date";

  //new
  action =
      "&action=querySPDeviceKeyParameterOneDay&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false&&date=$Date";
  // action =
  //     "&action=querySPDeviceKeyParameterOneDay&pn=W0025105062971&sn=96142208600425&devcode=2452&devaddr=1&i18n=en_US&parameter=PV_OUTPUT_POWER&chartStatus=false&date=2025-03-25";
//
  // action =
  //     "&action=queryPlantActiveOuputPowerOneDay&plantid=$plantId&date=$Date";

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
  print('DeviceActiveOuputPowerOneDay URL: $url');
  //var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DeviceActiveOuputPowerOneDay Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'DeviceActiveOuputPowerOneDay APIrequest response : ${jsonResponse}');
      print(
          'DeviceActiveOuputPowerOneDay APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** DeviceActiveOuputPowerOneDay REquest   *//////END///////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

class DeviceEnergyCurrMonDayYear {
  DeviceEnergyCurrMonDayYear({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory DeviceEnergyCurrMonDayYear.fromJson(Map<String, dynamic> json) =>
      DeviceEnergyCurrMonDayYear(
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
    this.detail,
  });

  final List<OutputPower>? detail;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        detail: json["detail"] == null
            ? null
            : List<OutputPower>.from(
                json["detail"].map((x) => OutputPower.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "detail": detail == null
            ? null
            : List<dynamic>.from(detail!.map((x) => x.toJson())),
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
