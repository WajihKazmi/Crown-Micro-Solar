class EnergyData {
  final String deviceId;
  final DateTime timestamp;
  final double power;
  final double energy;
  final double voltage;
  final double current;
  final double temperature;
  final Map<String, dynamic> additionalData;

  EnergyData({
    required this.deviceId,
    required this.timestamp,
    required this.power,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.additionalData,
  });

  factory EnergyData.fromJson(Map<String, dynamic> json) {
    return EnergyData(
      deviceId: json['deviceId'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      power: (json['power'] ?? 0.0).toDouble(),
      energy: (json['energy'] ?? 0.0).toDouble(),
      voltage: (json['voltage'] ?? 0.0).toDouble(),
      current: (json['current'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      additionalData: json['additionalData'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'power': power,
      'energy': energy,
      'voltage': voltage,
      'current': current,
      'temperature': temperature,
      'additionalData': additionalData,
    };
  }
}

class EnergySummary {
  final String deviceId;
  final DateTime date;
  final double totalEnergy;
  final double peakPower;
  final double averagePower;
  final List<EnergyData> hourlyData;

  EnergySummary({
    required this.deviceId,
    required this.date,
    required this.totalEnergy,
    required this.peakPower,
    required this.averagePower,
    required this.hourlyData,
  });

  factory EnergySummary.fromJson(Map<String, dynamic> json) {
    return EnergySummary(
      deviceId: json['deviceId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      totalEnergy: (json['totalEnergy'] ?? 0.0).toDouble(),
      peakPower: (json['peakPower'] ?? 0.0).toDouble(),
      averagePower: (json['averagePower'] ?? 0.0).toDouble(),
      hourlyData: (json['hourlyData'] as List<dynamic>?)
          ?.map((data) => EnergyData.fromJson(data))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'date': date.toIso8601String(),
      'totalEnergy': totalEnergy,
      'peakPower': peakPower,
      'averagePower': averagePower,
      'hourlyData': hourlyData.map((data) => data.toJson()).toList(),
    };
  }
} 