// To parse this JSON data, do
//
//     final dailyPGinMonth2 = dailyPGinMonth2FromJson(jsonString);

import 'dart:convert';

DailyPGinMonth2 dailyPGinMonth2FromJson(String str) =>
    DailyPGinMonth2.fromJson(json.decode(str));

String dailyPGinMonth2ToJson(DailyPGinMonth2 data) =>
    json.encode(data.toJson());

class DailyPGinMonth2 {
  int err;
  String desc;
  Dat dat;

  DailyPGinMonth2({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory DailyPGinMonth2.fromJson(Map<String, dynamic> json) =>
      DailyPGinMonth2(
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
  List<Option> option;

  Dat({
    required this.option,
  });

  factory Dat.fromJson(Map<String, dynamic> json) => Dat(
        option:
            List<Option>.from(json["option"].map((x) => Option.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "option": List<dynamic>.from(option.map((x) => x.toJson())),
      };
}

class Option {
  DateTime gts;
  String val;

  Option({
    required this.gts,
    required this.val,
  });

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        gts: DateTime.parse(json["gts"]),
        val: json["val"],
      );

  Map<String, dynamic> toJson() => {
        "gts":
            "${gts.year.toString().padLeft(4, '0')}-${gts.month.toString().padLeft(2, '0')}-${gts.day.toString().padLeft(2, '0')}",
        "val": val,
      };
}
