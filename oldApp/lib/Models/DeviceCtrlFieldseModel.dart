// To parse this JSON data, do
//
//     final deviceCtrlFieldseModel = deviceCtrlFieldseModelFromJson(jsonString);

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

DeviceCtrlFieldseModel deviceCtrlFieldseModelFromJson(String str) =>
    DeviceCtrlFieldseModel.fromJson(json.decode(str));
String deviceCtrlFieldseModelToJson(DeviceCtrlFieldseModel data) =>
    json.encode(data.toJson());
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query Device cTRL value  *//////Start//////////////////

Future<Map<String, dynamic>> DevicecTRLvalueQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr,
    required String id}) async {
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
      "&action=queryDeviceCtrlValue&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&id=$id&i18n=en_US";
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
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +postaction;
  print('DevicecTRLvalueQuery URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DevicecTRLvalueQuery Queries REquest  Response Success!! no Error');
          print(
              'DevicecTRLvalueQuery Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print(
            'DevicecTRLvalueQuery Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'DevicecTRLvalueQuery Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'DevicecTRLvalueQuery Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Query Device cTRL value  *//////End//////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** DeviceCtrlFieldseModel Queries  REquest *//////Start//////////////////

Future<Map<String, dynamic>> DeviceCtrlFieldseModelQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr}) async {
  // final assetbundle = DefaultAssetBundle.of(context);
  // final dummy_data = await assetbundle.loadString("assets/PSdummy.json");
  // var jsonresonselist = jsonDecode(dummy_data);
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  //old
  // String action =
  //     "&action=queryDeviceCtrlField&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US&lang=en_US";
  
  //new
   String action =
      "&action=queryDeviceCtrlField&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US";

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
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  print('DeviceCtrlFieldseModel URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DeviceCtrlFieldseModel Queries REquest  Response Success!! no Error');
          print(
              'DeviceCtrlFieldseModel Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print(
            'DeviceCtrlFieldseModel Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'DeviceCtrlFieldseModel Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'DeviceCtrlFieldseModel Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** DeviceCtrlFieldseModel Queries REquest  *//////End//////////////////

//////////////////////////////////////** ctrlDevice field value update REquest  *//////Start//////////////////

Future<Map<String, dynamic>> UpdateDeviceFieldQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String ID,
    required String Value,
    required String devcode,
    required String devaddr}) async {
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
      "&action=ctrlDevice&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&id=$ID&val=$Value&i18n=en_US";
  
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
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;
  print('UpdateDeviceField URL: $url');
  //var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'UpdateDeviceField Queries REquest  Response Success!! no Error');
          print(
              'UpdateDeviceField Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print(
            'UpdateDeviceField Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'UpdateDeviceField Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'UpdateDeviceField Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** ctrlDevice field value update REquest  *//////End//////////////////

/////////////////////////////////////** modify device information Queries  REquest *//////Start//////////////////

Future<Map<String, dynamic>> ModifyDeviceinfoQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr,
    required String alias}) async {
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
      "&action=editDeviceInfo&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&alias=$alias&i18n=en_US";
  
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
  

  var data = salt + Secret + token + action +postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +postaction;
  print('DeviceCtrlFieldseModel URL: $url');
  //var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'ModifyDeviceinfoQuery Queries REquest  Response Success!! no Error');
          // print(
          //     'ModifyDeviceinfoQuery Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print(
            'ModifyDeviceinfoQuery Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'ModifyDeviceinfoQuery Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'ModifyDeviceinfoQuery Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** modify device information Queries REquest  *//////End//////////////////

////////////////////////////////////** Delete device information Queries  REquest *//////Start//////////////////

Future<Map<String, dynamic>> DeletedeviceQuery(
  BuildContext context, {
  required String SN,
  required String PN,
  required String devcode,
  required String devaddr,
}) async {
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
      "&action=delDeviceFromPlant&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode";
  
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
          action + postaction;
  print('Deletedevice URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Deletedevice Queries REquest  Response Success!! no Error');
          print(
              'Deletedevice Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('Deletedevice Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'Deletedevice Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'Deletedevice Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Delete device information Queries REquest  *//////End//////////////////

////////////////////////////////////**Changebackflow of device  Queries REquest  *//////Start//////////////////

Future<Map<String, dynamic>> ChangebackflowQuery(
  BuildContext context, {
  required String SN,
  required String PN,
  required String devcode,
  required String devaddr,
  required String backflow,
}) async {
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
      "&action=ctrlBackFlow&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&backFlow=$backflow&i18n=en_US&lang=en_US";

  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  print('Changebackflow URL: $url');
  var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Changebackflow Queries REquest  Response Success!! no Error');
          print(
              'Changebackflow Queries REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('Changebackflow Queries REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'Changebackflow Queries REquest APIrequest response : ${jsonResponse}');
      print(
          'Changebackflow Queries REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');

  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Changebackflow of device  Queries REquest  *//////End//////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////
class DeviceCtrlFieldseModel {
  DeviceCtrlFieldseModel({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory DeviceCtrlFieldseModel.fromJson(Map<String, dynamic> json) =>
      DeviceCtrlFieldseModel(
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
    this.field,
  });

  final List<Field>? field;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        field: json["field"] == null
            ? null
            : List<Field>.from(json["field"].map((x) => Field.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "field": field == null
            ? null
            : List<dynamic>.from(field!.map((x) => x.toJson())),
      };
}

class Field {
  Field({
    this.id,
    this.name,
    this.item,
    this.unit,
    this.hint,
  });

  final String? id;
  final String? name;
  final List<Item>? item;
  final String? unit;
  final String? hint;

  factory Field.fromJson(Map<String, dynamic> json) => Field(
        id: json["id"] == null ? null : json["id"],
        name: json["name"] == null ? null : json["name"],
        item: json["item"] == null
            ? null
            : List<Item>.from(json["item"].map((x) => Item.fromJson(x))),
        unit: json["unit"] == null ? null : json["unit"],
        hint: json["hint"] == null ? null : json["hint"],
      );

  Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "name": name == null ? null : name,
        "item": item == null
            ? null
            : List<dynamic>.from(item!.map((x) => x.toJson())),
        "unit": unit == null ? null : unit,
        "hint": hint == null ? null : hint,
      };
}

class Item {
  Item({
    this.key,
    this.val,
  });

  final String? key;
  final String? val;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        key: json["key"] == null ? null : json["key"],
        val: json["val"] == null ? null : json["val"],
      );

  Map<String, dynamic> toJson() => {
        "key": key == null ? null : key,
        "val": val == null ? null : val,
      };
}
