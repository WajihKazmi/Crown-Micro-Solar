class Device {
  final String id;
  final String name;
  final String type;
  final String status;
  final String plantId;
  final DateTime lastUpdate;
  final double currentPower;
  final double dailyGeneration;
  final double monthlyGeneration;
  final double yearlyGeneration;
  final Map<String, dynamic> parameters;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.plantId,
    required this.lastUpdate,
    required this.currentPower,
    required this.dailyGeneration,
    required this.monthlyGeneration,
    required this.yearlyGeneration,
    required this.parameters,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    // Parse numeric values safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        if (value.isEmpty || value == "0" || value == "-") return 0.0;
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing double: $value, error: $e');
          return 0.0;
        }
      }
      return 0.0;
    }

    // Parse date strings safely
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == "0" || dateStr == "0.0000") {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $dateStr, error: $e');
        return DateTime.now();
      }
    }

    return Device(
      id: json['sn']?.toString() ?? '', // Use SN as device ID
      name: json['pn']?.toString() ?? '', // Use PN as device name
      type: json['devcode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      plantId: json['plantid']?.toString() ?? '',
      lastUpdate: parseDate(json['lastupdate']),
      currentPower: parseDouble(json['outputpower']),
      dailyGeneration: parseDouble(json['energy']),
      monthlyGeneration: parseDouble(json['energymonth']),
      yearlyGeneration: parseDouble(json['energyyear']),
      parameters: json, // Store all device parameters
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'plantId': plantId,
      'lastUpdate': lastUpdate.toIso8601String(),
      'currentPower': currentPower,
      'dailyGeneration': dailyGeneration,
      'monthlyGeneration': monthlyGeneration,
      'yearlyGeneration': yearlyGeneration,
      'parameters': parameters,
    };
  }
} 