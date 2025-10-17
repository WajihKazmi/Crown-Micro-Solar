// To parse this JSON data, do
//
//     final annualPg2 = annualPg2FromJson(jsonString);

import 'dart:convert';

AnnualPg2 annualPg2FromJson(String str) => AnnualPg2.fromJson(json.decode(str));

String annualPg2ToJson(AnnualPg2 data) => json.encode(data.toJson());

class AnnualPg2 {
  int err;
  String desc;
  Dat dat;

  AnnualPg2({
    required this.err,
    required this.desc,
    required this.dat,
  });

  factory AnnualPg2.fromJson(Map<String, dynamic> json) => AnnualPg2(
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
        gts: _parseYear(json["gts"]),
        val: json["val"],
      );

  Map<String, dynamic> toJson() => {
        "gts": gts.year.toString(),
        "val": val,
      };

  static DateTime _parseYear(String gts) {
    try {
      final year = int.parse(gts);
      return DateTime(year);
    } catch (e) {
      throw FormatException("Invalid year format: $gts");
    }
  }
}
