class PowerStationQueryResponse {
  final String stationId;
  final String name;
  final String location;
  final double totalCapacity;
  final double currentOutput;
  final List<PowerStationDevice> devices;
  final PowerStationStatus status;
  final Map<String, dynamic> metrics;

  PowerStationQueryResponse({
    required this.stationId,
    required this.name,
    required this.location,
    required this.totalCapacity,
    required this.currentOutput,
    required this.devices,
    required this.status,
    required this.metrics,
  });

  factory PowerStationQueryResponse.fromJson(Map<String, dynamic> json) {
    return PowerStationQueryResponse(
      stationId: json['stationId'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      totalCapacity: (json['totalCapacity'] ?? 0.0).toDouble(),
      currentOutput: (json['currentOutput'] ?? 0.0).toDouble(),
      devices: (json['devices'] as List<dynamic>?)
          ?.map((device) => PowerStationDevice.fromJson(device))
          .toList() ?? [],
      status: PowerStationStatus.fromJson(json['status'] ?? {}),
      metrics: json['metrics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'name': name,
      'location': location,
      'totalCapacity': totalCapacity,
      'currentOutput': currentOutput,
      'devices': devices.map((device) => device.toJson()).toList(),
      'status': status.toJson(),
      'metrics': metrics,
    };
  }
}

class PowerStationDevice {
  final String deviceId;
  final String name;
  final String type;
  final double capacity;
  final double currentOutput;
  final String status;

  PowerStationDevice({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.capacity,
    required this.currentOutput,
    required this.status,
  });

  factory PowerStationDevice.fromJson(Map<String, dynamic> json) {
    return PowerStationDevice(
      deviceId: json['deviceId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      capacity: (json['capacity'] ?? 0.0).toDouble(),
      currentOutput: (json['currentOutput'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'type': type,
      'capacity': capacity,
      'currentOutput': currentOutput,
      'status': status,
    };
  }
}

class PowerStationStatus {
  final String overallStatus;
  final int activeDevices;
  final int totalDevices;
  final List<String> alerts;
  final DateTime lastUpdate;

  PowerStationStatus({
    required this.overallStatus,
    required this.activeDevices,
    required this.totalDevices,
    required this.alerts,
    required this.lastUpdate,
  });

  factory PowerStationStatus.fromJson(Map<String, dynamic> json) {
    return PowerStationStatus(
      overallStatus: json['overallStatus'] ?? '',
      activeDevices: json['activeDevices'] ?? 0,
      totalDevices: json['totalDevices'] ?? 0,
      alerts: (json['alerts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStatus': overallStatus,
      'activeDevices': activeDevices,
      'totalDevices': totalDevices,
      'alerts': alerts,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
} 