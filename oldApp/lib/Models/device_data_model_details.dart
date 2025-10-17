// To parse this JSON data, do
//
//     final devlceDataModelDetails = devlceDataModelDetailsFromJson(jsonString);

import 'dart:convert';

DevlceDataModelDetails devlceDataModelDetailsFromJson(String str) =>
    DevlceDataModelDetails.fromJson(json.decode(str));

String devlceDataModelDetailsToJson(DevlceDataModelDetails data) =>
    json.encode(data.toJson());

class DevlceDataModelDetails {
  int err;
  String desc;
  Dat dat;

  DevlceDataModelDetails({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory DevlceDataModelDetails.fromJson(Map<String, dynamic> json) =>
      DevlceDataModelDetails(
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
  List<Device> device;

  Dat({
    required this.total,
    required this.page,
    required this.pagesize,
    required this.device,
  });

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        total: json["total"],
        page: json["page"],
        pagesize: json["pagesize"],
        device:
            List<Device>.from(json["device"].map((x) => Device.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "pagesize": pagesize,
        "device": List<dynamic>.from(device.map((x) => x.toJson())),
      };
}

class Device {
  String devalias;
  String sn;
  int status;
  int brand;
  String devtype;
  String collalias;
  String pn;
  int devaddr;
  int devcode;
  String usr;
  int uid;
  String profitToday;
  String profitTotal;
  String buyProfitToday;
  String buyProfitTotal;
  String sellProfitToday;
  String sellProfitTotal;
  int pid;
  bool focus;
  String outpower;
  String energyToday;
  String energyYear;
  String energyTotal;
  String buyEnergyToday;
  String buyEnergyTotal;
  String sellEnergyToday;
  String sellEnergyTotal;

  Device({
    required this.devalias,
    required this.sn,
    required this.status,
    required this.brand,
    required this.devtype,
    required this.collalias,
    required this.pn,
    required this.devaddr,
    required this.devcode,
    required this.usr,
    required this.uid,
    required this.profitToday,
    required this.profitTotal,
    required this.buyProfitToday,
    required this.buyProfitTotal,
    required this.sellProfitToday,
    required this.sellProfitTotal,
    required this.pid,
    required this.focus,
    required this.outpower,
    required this.energyToday,
    required this.energyYear,
    required this.energyTotal,
    required this.buyEnergyToday,
    required this.buyEnergyTotal,
    required this.sellEnergyToday,
    required this.sellEnergyTotal,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        devalias: json["devalias"],
        sn: json["sn"],
        status: json["status"],
        brand: json["brand"],
        devtype: json["devtype"],
        collalias: json["collalias"],
        pn: json["pn"],
        devaddr: json["devaddr"],
        devcode: json["devcode"],
        usr: json["usr"],
        uid: json["uid"],
        profitToday: json["profitToday"],
        profitTotal: json["profitTotal"],
        buyProfitToday: json["buyProfitToday"],
        buyProfitTotal: json["buyProfitTotal"],
        sellProfitToday: json["sellProfitToday"],
        sellProfitTotal: json["sellProfitTotal"],
        pid: json["pid"],
        focus: json["focus"],
        outpower: json["outpower"],
        energyToday: json["energyToday"],
        energyYear: json["energyYear"],
        energyTotal: json["energyTotal"],
        buyEnergyToday: json["buyEnergyToday"],
        buyEnergyTotal: json["buyEnergyTotal"],
        sellEnergyToday: json["sellEnergyToday"],
        sellEnergyTotal: json["sellEnergyTotal"],
      );

  Map<String, dynamic> toJson() => {
        "devalias": devalias,
        "sn": sn,
        "status": status,
        "brand": brand,
        "devtype": devtype,
        "collalias": collalias,
        "pn": pn,
        "devaddr": devaddr,
        "devcode": devcode,
        "usr": usr,
        "uid": uid,
        "profitToday": profitToday,
        "profitTotal": profitTotal,
        "buyProfitToday": buyProfitToday,
        "buyProfitTotal": buyProfitTotal,
        "sellProfitToday": sellProfitToday,
        "sellProfitTotal": sellProfitTotal,
        "pid": pid,
        "focus": focus,
        "outpower": outpower,
        "energyToday": energyToday,
        "energyYear": energyYear,
        "energyTotal": energyTotal,
        "buyEnergyToday": buyEnergyToday,
        "buyEnergyTotal": buyEnergyTotal,
        "sellEnergyToday": sellEnergyToday,
        "sellEnergyTotal": sellEnergyTotal,
      };
}
