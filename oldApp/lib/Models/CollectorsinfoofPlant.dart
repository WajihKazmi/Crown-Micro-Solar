import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// To parse this JSON data, do
//
//     final collectorsinfoofPlant = collectorsinfoofPlantFromJson(jsonString);

import 'dart:convert';

CollectorsinfoofPlant collectorsinfoofPlantFromJson(String str) =>
    CollectorsinfoofPlant.fromJson(json.decode(str));

String collectorsinfoofPlantToJson(CollectorsinfoofPlant data) =>
    json.encode(data.toJson());

class CollectorsinfoofPlant {
  CollectorsinfoofPlant({
    this.err,
    this.desc,
    this.dat,
  });

  final int? err;
  final String? desc;
  final Dat? dat;

  factory CollectorsinfoofPlant.fromJson(Map<String, dynamic> json) =>
      CollectorsinfoofPlant(
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
    this.collector,
  });

  final int? total;
  final int? page;
  final int? pagesize;
  final List<Collector>? collector;

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"] == null ? null : json["total"],
        page: json["page"] == null ? null : json["page"],
        pagesize: json["pagesize"] == null ? null : json["pagesize"],
        collector: json["collector"] == null
            ? null
            : List<Collector>.from(
                json["collector"].map((x) => Collector.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total == null ? null : total,
        "page": page == null ? null : page,
        "pagesize": pagesize == null ? null : pagesize,
        "collector": collector == null
            ? null
            : List<dynamic>.from(collector!.map((x) => x.toJson())),
      };
}

class Collector {
  Collector({
    this.pn,
    this.alias,
    this.datFetch,
    this.timezone,
    this.load,
    this.status,
    this.type,
    this.uid,
    this.pid,
    this.firmware,
    this.Signal,
    this.descx,
    this.buyprofit,
    this.currency,
    this.sellprofit,
    this.unitprofit
  });

  final String? pn;
  final String? firmware;
  final String? alias;
  final int? datFetch;
  final int? timezone;
  final int? load;
  final int? status;
  final int? type;
  final int? uid;
  final int? pid;
  //new
  final double? Signal;
  final String? descx;
  final double? unitprofit;
  final double? buyprofit;
  final double? sellprofit;
  final String? currency;

  factory Collector.fromJson(Map<String, dynamic> json) => Collector(
        pn: json["pn"] == null ? null : json["pn"],
        alias: json["alias"] == null ? null : json["alias"],
        datFetch: json["datFetch"] == null ? null : json["datFetch"],
        timezone: json["timezone"] == null ? null : json["timezone"],
        load: json["load"] == null ? null : json["load"],
        status: json["status"] == null ? null : json["status"],
        type: json["type"] == null ? null : json["type"],
        uid: json["uid"] == null ? null : json["uid"],
        pid: json["pid"] == null ? null : json["pid"],
        firmware: json["fireware"] == null ? null : json["fireware"],
        Signal:  json["signal"] == null ? null : double.parse( json["signal"]),
        descx:  json["descx"] == null ? null : json["descx"],
        unitprofit: json["unitProfit"] == null ? null : json["unitProfit"],
        buyprofit:  json["buyProfit"] == null ? null : json["buyProfit"],
        sellprofit: json["sellProfit"] == null ? null : json["sellProfit"],
        currency: json["currency"] == null ? null : json["currency"],
        
      );

  Map<String, dynamic> toJson() => {
        "pn": pn == null ? null : pn,
        "alias": alias == null ? null : alias,
        "datFetch": datFetch == null ? null : datFetch,
        "timezone": timezone == null ? null : timezone,
        "load": load == null ? null : load,
        "status": status == null ? null : status,
        "type": type == null ? null : type,
        "uid": uid == null ? null : uid,
        "pid": pid == null ? null : pid,
      };
}
