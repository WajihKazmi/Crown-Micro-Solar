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

  // Extended fields for Plant Info screen
  final String? company;
  final double? plannedPower;
  final String? establishmentDate;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? town;
  final String? village;
  final String? timezone;
  final String? address;
  final double? latitude;
  final double? longitude;

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
    this.company,
    this.plannedPower,
    this.establishmentDate,
    this.country,
    this.province,
    this.city,
    this.district,
    this.town,
    this.village,
    this.timezone,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    print('Plant.fromJson: Parsing plant data: $json');

    // Handle nested address object
    final addressData = json['address'] as Map<String, dynamic>? ?? {};

    // Parse date strings safely
    DateTime parseDate(String? dateStr) {
      if (dateStr == null ||
          dateStr.isEmpty ||
          dateStr == "0" ||
          dateStr == "0.0000") {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $dateStr, error: $e');
        return DateTime.now();
      }
    }

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

    try {
      // Special handling for plant ID - critical for subsequent API calls
      String plantId = json['pid']?.toString() ?? '';
      if (plantId.isEmpty) {
        print(
            'WARNING: Plant ID is empty! Attempting to find ID in raw JSON: $json');
        // Last attempt to find any ID in the data
        if (json.containsKey('id')) {
          plantId = json['id']?.toString() ?? '';
          print('Found alternative ID field: $plantId');
        }
      }

      if (plantId.isEmpty) {
        print('CRITICAL ERROR: Could not find valid plant ID in response');
      }

      final plant = Plant(
        id: plantId,
        name: json['name']?.toString() ?? '',
        location: addressData['address']?.toString() ?? '',
        capacity: parseDouble(json['nominalPower']),
        status: json['status']?.toString() ?? '1',
        lastUpdate: parseDate(json['energyDate']),
        currentPower: parseDouble(json['outputPower']),
        dailyGeneration: parseDouble(json['energy']),
        monthlyGeneration: parseDouble(json['energyMonth']),
        yearlyGeneration: parseDouble(json['energyYear']),
        company: json['designCompany']?.toString(),
        plannedPower: parseDouble(json['nominalPower']),
        establishmentDate: json['install']?.toString(),
        country: addressData['country']?.toString(),
        province: addressData['province']?.toString(),
        city: addressData['city']?.toString(),
        district: addressData['county']?.toString(),
        town: addressData['town']?.toString(),
        village: addressData['village']?.toString(),
        timezone: addressData['timezone']?.toString(),
        address: addressData['address']?.toString(),
        latitude: parseDouble(addressData['lat']),
        longitude: parseDouble(addressData['lon']),
      );
      print('Plant.fromJson: Successfully created plant: ${plant.name}');
      return plant;
    } catch (e) {
      print('Plant.fromJson: Error creating plant: $e');
      rethrow;
    }
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
      'company': company,
      'plannedPower': plannedPower,
      'establishmentDate': establishmentDate,
      'country': country,
      'province': province,
      'city': city,
      'district': district,
      'town': town,
      'village': village,
      'timezone': timezone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
