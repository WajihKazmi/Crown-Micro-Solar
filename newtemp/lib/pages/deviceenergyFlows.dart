import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<dynamic> fetchChartFieldDetailData(
    {required int devcode, required String PN, devadr, SN, Date, field}) async {
  print("----------$Date------------------------");
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=queryDeviceChartFieldDetailData&pn=$PN&devcode=$devcode&sn=$SN&devaddr=$devadr&field=$field&precision=5&sdate=$Date+00:00:00&edate=$Date+23:59:59&i18n=en_US";

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
          action +
          postaction;
  print(url);

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('ChartFieldDetailData REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('ChartFieldDetailData REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          '---------------------------------------------------------------------');
      print(
          'ChartFieldDetailData  REquest APIrequest response : ${jsonResponse}');
      print(
          '---------------------------------------------------------------------');
      print(
          'ChartFieldDetailData  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return jsonResponse;
}

///////////////---------------------/////////////////////

Future<dynamic> fetchkeyparametersfields({required int devcode}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action = "&action=queryDeviceChartField&devcode=$devcode&lang=en_US";

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
          action +
          postaction;

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('queryDeviceChartField REquest  Response Success!! no Error');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('queryDeviceChartField REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          '---------------------------------------------------------------------');
      print(
          'queryDeviceChartField  REquest APIrequest response : ${jsonResponse}');
      print(
          '---------------------------------------------------------------------');
      print(
          'queryDeviceChartField  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return jsonResponse;
}

//////////////---------------------/////////////////////////////

Future<dynamic> fetchdeviceparamES(
    {required String devcode, required String PN, devadr, SN}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  String action =
      "&action=queryDeviceParsEs&source=1&devcode=$devcode&pn=$PN&devaddr=$devadr&sn=$SN&i18n=en_US";
  // "&action=queryDeviceParsEs&source=1&devcode=2452&pn=W0029206442666&devaddr=1&sn=96142303106851&i18n=en_US";

  ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  // String postaction =
  //     "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////

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
        if (jsonResponse['err'] == 0) {
          print('DeviceParsE REquest  Response Success!! no Error');
          print(
              'DeviceParsE REquest response: ${jsonResponse['dat']['total']}');
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('DeviceParsE REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          '---------------------------------------------------------------------');
      print('DeviceParsE  REquest APIrequest response : ${jsonResponse}');
      print(
          '---------------------------------------------------------------------');
      print(
          'DeviceParsE  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return jsonResponse;
}

Future<deviceenergyflows?> fetchdevenrgyflows(
    {required int devcode, required String PN, devadr, SN}) async {
  var jsonResponse = null;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final Secret = prefs.getString('Secret') ?? '';
  String salt = "12345678";
  //Action for specific PID  Status devicetype query
  String action =
      "&action=webQueryDeviceEnergyFlowEs&devcode=$devcode&pn=$PN&devaddr=$devadr&sn=$SN";

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
          action +
          postaction;
  print('DeviceEnergyFlowEs URL: $url');
  //var response = await http.get(Uri.parse(url));
  deviceenergyflows? DEF;

  try {
    await http.post(Uri.parse(url)).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['err'] == 0) {
          print('DeviceEnergyFlowEs REquest  Response Success!! no Error');
          print(
              'DeviceEnergyFlowEs REquest response: ${jsonResponse['dat']['total']}');
          DEF = new deviceenergyflows.fromJson(jsonResponse);
        } else {
          print('${jsonResponse['desc'].toString()}');
        }
      } else if (response.statusCode == 404) {
        print('DeviceEnergyFlowEs REquest  Response Failed !! Error 404');
        jsonResponse = {'err': 404};
      }
      print(
          '---------------------------------------------------------------------');
      print(
          'DeviceEnergyFlowEs  REquest APIrequest response : ${jsonResponse}');
      print(
          '---------------------------------------------------------------------');
      print(
          'DeviceEnergyFlowEs  REquest APIrequest statucode : ${response.statusCode}');
    });
  } catch (e) {
    print(e.toString());
  }

  return DEF;
}

class deviceenergyflows {
  int? err;
  String? desc;
  Dat? dat;

  deviceenergyflows({this.err, this.desc, this.dat});

  deviceenergyflows.fromJson(Map<String, dynamic> json) {
    err = json['err'];
    desc = json['desc'];
    dat = json['dat'] != null ? new Dat.fromJson(json['dat']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['err'] = this.err;
    data['desc'] = this.desc;
    if (this.dat != null) {
      data['dat'] = this.dat!.toJson();
    }
    return data;
  }
}

class Dat {
  int? brand;
  int? status;
  List<BtStatus>? btStatus;
  List<PvStatus>? pvStatus;
  List<GdStatus>? gdStatus;
  List<BcStatus>? bcStatus;
  List<OlStatus>? olStatus;
  List<WeStatus>? weStatus;
  // List<dynamic>? miStatus;
  // List<dynamic>? mtStatus;

  Dat({
    this.brand,
    this.status,
    this.btStatus,
    this.pvStatus,
    this.gdStatus,
    this.bcStatus,
    this.olStatus,
    this.weStatus,
    // this.miStatus,
    // this.mtStatus
  });

  Dat.fromJson(Map<String, dynamic> json) {
    brand = json['brand'];
    status = json['status'];
    if (json['bt_status'] != null) {
      btStatus = <BtStatus>[];
      json['bt_status'].forEach((v) {
        btStatus!.add(new BtStatus.fromJson(v));
      });
    }
    if (json['pv_status'] != null) {
      pvStatus = <PvStatus>[];
      json['pv_status'].forEach((v) {
        pvStatus!.add(new PvStatus.fromJson(v));
      });
    }
    if (json['gd_status'] != null) {
      gdStatus = <GdStatus>[];
      json['gd_status'].forEach((v) {
        gdStatus!.add(new GdStatus.fromJson(v));
      });
    }
    if (json['bc_status'] != null) {
      bcStatus = <BcStatus>[];
      json['bc_status'].forEach((v) {
        bcStatus!.add(new BcStatus.fromJson(v));
      });
    }
    if (json['ol_status'] != null) {
      olStatus = <OlStatus>[];
      json['ol_status'].forEach((v) {
        olStatus!.add(new OlStatus.fromJson(v));
      });
    }
    if (json['we_status'] != null) {
      weStatus = <WeStatus>[];
      json['we_status'].forEach((v) {
        weStatus!.add(new WeStatus.fromJson(v));
      });
    }
    // if (json['mi_status'] != null) {
    //   miStatus = <dynamic>[];
    //   json['mi_status'].forEach((v) {
    //     miStatus!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['mt_status'] != null) {
    //   mtStatus = <dynamic>[];
    //   json['mt_status'].forEach((v) {
    //     mtStatus!.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['brand'] = this.brand;
    data['status'] = this.status;
    if (this.btStatus != null) {
      data['bt_status'] = this.btStatus!.map((v) => v.toJson()).toList();
    }
    if (this.pvStatus != null) {
      data['pv_status'] = this.pvStatus!.map((v) => v.toJson()).toList();
    }
    if (this.gdStatus != null) {
      data['gd_status'] = this.gdStatus!.map((v) => v.toJson()).toList();
    }
    if (this.bcStatus != null) {
      data['bc_status'] = this.bcStatus!.map((v) => v.toJson()).toList();
    }
    if (this.olStatus != null) {
      data['ol_status'] = this.olStatus!.map((v) => v.toJson()).toList();
    }
    if (this.weStatus != null) {
      data['we_status'] = this.weStatus!.map((v) => v.toJson()).toList();
    }
    // if (this.miStatus != null) {
    //   data['mi_status'] = this.miStatus!.map((v) => v.toJson()).toList();
    // }
    // if (this.mtStatus != null) {
    //   data['mt_status'] = this.mtStatus!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class BtStatus {
  String? par;
  String? val;
  String? unit;
  int? status;

  BtStatus({this.par, this.val, this.unit, this.status});

  BtStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    unit = json['unit'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['unit'] = this.unit;
    data['status'] = this.status;
    return data;
  }
}

class PvStatus {
  String? par;
  String? val;
  int? status;

  PvStatus({this.par, this.val, this.status});

  PvStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['status'] = this.status;
    return data;
  }
}

class GdStatus {
  String? par;
  String? val;
  String? unit;
  int? status;

  GdStatus({this.par, this.val, this.unit, this.status});

  GdStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    unit = json['unit'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['unit'] = this.unit;
    data['status'] = this.status;
    return data;
  }
}

class BcStatus {
  String? par;
  String? val;
  String? unit;
  int? status;

  BcStatus({this.par, this.val, this.unit, this.status});

  BcStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    unit = json['unit'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['unit'] = this.unit;
    data['status'] = this.status;
    return data;
  }
}

class OlStatus {
  String? par;
  String? val;
  String? unit;
  int? status;

  OlStatus({this.par, this.val, this.unit, this.status});

  OlStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    unit = json['unit'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['unit'] = this.unit;
    data['status'] = this.status;
    return data;
  }
}

class WeStatus {
  String? par;
  String? val;
  String? unit;
  int? status;

  WeStatus({this.par, this.val, this.unit, this.status});

  WeStatus.fromJson(Map<String, dynamic> json) {
    par = json['par'];
    val = json['val'];
    unit = json['unit'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['par'] = this.par;
    data['val'] = this.val;
    data['unit'] = this.unit;
    data['status'] = this.status;
    return data;
  }
}
