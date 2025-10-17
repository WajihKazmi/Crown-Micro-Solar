// To parse this JSON data, do
//
//     final devicesofPlant = devicesofPlantFromJson(jsonString);

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

DevicesofPlant devicesofPlantFromJson(String str) =>
    DevicesofPlant.fromJson(json.decode(str));
String devicesofPlantToJson(DevicesofPlant data) => json.encode(data.toJson());

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Devices of Plant Queries REquest REquest *//////Start//////////////////

Future<Map<String, dynamic>> DevicesofplantQuery(BuildContext context,
    {required String status,
    required String devicetype,
    required String PID}) async {
  // final assetbundle = DefaultAssetBundle.of(context);
  // final dummy_data = await assetbundle.loadString("assets/PSdummy.json");
  // var jsonresonselist = jsonDecode(dummy_data);
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  String action =
      "&action=webQueryDeviceEs&status=$status&page=0&pagesize=100&plantid=$PID";
  //Action for PID query
  String action2 = "&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$PID";
  //Action for pid and device type
  String action3 =
      "&action=webQueryDeviceEs&devtype=$devicetype&page=0&pagesize=100&plantid=$PID";

  //// DataCollector/logger actions/////////////////////////////////////////////
  // String action4 =
  //     "&action=queryCollectors&devtype=-1&page=0&pagesize=100&plantid=$PID";

  //&devtype=2304

  //collector without status
  String action4 =
      "&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$PID";
  //collector with status
  String action5 =
      "&action=webQueryCollectorsEs&status=$status&page=0&pagesize=100&plantid=$PID";
  ///////////////////////////////////////////////////////////////////////////////

  /////////////////////condition check/////////////////
  print(
      'PID selected: ${PID} ,Status selected: ${status} ,DeviceTYPE selected: ${devicetype} ,');
  String new_action;
  if (status == '0101' && devicetype == '0101') {
    /// condition if status is all and device type is all
    new_action = action2;
  } else if (status == '0101' && devicetype != '0101' && devicetype != '0110') {
    /// condition if status is all and device type is changed
    new_action = action3;
  } else if (status == '0101' && devicetype == '0110') {
    ///collector query condition 1
    new_action = action4;
  } else if (status != '0101' && devicetype == '0110') {
    ///collector query condition 2
    new_action = action5;
  } else {
    /// condition if status  and device type  are changed
    new_action = action;
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

  var data = salt + Secret + token + new_action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          new_action +
          postaction;
  print('DevicesofPlant URL: $url');
  // var response = await http.get(Uri.parse(url));
  // print(response);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'Devices of Plant Queries REquest  Response Success!! no Error');
          print(
              'Devices of Plant Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('Devices of Plant Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      } else if (response.statusCode == 504) {
        print('Devices of Plant Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 504};
      }
      print(
          'Devices of Plant Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'Devices of Plant Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Devices of Plant Queries REquest  *//////End//////////////////

class DevicesofPlant {
  DevicesofPlant({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory DevicesofPlant.fromJson(Map<String, dynamic> json) => DevicesofPlant(
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
  Device(
      {this.pn,
      this.devcode,
      this.devaddr,
      this.sn,
      this.timezone,
      this.status,
      this.uid,
      this.pid,
      this.alias});

  final String? pn;
  final int? devcode;
  final int? devaddr;
  final String? sn;
  final int? timezone;
  final int? status;
  final int? uid;
  final int? pid;
  final String? alias;

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        pn: json["pn"] == null ? null : json["pn"],
        devcode: json["devcode"] == null ? null : json["devcode"],
        devaddr: json["devaddr"] == null ? null : json["devaddr"],
        sn: json["sn"] == null ? null : json["sn"],
        timezone: json["timezone"] == null ? null : json["timezone"],
        status: json["status"] == null ? null : json["status"],
        uid: json["uid"] == null ? null : json["uid"],
        pid: json["pid"] == null ? null : json["pid"],
        alias: json["devalias"] == null ? null : json["devalias"],
      );

  Map<String, dynamic> toJson() => {
        "pn": pn == null ? null : pn,
        "devcode": devcode == null ? null : devcode,
        "devaddr": devaddr == null ? null : devaddr,
        "sn": sn == null ? null : sn,
        "timezone": timezone == null ? null : timezone,
        "status": status == null ? null : status,
        "uid": uid == null ? null : uid,
        "pid": pid == null ? null : pid,
      };
}
