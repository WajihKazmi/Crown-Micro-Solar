import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// To parse this JSON data, do
//
//     final annualPg = annualPgFromJson(jsonString);

AnnualPg annualPgFromJson(String str) => AnnualPg.fromJson(json.decode(str));
String annualPgToJson(AnnualPg data) => json.encode(data.toJson());

/////////////////////////////////////** Annual PowerGeneration Queries *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> AnnualPgQuery({required String PID}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  if (PID == 'all') {
    action = "&action=queryPlantsEnergyTotalPerYear&source=1";
  } else {
    action = "&action=queryPlantEnergyTotalPerYear&plantid=$PID&source=1";
  }
  //print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  print('AnnualPg URL:  $url');
  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('AnnualPg Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('AnnualPg APIrequest response : ${jsonResponse}');
      print('AnnualPg APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> AnnualPgQuery2({
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
      "&action=querySPDeviceKeyParameterTotalPerYear&source=$Source&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false";

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

  print('AnnualPgQuery2 URL: $url');

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('AnnualPg Query Response Success!! No Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('AnnualPg API request response: $jsonResponse');
      print('AnnualPg API request status code: ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Annual PowerGeneration  Queries  *//////END///////////////////////////

class AnnualPg {
  AnnualPg({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory AnnualPg.fromJson(Map<String, dynamic> json) => AnnualPg(
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
    this.peryear,
  });

  final List<Peryear>? peryear;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        peryear: json["peryear"] == null
            ? null
            : List<Peryear>.from(
                json["peryear"].map((x) => Peryear.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "peryear": peryear == null
            ? null
            : List<dynamic>.from(peryear!.map((x) => x.toJson())),
      };
}

class Peryear {
  Peryear({
    this.val,
    this.ts,
  });

  final String? val;
  final DateTime? ts;

  factory Peryear.fromJson(Map<String, dynamic> json) => Peryear(
        val: json["val"] == null ? null : json["val"],
        ts: json["ts"] == null ? null : DateTime.parse(json["ts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val == null ? null : val,
        "ts": ts == null ? null : ts?.toIso8601String(),
      };
}
