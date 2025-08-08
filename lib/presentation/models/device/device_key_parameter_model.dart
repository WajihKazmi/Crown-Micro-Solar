class DeviceKeyParameterModel {
  final int? err;
  final String? desc;
  final DeviceKeyParameterData? dat;
  final String? source; // Added to track where data came from (API or fallback)

  DeviceKeyParameterModel({this.err, this.desc, this.dat, this.source});

  factory DeviceKeyParameterModel.fromJson(Map<String, dynamic> json) {
    print(
        'DeviceKeyParameterModel.fromJson: Parsing response: ${json.keys.join(', ')}');

    // Check if this is coming from live signal data
    final source = json['source'] ?? 'api';

    return DeviceKeyParameterModel(
      err: json['err'],
      desc: json['desc'],
      source: source,
      dat: json['dat'] != null
          ? DeviceKeyParameterData.fromJson(json['dat'])
          : null,
    );
  }

  // Method to get the latest value from the model
  double getLatestValue() {
    if (dat == null) return 0.0;

    // Check if we have a direct parameter value
    if (dat!.parameter != null) {
      try {
        return double.tryParse(dat!.parameter!) ?? 0.0;
      } catch (e) {
        print('DeviceKeyParameterModel: Error parsing parameter value: $e');
      }
    }

    // If not, try to get value from rows
    if (dat!.row != null && dat!.row!.isNotEmpty) {
      try {
        final lastRow = dat!.row!.last;
        if (lastRow.field != null && lastRow.field!.isNotEmpty) {
          return double.tryParse(lastRow.field!.first.toString()) ?? 0.0;
        }
      } catch (e) {
        print('DeviceKeyParameterModel: Error parsing row field value: $e');
      }
    }

    return 0.0;
  }
}

class DeviceKeyParameterData {
  final String? parameter;
  final String? date;
  final int? total;
  final List<DeviceKeyParameterRow>? row;
  final List<DeviceKeyParameterTitle>? title;

  DeviceKeyParameterData(
      {this.parameter, this.date, this.total, this.row, this.title});

  factory DeviceKeyParameterData.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    if (json.containsKey('parameter')) {
      // New format from test has parameter array
      try {
        print(
            'DeviceKeyParameterModel: Processing parameter array with ${json['parameter']?.length ?? 0} items');

        // Get the latest value if available
        double latestValue = 0.0;
        String latestDate = '';

        if (json['parameter'] != null && json['parameter'].isNotEmpty) {
          // Find the most recent non-zero value if possible
          List<dynamic> parameters = json['parameter'];
          // First try to find any non-zero value
          var nonZeroEntry = parameters.lastWhere(
              (p) =>
                  double.tryParse(p['val'].toString()) != null &&
                  double.parse(p['val'].toString()) > 0.0,
              orElse: () => null);

          // If no non-zero value, take the latest entry
          var entry = nonZeroEntry ?? parameters.last;

          if (entry != null) {
            latestValue = double.tryParse(entry['val'].toString()) ?? 0.0;
            latestDate = entry['ts']?.toString() ?? '';
            print(
                'DeviceKeyParameterModel: Found latest value: $latestValue at $latestDate');
          }
        }

        return DeviceKeyParameterData(
          parameter: latestValue.toString(),
          date: latestDate,
          total: json['parameter']?.length,
          row: json['parameter'] != null
              ? json['parameter']
                  .map<DeviceKeyParameterRow>((p) => DeviceKeyParameterRow(
                      time: p['ts'] != null
                          ? p['ts'].toString().substring(11, 16)
                          : '',
                      field: [p['val']]))
                  .toList()
              : [],
        );
      } catch (e) {
        print('DeviceKeyParameterModel: Error parsing parameter array: $e');
        return DeviceKeyParameterData(
          parameter: '0',
          date: DateTime.now().toString(),
          total: 0,
          row: [],
        );
      }
    } else {
      // Original format
      print('DeviceKeyParameterModel: Using original format parser');
      return DeviceKeyParameterData(
        total: json['total'],
        row: (json['row'] as List?)
            ?.map((e) => DeviceKeyParameterRow.fromJson(e))
            .toList(),
        title: (json['title'] as List?)
            ?.map((e) => DeviceKeyParameterTitle.fromJson(e))
            .toList(),
      );
    }
  }
}

class DeviceKeyParameterRow {
  final String? time;
  final List<dynamic>? field;
  DeviceKeyParameterRow({this.time, this.field});
  factory DeviceKeyParameterRow.fromJson(Map<String, dynamic> json) {
    return DeviceKeyParameterRow(
      time: json['time'],
      field: json['field'],
    );
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
