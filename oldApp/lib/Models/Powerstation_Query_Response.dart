// To parse this JSON data, do
//
//     final response = responseFromJson(jsonString);

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Response responseFromJson(String str) => Response.fromJson(json.decode(str));
String responseToJson(Response data) => json.encode(data.toJson());

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////EditInfo PS////////start//////////////////////////////////////////////////////////

Future<Map<String, dynamic>> EDITPS(
    {required String PID,
    required String Plantname,
    required String country,
    required String province,
    required String city,
    required String county,
    required String lat,
    required String lon,
    required String timezone,
    required String? town,
    required String? village,
    required String? address,
    required String UnitProfit,
    required String currency,
    required String? countrycurrency,
    required String coal,
    required String co2,
    required String so2,
    required String nominalPower,
    required String? EnergyYearEstimate,
    required String? DesignCompany,
    dynamic? PicBig,
    dynamic? PicSmall,
    required String installdate}) async {
  print(PicBig);
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  // String action = "&action=editPlant&plantid=$PID&name=$name";

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
  

  ////////////////// TO CREATE ACTION for sign ////////////////
  /////////////////////////////////////////////////////////////

  Map<String, dynamic> queryparameters = {
    'action': 'editPlant', //required
    'plantid': '$PID', //required
    'name': '$Plantname', //required
    'address.country': '$country', //required
    'address.province': '$province', //required
    'address.city': '$city', //required
    'address.county': '$county', //required
    'address.lon': '$lon', //required
    'address.lat': '$lat', //required
    'address.timezone': '$timezone', //required
    'address.town': '$town',
    'address.village': '$village',
    'address.address': '$address',
    'profit.unitProfit': '$UnitProfit', //required
    'profit.currency': '$currency', //required
    'profit.currencyCountry': '$countrycurrency',
    'profit.coal': '$coal', //required
    'profit.co2': '$co2', //required
    'profit.so2': '$so2', //required
    'nominalPower': '$nominalPower', //required
    'energyYearEstimate': '$EnergyYearEstimate',
    'designCompany': '$DesignCompany',
    'install': '$installdate', //required
    //'picBig': PicBig == null ? "" : await MultipartFile.fromFile(PicBig, filename: Plantname),
     "source": "$Source",
      "app_id": "$packageName",
      "app_version": "$version",
      "app_client":  "$platform"
  };

  String action = '&' + Uri(queryParameters: queryparameters).query;

  //print('Sign: $sign');
  // String url =
  //     'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
  //         action;

  /////////////////// To create sign /////////////////////////

  print('action: $action');
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  print('Sign: $sign');
  /////////////////// To create sign /////////////////////////
  ////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////
  /////////// TO CREATE QueryParameter with sign+salt+token+action ////////
  Map<String, dynamic> parameterswithsignsalttokenaction = {
    'sign': '$sign',
    'salt': '$salt',
    'token': '$token',
  };
  parameterswithsignsalttokenaction.addAll(queryparameters);
  ////////////// TO CREATE QueryParameter with sign+salt+token+action ////////////////
  ////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////
  ////////////// TO CREATE Api request url  with apilink+sign+salt+token+action ////////////////
  var uri = Uri.parse('http://api.dessmonitor.com/public/');
  uri = uri.replace(queryParameters: parameterswithsignsalttokenaction);
  print('URI:$uri');
  ////////////// TO CREATE Api request url  with apilink+sign+salt+token+action ////////////////
  ///
  


  
  // print(response.body);
  
  try {
    await http.post(uri).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('EditInfo PS Response Success!! no Error');

          // plantcount = jsonResponse['dat']['count'];
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('EditInfo PS APIrequest response : ${jsonResponse}');
      print('EditInfo PS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

/////////////////////////////////////////////////EditInfo PS////////end/////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////Delete PS////////start//////////////////////////////////////////////////////////

Future<Map<String, dynamic>> DeletePS({required String PID, required String plantname}) async {
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";

  //old
  String action = "&action=delPlant&plantid=$PID";

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
  //print('Sign: $sign');

  String url =
      'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
          action + postaction;

 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('Delete PS Response Success!! no Error');

          // plantcount = jsonResponse['dat']['count'];
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('Delete PS APIrequest response : ${jsonResponse}');
      print('Delete PS APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return jsonResponse;
}

/////////////////////////////////////////////////Delete PS////////end/////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Total COunt Queries REquest  *//////Start//////////////////

Future<int> NumberofPowerStationQuery() async {
  var jsonResponse = null;
  var plantcount = 0;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action = "&action=queryPlantCount";

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
  String url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' + action + postaction;

 // var response = await http.get(Uri.parse(url));
  // print(response.body);
  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('NumberofPowerStation Response Success!! no Error');
          print(
              'NumberofPowerStation count response: ${jsonResponse['dat']['count']}');
          plantcount = jsonResponse['dat']['count'];
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      }
      print('NumberofPowerStation APIrequest response : ${jsonResponse}');
      print(
          'NumberofPowerStation APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  return plantcount;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Total COunt Queries REquest  *//////End//////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** All Powerstations Info List Queries REquest *//////Start//////////////////

Future<Map<String, dynamic>> ListofPowerStationQuery(BuildContext context, {required int status, required String orderby, required String Plantname}) async {
  
  var jsonResponse = null;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  ///////////////////////////////////////////////////////
  ////////////Action for specific query////////////////////
  // String action =
  //     "&action=queryPlants&status=$status&orderBy=$orderby&page=0&pagesize=20";
  // //Action for All plants query
  // String action2 = "&action=queryPlants&orderBy=$orderby&page=0&pagesize=20";
  // //Action if plant name is given
  // String action3 = "&action=queryPlants&plantName=$Plantname";
  /////////////////////condition check/////////////////
  ////////////////////////////////////////////////////////////

  String action = "&action=webQueryPlants&status=$status&orderBy=$orderby&page=0&pagesize=100";
  //Action for All plants query
  String action2 = "&action=webQueryPlants&orderBy=$orderby&page=0&pagesize=100";

  //Action if plant name is given
  String action3 = "&action=webQueryPlants&plantName=$Plantname";

  print('Plant name selescted: $Plantname');
  String new_action;
  if (Plantname.length == 0) {
    new_action = status.toString() == '5' ? action2 : action;
  } else {
    new_action = action3;
  }

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction = "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";

  var data = salt + Secret + token + new_action + postaction;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();

  String url = 'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' + new_action + postaction;

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('All Powerstations Info List  Response Success!! no Error');
          print('All Powerstations Info List  count response: ${jsonResponse['dat']['total']}');
          
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {

        print('All Powerstations Info List  Response Failed : No response from server');
        jsonResponse = {'err': 404};

      } else if (response.statusCode == 504) {
        print('All Powerstations Info List  Response Failed : No response from server');
        jsonResponse = {'err': 504};
       
      }
      print('All Powerstations Info List  APIrequest response : ${jsonResponse}');
      print('All Powerstations Info List  APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }
  // var R = Response.fromJson(jsonresonselist);
  print('SENT JSonresponse: ${jsonResponse}');
  return jsonResponse;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** all Powerstations Info List Queries REquest  *//////End//////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Queries REquest  *//////START///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<Map<String, dynamic>> PowerStationInfoQuery() async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  
  String salt = "12345678";

  Map<String, String> queryparameters = {
    'action': 'queryPlants', //required
    'pagesize': '1',
    'page': '0'
  };

  String action = '&' + Uri(queryParameters: queryparameters).query;

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction = "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
 
  var data = salt + Secret + token + action;
  var output = utf8.encode(data);
  var sign = sha1.convert(output).toString();
  
  Map<String, String> parameterswithsignsalttokenaction = {
    'sign': '$sign',
    'salt': '$salt',
    'token': '$token',
  };

  parameterswithsignsalttokenaction.addAll(queryparameters);
 
  var uri = Uri.parse('http://api.dessmonitor.com/public/');
  uri = uri.replace(queryParameters: parameterswithsignsalttokenaction);
  
  try {
    await http.post(uri).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('PowersStation Query Response Success!! no Error');
          return jsonResponse;
          
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('PowersStation Query Response Failed : No response from server');
        jsonResponse = {'err': 404};
        
      }
      print('PowerStationQueryAPIrequest response : ${jsonResponse}');
      print('APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return jsonResponse;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////** Powerstations Queries  *//////END///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Response {
  Response({
    this.err,
    this.desc,
    this.dat,
  });

  int? err;
  String? desc;
  Dat? dat;

  factory Response.fromJson(Map<String, dynamic> json) => Response(
        err: json["err"] == null ? null : json["err"],
        desc: json["desc"] == null ? null : json["desc"],
        dat: Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err,
        "desc": desc,
        "dat": dat?.toJson(),
      };

  //responseclasss
}

class Dat {
  Dat({
    this.total,
    this.page,
    this.pagesize,
    this.plant,
  });

  int? total;
  int? page;
  int? pagesize;
  List<Plant>? plant;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        plant: List<Plant>.from(json["plant"].map((x) => Plant.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "pagesize": pagesize,
        "plant": List<dynamic>.from(plant!.map((x) => x.toJson())),
      };
}

class Plant {
  Plant({
    this.pid,
    this.uid,
    this.name,
    this.status,
    this.address,
    this.profit,
    this.nominalPower,
    this.energyYearEstimate,
    this.designCompany,
    this.picBig,
    this.picSmall,
    this.Todayenergy,
    this.Currentoutputpower,
    this.Totalpower,
    this.install,
    this.gts,
  });

  int? pid;
  int? uid;
  String? name;
  int? status;
  Address? address;
  Profit? profit;
  String? nominalPower;
  String? energyYearEstimate;
  String? designCompany;
  String? picBig;
  String? picSmall;
  DateTime? install;
  DateTime? gts;
  String? Todayenergy;
  String? Currentoutputpower;
  String? Totalpower;

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
        Todayenergy: json["energy"] == null ? 'null' : json["energy"],
        Currentoutputpower:
            json["outputPower"] == null ? 'null' : json["outputPower"],
        Totalpower: json["energyTotal"] == null ? 'null' : json["energyTotal"],
        pid: json["pid"] == null ? 'null' : json["pid"],
        uid: json["uid"] == null ? 'null' : json["uid"],
        name: json["name"] == null ? 'null' : json["name"],
        status: json["status"] == null ? 'null' : json["status"],
        address: Address.fromJson(json["address"]),
        profit: Profit.fromJson(json["profit"]),
        nominalPower:
            json["nominalPower"] == null ? '0.00' : json["nominalPower"],
        energyYearEstimate: json["energyYearEstimate"] == null
            ? '0.00'
            : json["energyYearEstimate"],
        designCompany:
            json["designCompany"] == null ? 'null' : json["designCompany"],
        picBig: json["picBig"] == null ? 'null' : json["picBig"],
        picSmall: json["picSmall"] == null ? 'null' : json["picSmall"],
        install: DateTime.parse(json["install"]),
        gts: DateTime.parse(json["gts"]),
      );

  Map<String, dynamic> toJson() => {
        "pid": pid,
        "uid": uid,
        "name": name,
        "status": status,
        "address": address?.toJson(),
        "profit": profit?.toJson(),
        "nominalPower": nominalPower,
        "energyYearEstimate": energyYearEstimate,
        "designCompany": designCompany,
        "picBig": picBig,
        "picSmall": picSmall,
        "install": install?.toIso8601String(),
        "gts": gts?.toIso8601String(),
      };
}

class Address {
  Address({
    this.country,
    this.province,
    this.city,
    this.county,
    this.town,
    this.village,
    this.address,
    this.lon,
    this.lat,
    this.timezone,
  });

  String? country;
  String? province;
  String? city;
  String? county;
  String? town;
  String? village;
  String? address;
  String? lon;
  String? lat;
  int? timezone;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        country: json["country"] == null ? 'null' : json["country"],
        province: json["province"] == null ? 'null' : json["province"],
        city: json["city"] == null ? 'null' : json["city"],
        county: json["county"] == null ? 'null' : json["county"],
        town: json["town"] == null ? 'null' : json["town"],
        village: json["village"] == null ? 'null' : json["village"],
        address: json["address"] == null ? 'null' : json["address"],
        lon: json["lon"] == null ? 'null' : json["lon"],
        lat: json["lat"] == null ? 'null' : json["lat"],
        timezone: json["timezone"] == null ? 'null' : json["timezone"],
      );

  Map<String, dynamic> toJson() => {
        "country": country,
        "province": province,
        "city": city,
        "county": county,
        "town": town,
        "village": village,
        "address": address,
        "lon": lon,
        "lat": lat,
        "timezone": timezone,
      };
}

class Profit {
  Profit({
    this.unitProfit,
    this.currency,
    this.currencyCountry,
    this.coal,
    this.co2,
    this.so2,
  });

  String? unitProfit;
  String? currency;
  String? currencyCountry;
  String? coal;
  String? co2;
  String? so2;

  factory Profit.fromJson(Map<String, dynamic> json) => Profit(
        unitProfit: json["unitProfit"] == null ? 'null' : json["unitProfit"],
        currency: json["currency"] == null ? 'null' : json["currency"],
        currencyCountry:
            json["currencyCountry"] == null ? 'null' : json["currencyCountry"],
        coal: json["coal"] == null ? 'null' : json["coal"],
        co2: json["co2"] == null ? 'null' : json["co2"],
        so2: json["so2"] == null ? 'null' : json["so2"],
      );

  Map<String, dynamic> toJson() => {
        "unitProfit": unitProfit,
        "currency": currency,
        "currencyCountry": currencyCountry,
        "coal": coal,
        "co2": co2,
        "so2": so2,
      };
}
