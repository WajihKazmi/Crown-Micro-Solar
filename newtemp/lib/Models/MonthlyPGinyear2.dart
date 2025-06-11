// To parse this JSON data, do
//
//     final monthlyPGinyear2 = monthlyPGinyear2FromJson(jsonString);

import 'dart:convert';

MonthlyPGinyear2 monthlyPGinyear2FromJson(String str) =>
    MonthlyPGinyear2.fromJson(json.decode(str));

String monthlyPGinyear2ToJson(MonthlyPGinyear2 data) =>
    json.encode(data.toJson());

class MonthlyPGinyear2 {
  int err;
  String desc;
  Dat dat;

  MonthlyPGinyear2({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory MonthlyPGinyear2.fromJson(Map<String, dynamic> json) =>
      MonthlyPGinyear2(
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
        gts: _parseYearMonth(json["gts"]),
        val: json["val"],
      );

  Map<String, dynamic> toJson() => {
        "gts":
            "${gts.year.toString().padLeft(4, '0')}-${gts.month.toString().padLeft(2, '0')}",
        "val": val,
      };

  static DateTime _parseYearMonth(String gts) {
    try {
      final parts = gts.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateTime(year, month);
    } catch (e) {
      throw FormatException("Invalid date format: $gts");
    }
  }
}
