// To parse this JSON data, do
//
//     final queryPlantCurrentDataNew = queryPlantCurrentDataNewFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

QueryPlantCurrentDataNew queryPlantCurrentDataNewFromJson(String str) =>
    QueryPlantCurrentDataNew.fromJson(json.decode(str));
String queryPlantCurrentDataNewToJson(QueryPlantCurrentDataNew data) =>
    json.encode(data.toJson());

/////////////////////////////////////////PlantcurrentData Query Test ////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
Future<Map<String, dynamic>> PlantcurrentDataQuery(
    {required String PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action =
      "&action=queryPlantCurrentData&plantid=$PID&par=ENERGY_TODAY,ENERGY_MONTH,ENERGY_YEAR,ENERGY_TOTAL,ENERGY_PROCEEDS,ENERGY_CO2,CURRENT_TEMP,CURRENT_RADIANT,BATTERY_SOC,ENERGY_COAL,ENERGY_SO2";
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
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  //print(url);
//  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('PlantcurrentData Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('PlantcurrentData response : ${jsonResponse}');
      print('PlantcurrentData statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse ?? {"error": "404"};
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query DeviceCount REquest   *//////END///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

class QueryPlantCurrentDataNew {
  QueryPlantCurrentDataNew({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final List<Dat>? dat;

  factory QueryPlantCurrentDataNew.fromJson(Map<String, dynamic> json) =>
      QueryPlantCurrentDataNew(
        err: json["err"] == null ? null : json["err"],
        desc: json["desc"] == null ? null : json["desc"],
        dat: json["dat"] == null
            ? null
            : List<Dat>.from(json["dat"].map((x) => Dat.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "err": err == null ? null : err,
        "desc": desc == null ? null : desc,
        "dat": dat == null
            ? null
            : List<dynamic>.from(dat!.map((x) => x.toJson())),
      };
}

class Dat {
  Dat({
    this.key,
    this.val,
  });

  final String? key;
  final dynamic? val;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        key: json["key"] == null ? null : json["key"],
        val: json["val"],
      );

  Map<String, dynamic> toJson() => {
        "key": key == null ? null : key,
        "val": val,
      };
}
