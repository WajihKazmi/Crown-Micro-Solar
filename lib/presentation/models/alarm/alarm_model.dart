class Alarm {
  final String id;
  final String deviceId;
  final String plantId;
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final bool isActive;
  final Map<String, dynamic> parameters;

  Alarm({
    required this.id,
    required this.deviceId,
    required this.plantId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.isActive,
    required this.parameters,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      plantId: json['plantId'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      parameters: json['parameters'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'plantId': plantId,
      'type': type,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'parameters': parameters,
    };
  }
}

class Warning {
  final String id;
  final String deviceId;
  final String plantId;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool isActive;
  final Map<String, dynamic> parameters;

  Warning({
    required this.id,
    required this.deviceId,
    required this.plantId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isActive,
    required this.parameters,
  });

  factory Warning.fromJson(Map<String, dynamic> json) {
    // Parse date strings safely
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == "0" || dateStr == "0.0000") {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing warning date: $dateStr, error: $e');
        return DateTime.now();
      }
    }

    return Warning(
      id: json['id']?.toString() ?? json['sn']?.toString() ?? '',
      deviceId: json['sn']?.toString() ?? '',
      plantId: json['plantid']?.toString() ?? '',
      type: json['type']?.toString() ?? json['warningtype']?.toString() ?? '',
      message: json['message']?.toString() ?? json['warningmsg']?.toString() ?? '',
      timestamp: parseDate(json['timestamp'] ?? json['warningtime']),
      isActive: json['isActive'] ?? json['active'] ?? true,
      parameters: json, // Store all warning parameters
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'plantId': plantId,
      'type': type,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'parameters': parameters,
    };
  }
} 