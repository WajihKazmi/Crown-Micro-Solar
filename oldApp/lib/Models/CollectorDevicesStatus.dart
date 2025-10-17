import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

CollectorDevicesStatus collectorDevicesStatusFromJson(String str) =>
    CollectorDevicesStatus.fromJson(json.decode(str));
String collectorDevicesStatusToJson(CollectorDevicesStatus data) =>
    json.encode(data.toJson());

Future<Map<String, dynamic>> DeleteCollector({required String PN}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  String action = "&action=delCollectorFromPlant&pn=$PN";

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
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  //print('CollectorDevicesStatus URL: $url');
  //var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('DeleteCollector REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('DeleteCollector REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print('DeleteCollector REquest APIrequest response : ${jsonResponse}');
      print(
          'DeleteCollector REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> NameChangeCollector(
    {required String PN, required String name}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  String action = "&action=editCollector&pn=$PN&alias=$name";

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
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  print('NameChangeCollector URL: $url');
//  var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('NameChangeCollector REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('NameChangeCollector REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'NameChangeCollector REquest APIrequest response : ${jsonResponse}');
      print(
          'NameChangeCollector REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////COLLECTOR STATUS AND ITS SUBORDINATE DEVICES STATUS DATAMODEL//////////////////////

Future<Map<String, dynamic>> CollectorDevicesStatusQuery(
    {required String PN}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  //String action = "&action=queryCollectorDevicesStatus&pn=$PN";   //old

  //new API
  
  String action = "&action=webQueryDeviceEs&pn=$PN&page=0&pagesize=20";
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
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +postaction;
  //print('CollectorDevicesStatus URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('CollectorDevicesStatus REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('CollectorDevicesStatus REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'CollectorDevicesStatus REquest APIrequest response : ${jsonResponse}');
      print(
          'CollectorDevicesStatus REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return jsonResponse;
}

Future<Map<String, dynamic>> AddCollectortoplant(
    {required String PN, required String name, required String PID}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";

  String Name = name.replaceAll(RegExp(r' '), '');
  log(Name);

  int TZ = DateTime.now().timeZoneOffset.inSeconds;

  //Action for specific PID  Status devicetype query
  String action =
      "&action=addCollectorEs&pn=$PN&alias=$Name&plantid=$PID&timezone=$TZ";

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

  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  print('AddCollectortoplant URL: $url');
  // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('AddCollectortoplant REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('AddCollectortoplant REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'AddCollectortoplant REquest APIrequest response : ${jsonResponse}');
      print(
          'AddCollectortoplant REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////COLLECTOR STATUS AND ITS SUBORDINATE DEVICES STATUS DATAMODEL//////////////////////

///////////////////////// Add Collector New API /////////////////////////////////////////////
///
Future<Map<String, dynamic>> AddCollectortoplantNEW(
    {required String PN, required String name, required String PID}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  ////////////////////////////////////
  String date = DateFormat('y-MM-dd').add_Hms().format(DateTime.now());
  int TZ = DateTime.now().timeZoneOffset.inSeconds;

  print(date);
  print(TZ);
  String Name = name.replaceAll(RegExp(r' '), '');
  log(Name);
  //Action for specific PID  Status devicetype query
  String action =
      "&action=addCollectorEs&pn=$PN&alias=$Name&plantid=$PID&address.installDate=$date&timezone=$TZ&source=1&address.installer=+&profit.nominalPower=500&address.lat=0&address.lon=0&address.address=abc&address.timezone=$TZ";

  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  print('AddCollectortoplant NEW API URL: $url');
  var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'AddCollectortoplant REquest  NEW  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('AddCollectortoplant REquest  NEw Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'AddCollectortoplant NEW REquest APIrequest response : ${jsonResponse}');
      print(
          'AddCollectortoplant NEW REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

///
/////////////////////////////Add Collector New API////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////Collector restart////////////////////////////
Future<Map<String, dynamic>> RestartCollector({required String PN}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  String action = "&action=restartCollector&pn=$PN";

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
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  // print('RestartCollector URL: $url');
  //var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('RestartCollector REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('RestartCollector REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print('RestartCollector REquest APIrequest response : ${jsonResponse}');
      print(
          'RestartCollector REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// To parse this JSON data, do
//
//     final collectorDevicesStatus = collectorDevicesStatusFromJson(jsonString);

class CollectorDevicesStatus {
  CollectorDevicesStatus({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory CollectorDevicesStatus.fromJson(Map<String, dynamic> json) =>
      CollectorDevicesStatus(
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
    this.total,
    this.page,
    this.pagesize,
    this.device,
  });

  final int? total;
  final int? page;
  final int? pagesize;
  final List<Device>? device;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        device: json["device"] == null
            ? null
            : List<Device>.from(json["device"].map((x) => Device.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total == null ? null : total,
        "page": page == null ? null : page,
        "pagesize": pagesize == null ? null : pagesize,
        "device": device == null
            ? null
            : List<dynamic>.from(device!.map((x) => x.toJson())),
      };
}

class Device {
  Device({
    this.devalias,
    this.sn,
    this.status,
    this.brand,
    this.devtype,
    this.collalias,
    this.pn,
    this.devaddr,
    this.devcode,
    this.usr,
    this.uid,
    this.profitToday,
    this.profitTotal,
    this.pid,
    this.focus,
    this.outpower,
    this.energyToday,
    this.energyYear,
    this.energyTotal,
  });

  final String? devalias;
  final String? sn;
  final int? status;
  final int? brand;
  final String? devtype;
  final String? collalias;
  final String? pn;
  final int? devaddr;
  final int? devcode;
  final String? usr;
  final int? uid;
  final String? profitToday;
  final String? profitTotal;
  final int? pid;
  final bool? focus;
  final String? outpower;
  final String? energyToday;
  final String? energyYear;
  final String? energyTotal;

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        devalias: json["devalias"] == null ? null : json["devalias"],
        sn: json["sn"] == null ? null : json["sn"],
        status: json["status"] == null ? null : json["status"],
        brand: json["brand"] == null ? null : json["brand"],
        devtype: json["devtype"] == null ? null : json["devtype"],
        collalias: json["collalias"] == null ? null : json["collalias"],
        pn: json["pn"] == null ? null : json["pn"],
        devaddr: json["devaddr"] == null ? null : json["devaddr"],
        devcode: json["devcode"] == null ? null : json["devcode"],
        usr: json["usr"] == null ? null : json["usr"],
        uid: json["uid"] == null ? null : json["uid"],
        profitToday: json["profitToday"] == null ? null : json["profitToday"],
        profitTotal: json["profitTotal"] == null ? null : json["profitTotal"],
        pid: json["pid"] == null ? null : json["pid"],
        focus: json["focus"] == null ? null : json["focus"],
        outpower: json["outpower"] == null ? null : json["outpower"],
        energyToday: json["energyToday"] == null ? null : json["energyToday"],
        energyYear: json["energyYear"] == null ? null : json["energyYear"],
        energyTotal: json["energyTotal"] == null ? null : json["energyTotal"],
      );

  Map<String, dynamic> toJson() => {
        "devalias": devalias == null ? null : devalias,
        "sn": sn == null ? null : sn,
        "status": status == null ? null : status,
        "brand": brand == null ? null : brand,
        "devtype": devtype == null ? null : devtype,
        "collalias": collalias == null ? null : collalias,
        "pn": pn == null ? null : pn,
        "devaddr": devaddr == null ? null : devaddr,
        "devcode": devcode == null ? null : devcode,
        "usr": usr == null ? null : usr,
        "uid": uid == null ? null : uid,
        "profitToday": profitToday == null ? null : profitToday,
        "profitTotal": profitTotal == null ? null : profitTotal,
        "pid": pid == null ? null : pid,
        "focus": focus == null ? null : focus,
        "outpower": outpower == null ? null : outpower,
        "energyToday": energyToday == null ? null : energyToday,
        "energyYear": energyYear == null ? null : energyYear,
        "energyTotal": energyTotal == null ? null : energyTotal,
      };
}
