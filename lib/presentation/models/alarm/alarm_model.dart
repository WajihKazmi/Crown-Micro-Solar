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
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
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
  final String sn;
  final String pn;
  final int devcode;
  final String desc;
  final int level;
  final String code;
  final DateTime gts;
  final bool handle;

  Warning({
    required this.id,
    required this.sn,
    required this.pn,
    required this.devcode,
    required this.desc,
    required this.level,
    required this.code,
    required this.gts,
    required this.handle,
  });

  factory Warning.fromJson(Map<String, dynamic> json) {
    // Parse date from timestamp
    DateTime parseGts(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      try {
        if (timestamp is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else if (timestamp is String) {
          return DateTime.parse(timestamp);
        }
        return DateTime.now();
      } catch (e) {
        print('Error parsing warning timestamp: $timestamp, error: $e');
        return DateTime.now();
      }
    }

    String resolveId(Map<String, dynamic> j) {
      final candidates = ['id', 'wid', 'warningId', 'warnId'];
      for (final k in candidates) {
        final v = j[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return '';
    }

    return Warning(
      id: resolveId(json),
      sn: json['sn']?.toString() ?? '',
      pn: json['pn']?.toString() ?? '',
      devcode: json['devcode'] ?? 0,
      desc: json['desc']?.toString() ?? '',
      level: json['level'] ?? 0,
      code: (() {
        final v = json['code'];
        if (v == null) return '';
        if (v is String) return v;
        return v.toString();
      })(),
      gts: parseGts(json['gts']),
      handle: json['handle'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sn': sn,
      'pn': pn,
      'devcode': devcode,
      'desc': desc,
      'level': level,
      'code': code,
      'gts': gts.millisecondsSinceEpoch,
      'handle': handle,
    };
  }

  // Helper methods for UI display
  String get deviceType {
    switch (devcode) {
      case 530:
        return 'Inverter';
      case 768:
        return 'Env-monitor';
      case 1024:
        return 'Smart meter';
      case 1280:
        return 'Combining manifolds';
      case 1536:
        return 'Camera';
      case 2451:
        return 'Energy storage machine';
      case 1792:
        return 'Battery';
      case 2048:
        return 'Charger';
      case 2452:
      case 2304:
        return 'Energy storage machine';
      case 2560:
        return 'Anti-islanding';
      case -1:
        return 'Datalogger';
      default:
        return devcode.toString();
    }
  }

  String get severityText {
    switch (level) {
      case 0:
        return 'Warning';
      case 1:
        return 'Error';
      case 2:
        return 'Fault';
      default:
        return 'Offline';
    }
  }

  String get statusText {
    return handle ? 'Processed' : 'Untreated';
  }
}
