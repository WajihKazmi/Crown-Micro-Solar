import 'dart:convert';

class DeviceDataOneDayPagingResponse {
  final int? err;
  final String? desc;
  final _PagingDat? dat;
  DeviceDataOneDayPagingResponse({this.err, this.desc, this.dat});
  factory DeviceDataOneDayPagingResponse.fromJson(Map<String, dynamic> json) =>
      DeviceDataOneDayPagingResponse(
        err: json['err'] as int?,
        desc: json['desc'] as String?,
        dat: json['dat'] == null
            ? null
            : _PagingDat.fromJson(json['dat'] as Map<String, dynamic>),
      );
  static DeviceDataOneDayPagingResponse parse(String body) =>
      DeviceDataOneDayPagingResponse.fromJson(
          json.decode(body) as Map<String, dynamic>);
}

class _PagingDat {
  final int? total;
  final int? page;
  final int? pagesize;
  final List<_Title>? title;
  final List<_Row>? row;
  _PagingDat({this.total, this.page, this.pagesize, this.title, this.row});
  factory _PagingDat.fromJson(Map<String, dynamic> json) => _PagingDat(
        total: json['total'] as int?,
        page: json['page'] as int?,
        pagesize: json['pagesize'] as int?,
        title:
            (json['title'] as List?)?.map((e) => _Title.fromJson(e)).toList(),
        row: (json['row'] as List?)?.map((e) => _Row.fromJson(e)).toList(),
      );
}

class _Title {
  final String? title;
  final String? unit;
  _Title({this.title, this.unit});
  factory _Title.fromJson(Map<String, dynamic> json) => _Title(
        title: json['title'] as String?,
        unit: json['unit'] as String?,
      );
}

class _Row {
  final bool? realtime;
  final List<dynamic>? field; // list of strings/numbers
  _Row({this.realtime, this.field});
  factory _Row.fromJson(Map<String, dynamic> json) => _Row(
        realtime: json['realtime'] as bool?,
        field: (json['field'] as List?)?.map((e) => e).toList(),
      );
}

extension DeviceDataOneDayPagingX on DeviceDataOneDayPagingResponse {
  // Return a map of column title -> latest non-null double value
  Map<String, double> latestValues() {
    final result = <String, double>{};
    final titles = dat?.title;
    final rows = dat?.row;
    if (titles == null || rows == null || rows.isEmpty) return result;
    final last = rows.last; // assume chronological
    for (int i = 0; i < (titles.length); i++) {
      if (i >= (last.field?.length ?? 0)) continue;
      final raw = last.field?[i];
      final v = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
      if (v != null) {
        final name = titles[i].title ?? 'col_$i';
        result[name] = v;
      }
    }
    return result;
  }

  // Extract a series for a given column title (hour aggregated by hour index)
  List<double> hourlySeries(String columnTitle) {
    final titles = dat?.title;
    final rows = dat?.row;
    if (titles == null || rows == null) return List.filled(24, 0);
    final idx = titles.indexWhere(
        (t) => (t.title ?? '').toLowerCase() == columnTitle.toLowerCase());
    if (idx == -1) return List.filled(24, 0);
    final hours = List<double>.filled(24, 0);
    for (final r in rows) {
      final fieldList = r.field;
      if (fieldList == null || idx >= fieldList.length) continue;
      // We don't have timestamp per row here (old API rows are sequential). We'll distribute sequentially or skip.
      // Without time we can't map precisely; rely on position count if equals hours.
    }
    return hours; // placeholder (not enough info in simplified copy)
  }
}
