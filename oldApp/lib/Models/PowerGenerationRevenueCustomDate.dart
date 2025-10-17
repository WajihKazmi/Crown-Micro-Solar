// To parse this JSON data, do
//
//     final powerGenerationRevenueCustomDate = powerGenerationRevenueCustomDateFromJson(jsonString);

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

PowerGenerationRevenueCustomDate powerGenerationRevenueCustomDateFromJson(
        String str) =>
    PowerGenerationRevenueCustomDate.fromJson(json.decode(str));
String powerGenerationRevenueCustomDateToJson(
        PowerGenerationRevenueCustomDate data) =>
    json.encode(data.toJson());

//////////////////////////////////////** Query Power generation Revenue ALL PP REquest REquest   *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> queryPlantsProfitStatistic(
    {required String Date}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  if (Date == 'all') {
    action = "&action=queryPlantsProfitStatistic&lang=zh_CN";
  } else {
    action = "&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$Date";
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

  print('URL: $url');
  // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('queryPlantsProfitStatistic Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('queryPlantsProfitStatistic APIrequest response : ${jsonResponse}');
      print(
          'queryPlantsProfitStatistic APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> queryPlantsProfitStatistic2({
  required String devcode,
  required String devaddr,
  required String pn,
  required String sn,
}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  // if (Date == 'all') {
  action =
      "&action=queryDeviceParsEs&source=1&devcode=$devcode&pn=$pn&devaddr=$devaddr&sn=$sn&i18n=en_US";
  // } else {
  //   action = "&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$Date";
  // }

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
  // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('queryPlantsProfitStatistic Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('queryPlantsProfitStatistic APIrequest response : ${jsonResponse}');
      print(
          'queryPlantsProfitStatistic APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> queryPlantsProfitStatistic3({
  required String sn,
}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";
  String action;
  // if (Date == 'all') {
  action = "&action=webQueryDeviceEs&source=1&sn=$sn";
  // } else {
  //   action = "&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$Date";
  // }

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
  // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('queryPlantsProfitStatistic Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('queryPlantsProfitStatistic APIrequest response : ${jsonResponse}');
      print(
          'queryPlantsProfitStatistic APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query Power generation Revenue ALL PP REquest   *//////END///////////////////////////
//////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////**Query Power generation Revenue Custom Date REquest   *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> PowerGenerationRevenueCustomQuery(
    {required String Date, required int Page, required int Pagesize}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  print('token: $token');
  print('Secret: $Secret');
  String salt = "12345678";

  ///date format YYYY-MM-DD
  ///PowerGeneration revenue customdate
  // String action =
  //     "&action=queryPlantsProfitOneDay&pagesize=$Pagesize&page=$Page&date=" +
  //         Date;

  ////power generation of all power sations on current date
  String action = "&action=queryPlantsProfit&pagesize=50";

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
//  var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'PowerGenerationRevenueCustomDATE Query Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print(
          'PowerGenerationRevenueCustomDATE APIrequest response : ${jsonResponse}');
      print('APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query Power generation Revenue Custom Date REquest   *//////END///////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

class PowerGenerationRevenueCustomDate {
  PowerGenerationRevenueCustomDate({
    required this.err,
    required this.desc,
    required this.dat,
  });

  int err;
  String desc;
  Dat dat;

  factory PowerGenerationRevenueCustomDate.fromJson(
          Map<String, dynamic> json) =>
      PowerGenerationRevenueCustomDate(
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
    required this.total,
    required this.page,
    required this.pagesize,
    required this.plant,
  });

  int total;
  int page;
  int pagesize;
  List<Plant> plant;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        plant: List<Plant>.from(json["plant"].map((x) => Plant.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total == null ? null : total,
        "page": page == null ? null : page,
        "pagesize": pagesize == null ? null : pagesize,
        "plant": plant == null
            ? null
            : List<dynamic>.from(plant.map((x) => x.toJson())),
      };
}

class Plant {
  Plant({
    required this.pid,
    required this.energy,
    required this.currency,
    required this.profit,
    required this.coal,
    required this.co2,
    required this.so2,
  });

  int pid;
  String energy;
  String currency;
  String profit;
  String coal;
  String co2;
  String so2;

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
        pid: json["pid"] == null ? null : json["pid"],
        energy: json["energy"] == null ? null : json["energy"],
        currency: json["currency"] == null ? null : json["currency"],
        profit: json["profit"] == null ? null : json["profit"],
        coal: json["coal"] == null ? null : json["coal"],
        co2: json["co2"] == null ? null : json["co2"],
        so2: json["so2"] == null ? null : json["so2"],
      );

  Map<String, dynamic> toJson() => {
        "pid": pid == null ? null : pid,
        "energy": energy == null ? null : energy,
        "currency": currency == null ? null : currency,
        "profit": profit == null ? null : profit,
        "coal": coal == null ? null : coal,
        "co2": co2 == null ? null : co2,
        "so2": so2 == null ? null : so2,
      };
}
