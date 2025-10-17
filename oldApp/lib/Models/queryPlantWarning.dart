import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

QueryPlantWarning queryPlantWarningFromJson(String str) =>
    QueryPlantWarning.fromJson(json.decode(str));
String queryPlantWarningToJson(QueryPlantWarning data) =>
    json.encode(data.toJson());

///////////////////////////////////////Query plant warning of specific plant with Plant id (PID)/////////////start///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Future<Map<String, dynamic>> PlantWarningQuery({
  required String devtype,
  required String level,
  required String PID,
  required String handle,
  required String? Sdate,
  required String? Edate,
  String? SN,
}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";

  if (SN == null) {
    SN = "";
  }
  //if only pid is given
  String action =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&sn=$SN";
  //if  level is given
  String action2 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&level=$level&sn=$SN";
  //if  devtype and Level is given
  String action3 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&level=$level&devtype=$devtype&sn=$SN";
  //if  handle devtype and level is given
  String action4 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&level=$level&devtype=$devtype&handle=$handle&sn=$SN";
  //
  String action5 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&devtype=$devtype&sn=$SN";

  ///
  String action6 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&devtype=$devtype&handle=$handle&sn=$SN";

  ///
  String action7 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&handle=$handle&sn=$SN";

  ///
  String action8 =
      "&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$PID&handle=$handle&level=$level&sn=$SN";
  /////////////////////condition check/////////////////
  print(
      'Level selected: ${level} ,Devtype selected: ${devtype} ,Handle selected: ${handle} ,');
  String new_action;

  if (level == '0101' && devtype == '0101' && handle == '0101') {
    new_action = action;
  } else if (level != '0101' && devtype == '0101' && handle == '0101') {
    new_action = action2;
  } else if (level != '0101' && devtype != '0101' && handle == '0101') {
    new_action = action3;
  } else if (level != '0101' && devtype != '0101' && handle != '0101') {
    new_action = action4;
  } else if (level == '0101' && devtype != '0101' && handle == '0101') {
    new_action = action5;
  } else if (level == '0101' && devtype != '0101' && handle != '0101') {
    new_action = action6;
  } else if (level == '0101' && devtype == '0101' && handle != '0101') {
    new_action = action7;
  } else {
    new_action = action8;
  }

  String new_action_with_daterange;
  if (Sdate == null && Edate == null) {
    new_action_with_daterange = new_action;
  } else {
    //webQueryPlantsWarning
    // String Ac ='&action=queryPlantWarning&mode=strict&i18n=en_US&plantid=313362&pn=&sdate=2022-02-25%2000:00:00&edate=2022-02-25%2017:41:02&page=0&pagesize=10&i18n=en_US&lang=en_US';
    // String Ac ='&action=queryPlantWarning&mode=strict&i18n=en_US&plantid=313362&pn=&sdate=$Sdate&edate=$Edate&page=0&pagesize=10&i18n=en_US&lang=en_US';

    new_action_with_daterange =
        new_action + '&sdate=$Sdate 00:00:00&edate=$Edate 23:59:59';
    //new_action_with_daterange = Ac;
    // new_action_with_daterange = new_action + '&sdate=$Sdate&edate=$Sdate<=date<$Edate';
    //sdate < = date < edate
  }
  //print('new_action_with_daterange : $new_action_with_daterange');
  //var ac ='&action=queryPlantWarning&i18n=en_US&page=0&pagesize=100&plantid=313362&handle=true&sdate=2022-02-21%2000:00:00&edate=2022-02-27%2021:10:35';
  //var ac ="&action=webQueryPlantsWarning&mode=strict&i18n=en_US&plantid=313362&handle=true&pn=&sdate=2022-02-21%2000:00:00&edate=2022-02-25%2021:10:35&page=0&pagesize=10&i18n=en_US&lang=en_US";
  //var Parsed_Action = ac;

  var Parsed_Action = Uri(query: new_action_with_daterange).query;
  var data = salt + Secret + token + Parsed_Action.toString();
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          Parsed_Action.toString();
  print('Start Date: $Sdate    End Date: $Edate');
  print('PlantWarningQuery URL: $url');
  print('PlantWarningQuery parsedURL: ${Uri.parse(url)}');
  var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('PlantWarningQuery REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('PlantWarningQuery REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print('PlantWarningQuery REquest APIrequest response : ${jsonResponse}');
      print(
          'PlantWarningQuery REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}
///////////////////////////////////////Query plant warning of specific plant with Plant id (PID)/////////////end///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///
///////////////////////////////////////Query plant warning of all plants/////////////start///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Future<Map<String, dynamic>> PlantWarningALLplantsQuery({
  required String devtype,
  required String level,
  required String handle,
  required String? Sdate,
  required String? Edate,
}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";

  //if only pid is given
  String action =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100";
  //if  level is given
  String action2 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&level=$level";
  //if  devtype and Level is given
  String action3 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&level=$level&devtype=$devtype";
  //if  handle devtype and level is given
  String action4 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&level=$level&devtype=$devtype&handle=$handle";
  //
  String action5 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&devtype=$devtype";

  ///
  String action6 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&devtype=$devtype&handle=$handle";

  ///
  String action7 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&handle=$handle";

  ///
  String action8 =
      "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&handle=$handle&level=$level";
  /////////////////////condition check/////////////////
  print(
      'Level selected: ${level} ,Devtype selected: ${devtype} ,Handle selected: ${handle} ,');
  String new_action;

  if (level == '0101' && devtype == '0101' && handle == '0101') {
    new_action = action;
  } else if (level != '0101' && devtype == '0101' && handle == '0101') {
    new_action = action2;
  } else if (level != '0101' && devtype != '0101' && handle == '0101') {
    new_action = action3;
  } else if (level != '0101' && devtype != '0101' && handle != '0101') {
    new_action = action4;
  } else if (level == '0101' && devtype != '0101' && handle == '0101') {
    new_action = action5;
  } else if (level == '0101' && devtype != '0101' && handle != '0101') {
    new_action = action6;
  } else if (level == '0101' && devtype == '0101' && handle != '0101') {
    new_action = action7;
  } else {
    new_action = action8;
  }

  String new_action_with_daterange;
  if (Sdate == null && Edate == null) {
    new_action_with_daterange = new_action;
  } else {
    //webQueryPlantsWarning
    // String Ac ='&action=queryPlantWarning&mode=strict&i18n=en_US&plantid=313362&pn=&sdate=2022-02-25%2000:00:00&edate=2022-02-25%2017:41:02&page=0&pagesize=10&i18n=en_US&lang=en_US';
    // String Ac ='&action=queryPlantWarning&mode=strict&i18n=en_US&plantid=313362&pn=&sdate=$Sdate&edate=$Edate&page=0&pagesize=10&i18n=en_US&lang=en_US';

    new_action_with_daterange =
        new_action + '&sdate=$Sdate 00:00:00&edate=$Edate 23:59:59';
    //new_action_with_daterange = Ac;
    // new_action_with_daterange = new_action + '&sdate=$Sdate&edate=$Sdate<=date<$Edate';
    //sdate < = date < edate
  }
  //print('new_action_with_daterange : $new_action_with_daterange');
  var Parsed_Action = Uri(query: new_action_with_daterange).query;

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
  
  var data = salt + Secret + token + Parsed_Action.toString() + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          Parsed_Action.toString() + postaction;
  print('ALL Start Date: $Sdate    End Date: $Edate');
  print('ALL PlantWarningQuery URL: $url');
  print('ALL PlantWarningQuery parsedURL: ${Uri.parse(url)}');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('ALL PlantWarningQuery REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('ALL PlantWarningQuery REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'ALL PlantWarningQuery REquest APIrequest response : ${jsonResponse}');
      print(
          'ALL PlantWarningQuery REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}
///////////////////////////////////////Query plant warning of all plants/////////////end///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////Delete plant warning of  plants/////////////start///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Future<Map<String, dynamic>> DeletePlantWarningQuery({
  required String ID,
}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";

  //if only pid is given
  String action = "&action=ignorePlantWarning&i18n=en_US&id=$ID";

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
  

  var data = salt + Secret + token + action.toString() + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action.toString() +postaction;
  print('Delete PlantWarningQuery URL: $url');
  print('Delete PlantWarningQuery parsedURL: ${Uri.parse(url)}');
  //var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'Delete PlantWarningQuery REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('Delete PlantWarningQuery REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'Delete PlantWarningQuery REquest APIrequest response : ${jsonResponse}');
      print(
          'Delete PlantWarningQuery REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}
///////////////////////////////////////Delete plant warning of  plants/////////////end///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class QueryPlantWarning {
  QueryPlantWarning({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory QueryPlantWarning.fromJson(Map<String, dynamic> json) =>
      QueryPlantWarning(
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
    this.warning,
  });

  final int? total;
  final int? page;
  final int? pagesize;
  final List<Warning>? warning;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        warning: json["warning"] == null
            ? null
            : List<Warning>.from(
                json["warning"].map((x) => Warning.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total == null ? null : total,
        "page": page == null ? null : page,
        "pagesize": pagesize == null ? null : pagesize,
        "warning": warning == null
            ? null
            : List<dynamic>.from(warning!.map((x) => x.toJson())),
      };
}

class Warning {
  Warning({
    this.id,
    this.uid,
    this.did,
    this.pid,
    this.pn,
    this.devcode,
    this.devaddr,
    this.sn,
    this.status,
    this.level,
    this.code,
    this.desc,
    this.handle,
    this.remind,
    this.gts,
  });

  final String? id;
  final int? uid;
  final int? did;
  final int? pid;
  final String? pn;
  final int? devcode;
  final int? devaddr;
  final String? sn;
  final bool? status;
  final int? level;
  final String? code;
  final String? desc;
  final bool? handle;
  final bool? remind;
  final DateTime? gts;

  factory Warning.fromJson(Map<String, dynamic> json) => Warning(
        id: json["id"] == null ? null : json["id"],
        uid: json["uid"] == null ? null : json["uid"],
        did: json["did"] == null ? null : json["did"],
        pid: json["pid"] == null ? null : json["pid"],
        pn: json["pn"] == null ? null : json["pn"],
        devcode: json["devcode"] == null ? null : json["devcode"],
        devaddr: json["devaddr"] == null ? null : json["devaddr"],
        sn: json["sn"] == null ? null : json["sn"],
        status: json["status"] == null ? null : json["status"],
        level: json["level"] == null ? null : json["level"],
        code: json["code"] == null ? null : json["code"],
        desc: json["desc"] == null ? null : json["desc"],
        handle: json["handle"] == null ? null : json["handle"],
        remind: json["remind"] == null ? null : json["remind"],
        gts: json["gts"] == null ? null : DateTime.parse(json["gts"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "uid": uid == null ? null : uid,
        "did": did == null ? null : did,
        "pid": pid == null ? null : pid,
        "pn": pn == null ? null : pn,
        "devcode": devcode == null ? null : devcode,
        "devaddr": devaddr == null ? null : devaddr,
        "sn": sn == null ? null : sn,
        "status": status == null ? null : status,
        "level": level == null ? null : level,
        "code": code == null ? null : code,
        "desc": desc == null ? null : desc,
        "handle": handle == null ? null : handle,
        "remind": remind == null ? null : remind,
        "gts": gts == null ? null : gts?.toIso8601String(),
      };
}
