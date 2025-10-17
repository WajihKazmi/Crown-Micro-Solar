// To parse this JSON data, do
//
//     final devlceDataModel = devlceDataModelFromJson(jsonString);

import 'dart:convert';

DevlceDataModel devlceDataModelFromJson(String str) =>
    DevlceDataModel.fromJson(json.decode(str));

String devlceDataModelToJson(DevlceDataModel data) =>
    json.encode(data.toJson());

class DevlceDataModel {
  int err;
  String desc;
  Dat dat;

  DevlceDataModel({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory DevlceDataModel.fromJson(Map<String, dynamic> json) =>
      DevlceDataModel(
        err: json["err"],
        desc: json["desc"],
        dat: Dat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err,
        "desc": desc,
        "dat": dat.toJson(),
      };
}

class Dat {
  int total;
  int page;
  int pagesize;
  List<Collector> collector;

  Dat({
    required this.total,
    required this.page,
    required this.pagesize,
    required this.collector,
  });

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"],
        page: json["page"],
        pagesize: json["pagesize"],
        collector: List<Collector>.from(
            json["collector"].map((x) => Collector.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "pagesize": pagesize,
        "collector": List<dynamic>.from(collector.map((x) => x.toJson())),
      };
}

class Collector {
  String alias;
  String pn;
  String descx;
  int status;
  String fireware;
  int pid;
  String pname;
  String signal;
  int load;
  String balance;
  String usr;
  int uid;
  int did;
  double unitProfit;
  double buyProfit;
  double sellProfit;
  String edate;
  int timeZone;
  int activationStatus;

  Collector({
    required this.alias,
    required this.pn,
    required this.descx,
    required this.status,
    required this.fireware,
    required this.pid,
    required this.pname,
    required this.signal,
    required this.load,
    required this.balance,
    required this.usr,
    required this.uid,
    required this.did,
    required this.unitProfit,
    required this.buyProfit,
    required this.sellProfit,
    required this.edate,
    required this.timeZone,
    required this.activationStatus,
  });

  factory Collector.fromJson(Map<String, dynamic> json) => Collector(
        alias: json["alias"] ?? "",
        pn: json["pn"] ?? "",
        descx: json["descx"] ?? "",
        status: json["status"],
        fireware: json["fireware"] ?? "",
        pid: json["pid"],
        pname: json["pname"] ?? "",
        signal: json["signal"] ?? "",
        load: json["load"],
        balance: json["balance"],
        usr: json["usr"],
        uid: json["uid"],
        did: json["did"],
        unitProfit: json["unitProfit"],
        buyProfit: json["buyProfit"],
        sellProfit: json["sellProfit"],
        edate: json["edate"],
        timeZone: json["timeZone"],
        activationStatus: json["activationStatus"],
      );

  Map<String, dynamic> toJson() => {
        "alias": alias,
        "pn": pn,
        "descx": descx,
        "status": status,
        "fireware": fireware,
        "pid": pid,
        "pname": pname,
        "signal": signal,
        "load": load,
        "balance": balance,
        "usr": usr,
        "uid": uid,
        "did": did,
        "unitProfit": unitProfit,
        "buyProfit": buyProfit,
        "sellProfit": sellProfit,
        "edate": edate,
        "timeZone": timeZone,
        "activationStatus": activationStatus,
      };
}
