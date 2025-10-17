import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

DeviceDataOneDayQuery deviceDataOneDayQueryFromJson(String str) =>
    DeviceDataOneDayQuery.fromJson(json.decode(str));
String deviceDataOneDayQueryToJson(DeviceDataOneDayQuery data) =>
    json.encode(data.toJson());

////////////////////////////////////**DeviceDataOneDayQuery REquest  *//////Start//////////////////

Future<DeviceDataOneDayQuery> DeviceDataOneDay_Query({  
  required String SN,
  required String PN,
  required String devcode,
  required String devaddr,
  required String date,
  required String pagenumber,
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
  
  //old
  // String action =
  //     "&action=queryDeviceDataOneDayPaging&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&date=$date&page=$pagenumber&pagesize=200&i18n=en_US&lang=en_US";
   

  //new 
   String action =
      "&action=queryDeviceDataOneDayPaging&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&date=$date&page=$pagenumber&pagesize=200&i18n=en_US";

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
          action + postaction;
  print('DeviceDataOneDayQuery URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('DeviceDataOneDayQuery REquest  Response Success!! no Error');
          print(
              'DeviceDataOneDayQuery REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('DeviceDataOneDayQuery REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'DeviceDataOneDayQuery  REquest APIrequest response : ${jsonResponse}');
      print(
          'DeviceDataOneDayQuery  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  //print('SENT JSonresponse: ${jsonResponse}');
  DeviceDataOneDayQuery DDOD = new DeviceDataOneDayQuery.fromJson(jsonResponse);
  print(
      'SENT DDOD   Title: ${DDOD.dat?.title![1].title}  Value : ${DDOD.dat?.row![0].field![1]}');
  return DDOD;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** DeviceDataOneDayQuery REquest  *//////End//////////////////

class DeviceDataOneDayQuery {
  DeviceDataOneDayQuery({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory DeviceDataOneDayQuery.fromJson(Map<String, dynamic> json) =>
      DeviceDataOneDayQuery(
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
    this.title,
    this.row,
  });

  final int? total;
  final int? page;
  final int? pagesize;
  final List<Title>? title;
  final List<Row>? row;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        title: json["title"] == null
            ? null
            : List<Title>.from(json["title"].map((x) => Title.fromJson(x))),
        row: json["row"] == null
            ? null
            : List<Row>.from(json["row"].map((x) => Row.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total == null ? null : total,
        "page": page == null ? null : page,
        "pagesize": pagesize == null ? null : pagesize,
        "title": title == null
            ? null
            : List<dynamic>.from(title!.map((x) => x.toJson())),
        "row": row == null
            ? null
            : List<dynamic>.from(row!.map((x) => x.toJson())),
      };
}

class Row {
  Row({
    this.realtime,
    this.field,
  });

  final bool? realtime;
  final List<String>? field;

  factory Row.fromJson(Map<String, dynamic> json) => Row(
        realtime: json["realtime"] == null ? null : json["realtime"],
        field: json["field"] == null
            ? null
            : List<String>.from(json["field"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "realtime": realtime == null ? null : realtime,
        "field":
            field == null ? null : List<dynamic>.from(field!.map((x) => x)),
      };
}

class Title {
  Title({
    this.title,
    this.unit,
  });

  final String? title;
  final String? unit;

  factory Title.fromJson(Map<String, dynamic> json) => Title(
        title: json["title"] == null ? null : json["title"],
        unit: json["unit"] == null ? null : json["unit"],
      );

  Map<String, dynamic> toJson() => {
        "title": title == null ? null : title,
        "unit": unit == null ? null : unit,
      };
}

/////////////////////////*******************************************?////////////////////// */
///////////////////////////////////TESTING can be deleted after tes//////////////////////////
////////////////////////////////////**DeviceDataOneDayQuery REquest  *//////Start//////////////////

Future<DeviceenergyQuint> DeviceEnergyQuintiyoneday_Query(
  BuildContext context, {
  required String SN,
  required String PN,
  required String devcode,
  required String devaddr,
  required String date,
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
      "&action=queryDeviceEnergyQuintetOneDay&pn=$PN&sn=$SN&devaddr=$devaddr&devcode=$devcode&date=$date";

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
  print('DeviceEnergyQuintiyoneday_Query URL: $url');
 // var response = await http.get(Uri.parse(url));

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print(
              'DeviceEnergyQuintiyoneday_Query REquest  Response Success!! no Error');
          print(
              'DeviceEnergyQuintiyoneday_Query REquest response: ${jsonResponse['dat']['total']}');
          //jsonresonselist = jsonResponse;
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print(
            'DeviceEnergyQuintiyoneday_Query REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          'DeviceEnergyQuintiyoneday_Query  REquest APIrequest response : ${jsonResponse}');
      print(
          'DeviceEnergyQuintiyoneday_Query  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  DeviceenergyQuint DEQOD = DeviceenergyQuint.fromJson(jsonResponse);

  return DEQOD;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** DeviceEnergyQuintiyoneday_Query REquest  *//////End//////////////////

class DeviceenergyQuint {
  String? outputpower;
  String? energytoday;
  String? energymonth;
  String? energyyear;
  String? energytotal;

  DeviceenergyQuint(
      {this.energymonth,
      this.energytoday,
      this.energytotal,
      this.energyyear,
      this.outputpower});

  factory DeviceenergyQuint.fromJson(Map<String, dynamic> json) {
    return DeviceenergyQuint(
        energymonth: json["dat"]["energyMonth"],
        energytoday: json["dat"]["energyToday"],
        energytotal: json["dat"]["energyTotal"],
        energyyear: json["dat"]["energyYear"],
        outputpower: json["dat"]["outputPower"]);
  }
}
