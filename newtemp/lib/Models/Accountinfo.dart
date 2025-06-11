// To parse this JSON data, do
//
//     final accountinfo = accountinfoFromJson(jsonString);

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Accountinfo accountinfoFromJson(String str) =>
    Accountinfo.fromJson(json.decode(str));
String accountinfoToJson(Accountinfo data) => json.encode(data.toJson());

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Queries REquest  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> AccountInfoQuery() async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryAccountInfo";

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
  //print(url);
 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Accountinfo Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('APIrequest response : ${jsonResponse}');
      print('APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Queries  *//////END///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Accountinfo {
  Accountinfo({
    required this.err,
    required this.desc,
    required this.dat,
  });

  int err;
  String desc;
  Dat dat;

  factory Accountinfo.fromJson(Map<String, dynamic> json) => Accountinfo(
        err: json["err"] == null ? '00000' : json["err"],
        desc: json["desc"] == null ? 'not available' : json["desc"],
        dat: Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err == null ? null : err,
        "desc": desc == null ? null : desc,
        "dat": dat == null ? null : dat.toJson(),
      };
}

class Dat {
  Dat(
      {required this.uid,
      required this.usr,
      required this.role,
      required this.mobile,
      required this.email,
      required this.qname,
      required this.enable,
      required this.gts,
      this.photo});
 
  String? photo;
  int uid;
  String usr;
  int role;
  String mobile;
  String email;
  String qname;
  bool enable;
  DateTime gts;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        uid: json["uid"] == null ? 'not available' : json["uid"],
        usr: json["usr"] == null ? 'not available' : json["usr"],
        role: json["role"] == null ? 'not available' : json["role"],
        mobile: json["mobile"] == null ? 'not available' : json["mobile"],
        email: json["email"] == null ? 'not available' : json["email"],
        qname: json["qname"] == null ? 'not available' : json["qname"],
        enable: json["enable"] == null ? 'not available' : json["enable"],
        photo: json["photo"] == null ? null : json["photo"],
        gts: DateTime.parse(json["gts"]),
      );

  Map<String, dynamic> toJson() => {
        "uid": uid == null ? null : uid,
        "usr": usr == null ? null : usr,
        "role": role == null ? null : role,
        "mobile": mobile == null ? null : mobile,
        "email": email == null ? null : email,
        "qname": qname == null ? null : qname,
        "enable": enable == null ? null : enable,
        "gts": gts == null ? null : gts.toIso8601String(),
      };
}
