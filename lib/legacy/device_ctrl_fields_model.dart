// Legacy Device Control model and queries copied from newtemp (DataControl stack)
// Keep URLs, parameters, signing, and error handling exactly as legacy app.

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

// Query a single control field current value (legacy exact)
Future<Map<String, dynamic>> DevicecTRLvalueQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr,
    required String id}) async {
  var jsonResponse;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=queryDeviceCtrlValue&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&id=$id&i18n=en_US";

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";
  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";

  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

// Query device control fields (legacy exact)
Future<Map<String, dynamic>> DeviceCtrlFieldseModelQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr}) async {
  var jsonResponse;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=queryDeviceCtrlField&pn=$PN&sn=$SN&devcode=$devcode&devaddr=$devaddr&i18n=en_US";

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";

  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

// Update field value (legacy exact)
Future<Map<String, dynamic>> UpdateDeviceFieldQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String ID,
    required String Value,
    required String devcode,
    required String devaddr}) async {
  var jsonResponse;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=ctrlDevice&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&id=$ID&val=$Value&i18n=en_US";

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";

  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

// --- Additional legacy calls retained for compatibility (optional) ---
Future<Map<String, dynamic>> ModifyDeviceinfoQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr,
    required String alias}) async {
  var jsonResponse;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=editDeviceInfo&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&alias=$alias&i18n=en_US";
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";
  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> DeletedeviceQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr}) async {
  var jsonResponse;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=delDeviceFromPlant&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode";
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";
  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  var data = salt + Secret + token + action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action +
          postaction;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

Future<Map<String, dynamic>> ChangebackflowQuery(BuildContext context,
    {required String SN,
    required String PN,
    required String devcode,
    required String devaddr,
    required String backflow}) async {
  var jsonResponse;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=ctrlBackFlow&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&backFlow=$backflow&i18n=en_US&lang=en_US";
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  String url =
      'http://web.shinemonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action;
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
      } else if (response.statusCode == 404) {
        jsonResponse = {'err': 404};
      }
    });
  } catch (e) {
    jsonResponse = {'err': 404, 'desc': e.toString()};
  }
  return jsonResponse;
}

// Legacy DTOs
class DeviceCtrlFieldseModel {
  DeviceCtrlFieldseModel({this.err, this.desc, this.dat});
  final int? err;
  final String? desc;
  final Dat? dat;

  factory DeviceCtrlFieldseModel.fromJson(Map<String, dynamic> json) =>
      DeviceCtrlFieldseModel(
        err: json["err"],
        desc: json["desc"],
        dat: json["dat"] == null ? null : Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err,
        "desc": desc,
        "dat": dat?.toJson(),
      };
}

class Dat {
  Dat({this.field});
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
  Field({this.id, this.name, this.item, this.unit, this.hint});
  final String? id;
  final String? name;
  final List<Item>? item;
  final String? unit;
  final String? hint;

  factory Field.fromJson(Map<String, dynamic> json) => Field(
        id: json["id"],
        name: json["name"],
        item: json["item"] == null
            ? null
            : List<Item>.from(json["item"].map((x) => Item.fromJson(x))),
        unit: json["unit"],
        hint: json["hint"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "item": item == null
            ? null
            : List<dynamic>.from(item!.map((x) => x.toJson())),
        "unit": unit,
        "hint": hint,
      };
}

class Item {
  Item({this.key, this.val});
  final String? key;
  final String? val;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        key: json["key"],
        val: json["val"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "val": val,
      };
}
