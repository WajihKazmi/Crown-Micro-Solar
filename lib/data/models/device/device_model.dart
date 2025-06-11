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
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      plantId: json['plantId'] ?? '',
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
      currentPower: (json['currentPower'] ?? 0.0).toDouble(),
      dailyGeneration: (json['dailyGeneration'] ?? 0.0).toDouble(),
      monthlyGeneration: (json['monthlyGeneration'] ?? 0.0).toDouble(),
      yearlyGeneration: (json['yearlyGeneration'] ?? 0.0).toDouble(),
      parameters: json['parameters'] ?? {},
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