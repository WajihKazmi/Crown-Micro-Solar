import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// To parse this JSON data, do
//
//     final powerGenerationCertainYear = powerGenerationCertainYearFromJson(jsonString);

import 'dart:convert';

PowerGenerationCertainYear powerGenerationCertainYearFromJson(String str) =>
    PowerGenerationCertainYear.fromJson(json.decode(str));
String powerGenerationCertainYearToJson(PowerGenerationCertainYear data) =>
    json.encode(data.toJson());

//////////////////////////////////////** PowerGeneration Certainyear Queries  REquest  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> PowerGenerationCertainYearQuery(
    {required String year}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action = "&action=queryPlantsEnergyYear&date=$year";
  //print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  //print('Sign: $sign');
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  print('PowerGenerationCertainYear URL:  $url');
  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('PowerGenerationCertainYear Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('PowerGenerationCertainYear APIrequest response : ${jsonResponse}');
      print(
          'PowerGenerationCertainYear APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** PowerGeneration Certainyear Queries  *//////END///////////////////////////

class PowerGenerationCertainYear {
  PowerGenerationCertainYear({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory PowerGenerationCertainYear.fromJson(Map<String, dynamic> json) =>
      PowerGenerationCertainYear(
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
    this.energy,
  });

  final String? energy;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        energy: json["energy"] == null ? null : json["energy"],
      );

  Map<String, dynamic> toJson() => {
        "energy": energy == null ? null : energy,
      };
}
