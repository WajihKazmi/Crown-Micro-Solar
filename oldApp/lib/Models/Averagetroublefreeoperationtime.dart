import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// To parse this JSON data, do
//
//     final averagetroublefreeoperationtime = averagetroublefreeoperationtimeFromJson(jsonString);

import 'dart:convert';

Averagetroublefreeoperationtime averagetroublefreeoperationtimeFromJson(
        String str) =>
    Averagetroublefreeoperationtime.fromJson(json.decode(str));
String averagetroublefreeoperationtimeToJson(
        Averagetroublefreeoperationtime data) =>
    json.encode(data.toJson());

/////////////////////////////////////** Average Trouble free operation time of power station  REquest  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> AveragetroublefreeoperationtimeQuery(
    {required int PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';

  String salt = "12345678";
  String action =
      "&action=queryPlantRunningNormalTimeAvg&plantid=" + PID.toString();
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
          action +postaction;
  print('AveragetroublefreeoperationTime $url');
 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'AveragetroublefreeoperationTime Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'AveragetroublefreeoperationTime APIrequest response : ${jsonResponse}');
      print(
          'AveragetroublefreeoperationTime APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Average Trouble free operation time of power station Queries  *//////END///////////////////////

class Averagetroublefreeoperationtime {
  Averagetroublefreeoperationtime({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory Averagetroublefreeoperationtime.fromJson(Map<String, dynamic> json) =>
      Averagetroublefreeoperationtime(
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
    this.minutes,
  });

  final int? minutes;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        minutes: json["minutes"] == null ? null : json["minutes"],
      );

  Map<String, dynamic> toJson() => {
        "minutes": minutes == null ? null : minutes,
      };
}
