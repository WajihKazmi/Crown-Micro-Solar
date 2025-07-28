class DeviceKeyParameterModel {
  final int? err;
  final String? desc;
  final DeviceKeyParameterData? dat;

  DeviceKeyParameterModel({this.err, this.desc, this.dat});

  factory DeviceKeyParameterModel.fromJson(Map<String, dynamic> json) {
    return DeviceKeyParameterModel(
      err: json['err'],
      desc: json['desc'],
      dat: json['dat'] != null ? DeviceKeyParameterData.fromJson(json['dat']) : null,
    );
  }
}

class DeviceKeyParameterData {
  final int? total;
  final List<DeviceKeyParameterRow>? row;
  final List<DeviceKeyParameterTitle>? title;

  DeviceKeyParameterData({this.total, this.row, this.title});

  factory DeviceKeyParameterData.fromJson(Map<String, dynamic> json) {
    return DeviceKeyParameterData(
      total: json['total'],
      row: (json['row'] as List?)?.map((e) => DeviceKeyParameterRow.fromJson(e)).toList(),
      title: (json['title'] as List?)?.map((e) => DeviceKeyParameterTitle.fromJson(e)).toList(),
    );
  }
}

class DeviceKeyParameterRow {
  final List<dynamic>? field;
  DeviceKeyParameterRow({this.field});
  factory DeviceKeyParameterRow.fromJson(Map<String, dynamic> json) {
    return DeviceKeyParameterRow(field: json['field']);
  }
}

class DeviceKeyParameterTitle {
  final String? title;
  final String? unit;
  DeviceKeyParameterTitle({this.title, this.unit});
  factory DeviceKeyParameterTitle.fromJson(Map<String, dynamic> json) {
    return DeviceKeyParameterTitle(
      title: json['title'],
      unit: json['unit'],
    );
  }
} 