class Plant {
  final String id;
  final String name;
  final String location;
  final double capacity;
  final String status;
  final DateTime lastUpdate;
  final double currentPower;
  final double dailyGeneration;
  final double monthlyGeneration;
  final double yearlyGeneration;

  Plant({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status,
    required this.lastUpdate,
    required this.currentPower,
    required this.dailyGeneration,
    required this.monthlyGeneration,
    required this.yearlyGeneration,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      capacity: (json['capacity'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
      currentPower: (json['currentPower'] ?? 0.0).toDouble(),
      dailyGeneration: (json['dailyGeneration'] ?? 0.0).toDouble(),
      monthlyGeneration: (json['monthlyGeneration'] ?? 0.0).toDouble(),
      yearlyGeneration: (json['yearlyGeneration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'status': status,
      'lastUpdate': lastUpdate.toIso8601String(),
      'currentPower': currentPower,
      'dailyGeneration': dailyGeneration,
      'monthlyGeneration': monthlyGeneration,
      'yearlyGeneration': yearlyGeneration,
    };
  }
} 