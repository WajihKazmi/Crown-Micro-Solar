class DeviceDataOneDayQueryModel {
  final int? err;
  final String? desc;
  final DeviceDataOneDayQueryData? dat;

  DeviceDataOneDayQueryModel({this.err, this.desc, this.dat});

  factory DeviceDataOneDayQueryModel.fromJson(Map<String, dynamic> json) {
    return DeviceDataOneDayQueryModel(
      err: json['err'],
      desc: json['desc'],
      dat: json['dat'] != null ? DeviceDataOneDayQueryData.fromJson(json['dat']) : null,
    );
  }
}

class DeviceDataOneDayQueryData {
  final int? total;
  final List<DeviceDataOneDayRow>? row;
  final List<DeviceDataOneDayTitle>? title;

  DeviceDataOneDayQueryData({this.total, this.row, this.title});

  factory DeviceDataOneDayQueryData.fromJson(Map<String, dynamic> json) {
    return DeviceDataOneDayQueryData(
      total: json['total'],
      row: (json['row'] as List?)?.map((e) => DeviceDataOneDayRow.fromJson(e)).toList(),
      title: (json['title'] as List?)?.map((e) => DeviceDataOneDayTitle.fromJson(e)).toList(),
    );
  }
}

class DeviceDataOneDayRow {
  final List<dynamic>? field;
  DeviceDataOneDayRow({this.field});
  factory DeviceDataOneDayRow.fromJson(Map<String, dynamic> json) {
    return DeviceDataOneDayRow(field: json['field']);
  }
}

class DeviceDataOneDayTitle {
  final String? title;
  final String? unit;
  DeviceDataOneDayTitle({this.title, this.unit});
  factory DeviceDataOneDayTitle.fromJson(Map<String, dynamic> json) {
    return DeviceDataOneDayTitle(
      title: json['title'],
      unit: json['unit'],
    );
  }
} 