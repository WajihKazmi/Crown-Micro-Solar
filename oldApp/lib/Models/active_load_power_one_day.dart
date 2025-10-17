// To parse this JSON data, do
//
//     final activeLoadOutputPower = activeLoadOutputPowerFromJson(jsonString);

import 'dart:convert';

ActiveLoadOutputPower activeLoadOutputPowerFromJson(String str) =>
    ActiveLoadOutputPower.fromJson(json.decode(str));

String activeLoadOutputPowerToJson(ActiveLoadOutputPower data) =>
    json.encode(data.toJson());

class ActiveLoadOutputPower {
  int err;
  String desc;
  LoadPowerDat dat;

  ActiveLoadOutputPower({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory ActiveLoadOutputPower.fromJson(Map<String, dynamic> json) =>
      ActiveLoadOutputPower(
        err: json["err"],
        desc: json["desc"],
        dat: LoadPowerDat.fromJson(json["dat"]),
      );

  Map<String, dynamic> toJson() => {
        "err": err,
        "desc": desc,
        "dat": dat.toJson(),
      };
}

class LoadPowerDat {
  List<LoadPowerDetail> detail;

  LoadPowerDat({
    required this.detail,
  });

  factory LoadPowerDat.fromJson(Map<String, dynamic> json) => LoadPowerDat(
        detail: List<LoadPowerDetail>.from(
            json["detail"].map((x) => LoadPowerDetail.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "detail": List<dynamic>.from(detail.map((x) => x.toJson())),
      };
}

class LoadPowerDetail {
  String val;
  DateTime ts;

  LoadPowerDetail({
    required this.val,
    required this.ts,
  });

  factory LoadPowerDetail.fromJson(Map<String, dynamic> json) =>
      LoadPowerDetail(
        val: json["val"],
        ts: DateTime.parse(json["ts"]),
      );

  Map<String, dynamic> toJson() => {
        "val": val,
        "ts": ts.toIso8601String(),
      };
}
