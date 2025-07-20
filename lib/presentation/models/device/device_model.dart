import 'dart:convert';

class Device {
  final String id;
  final String pn;
  final int devcode;
  final int devaddr;
  final String sn;
  final String alias;
  final int status;
  final int uid;
  final int pid;
  final int timezone;
  final String name;
  final String type;
  final String plantId;
  final DateTime lastUpdate;
  final double currentPower;
  final double dailyGeneration;
  final double monthlyGeneration;
  final double yearlyGeneration;
  final Map<String, dynamic> parameters;
  
  // Additional fields for collectors (from old app)
  final int? datFetch;
  final int? load;
  final String? firmware;
  final double? signal;
  final String? descx;
  final double? unitProfit;
  final double? buyProfit;
  final double? sellProfit;
  final String? currency;

  Device({
    required this.id,
    required this.pn,
    required this.devcode,
    required this.devaddr,
    required this.sn,
    required this.alias,
    required this.status,
    required this.uid,
    required this.pid,
    required this.timezone,
    required this.name,
    required this.type,
    required this.plantId,
    required this.lastUpdate,
    this.currentPower = 0.0,
    this.dailyGeneration = 0.0,
    this.monthlyGeneration = 0.0,
    this.yearlyGeneration = 0.0,
    required this.parameters,
    this.datFetch,
    this.load,
    this.firmware,
    this.signal,
    this.descx,
    this.unitProfit,
    this.buyProfit,
    this.sellProfit,
    this.currency,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    // Handle both device and collector JSON structures
    final isCollector = json['datFetch'] != null || json['load'] != null;
    
    return Device(
      id: json['pn']?.toString() ?? '',
      pn: json['pn']?.toString() ?? '',
      devcode: json['devcode'] ?? (isCollector ? -1 : 0),
      devaddr: json['devaddr'] ?? 0,
      sn: json['sn']?.toString() ?? '',
      alias: json['alias']?.toString() ?? json['devalias']?.toString() ?? '',
      status: json['status'] ?? 0,
      uid: json['uid'] ?? 0,
      pid: json['pid'] ?? 0,
      timezone: json['timezone'] ?? 0,
      name: json['alias']?.toString() ?? json['devalias']?.toString() ?? '',
      type: _getDeviceType(json['devcode']),
      plantId: json['pid']?.toString() ?? '',
      lastUpdate: DateTime.now(), // Will be updated with real-time data
      parameters: {
        'pn': json['pn']?.toString() ?? '',
        'sn': json['sn']?.toString() ?? '',
        'devcode': json['devcode']?.toString() ?? '',
        'devaddr': json['devaddr']?.toString() ?? '',
        'token': '', // Will be set from SharedPreferences
        'Secret': '', // Will be set from SharedPreferences
      },
      // Collector-specific fields
      datFetch: json['datFetch'],
      load: json['load'],
      firmware: json['fireware']?.toString() ?? json['firmware']?.toString(),
      signal: json['signal'] != null ? double.tryParse(json['signal'].toString()) : null,
      descx: json['descx']?.toString(),
      unitProfit: json['unitProfit'] != null ? double.tryParse(json['unitProfit'].toString()) : null,
      buyProfit: json['buyProfit'] != null ? double.tryParse(json['buyProfit'].toString()) : null,
      sellProfit: json['sellProfit'] != null ? double.tryParse(json['sellProfit'].toString()) : null,
      currency: json['currency']?.toString(),
    );
  }

  static String _getDeviceType(int? devcode) {
    if (devcode == null) return 'Unknown';
    
    switch (devcode) {
      case 512:
        return 'Inverter';
      case 768:
        return 'Env-monitor';
      case 1024:
        return 'Smart meter';
      case 1280:
        return 'Combining manifolds';
      case 1536:
        return 'Camera';
      case 1792:
        return 'Battery';
      case 2048:
        return 'Charger';
      case 2304:
      case 2452:
      case 2449:
      case 2400:
        return 'Energy storage machine';
      case 2560:
        return 'Anti-islanding';
      case -1:
        return 'Datalogger';
      default:
        return 'Device $devcode';
    }
  }

  String getStatusText() {
    switch (status) {
      case 0:
        return 'Online';
      case 1:
        return 'Offline';
      case 2:
        return 'Fault';
      case 3:
        return 'Standby';
      case 4:
        return 'Warning';
      case 5:
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  bool get isOnline => status == 0;
  bool get isCollector => devcode == -1 || datFetch != null;
  bool get isInverter => devcode == 512;
  bool get isEnvMonitor => devcode == 768;
  bool get isSmartMeter => devcode == 1024;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pn': pn,
    'devcode': devcode,
    'devaddr': devaddr,
    'sn': sn,
    'alias': alias,
    'status': status,
    'uid': uid,
    'pid': pid,
    'timezone': timezone,
    'name': name,
    'type': type,
    'plantId': plantId,
    'lastUpdate': lastUpdate.toIso8601String(),
    'currentPower': currentPower,
    'dailyGeneration': dailyGeneration,
    'monthlyGeneration': monthlyGeneration,
    'yearlyGeneration': yearlyGeneration,
    'parameters': parameters,
    'datFetch': datFetch,
    'load': load,
    'firmware': firmware,
    'signal': signal,
    'descx': descx,
    'unitProfit': unitProfit,
    'buyProfit': buyProfit,
    'sellProfit': sellProfit,
    'currency': currency,
  };

  Device copyWith({
    String? id,
    String? pn,
    int? devcode,
    int? devaddr,
    String? sn,
    String? alias,
    int? status,
    int? uid,
    int? pid,
    int? timezone,
    String? name,
    String? type,
    String? plantId,
    DateTime? lastUpdate,
    double? currentPower,
    double? dailyGeneration,
    double? monthlyGeneration,
    double? yearlyGeneration,
    Map<String, dynamic>? parameters,
    int? datFetch,
    int? load,
    String? firmware,
    double? signal,
    String? descx,
    double? unitProfit,
    double? buyProfit,
    double? sellProfit,
    String? currency,
  }) {
    return Device(
      id: id ?? this.id,
      pn: pn ?? this.pn,
      devcode: devcode ?? this.devcode,
      devaddr: devaddr ?? this.devaddr,
      sn: sn ?? this.sn,
      alias: alias ?? this.alias,
      status: status ?? this.status,
      uid: uid ?? this.uid,
      pid: pid ?? this.pid,
      timezone: timezone ?? this.timezone,
      name: name ?? this.name,
      type: type ?? this.type,
      plantId: plantId ?? this.plantId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      currentPower: currentPower ?? this.currentPower,
      dailyGeneration: dailyGeneration ?? this.dailyGeneration,
      monthlyGeneration: monthlyGeneration ?? this.monthlyGeneration,
      yearlyGeneration: yearlyGeneration ?? this.yearlyGeneration,
      parameters: parameters ?? this.parameters,
      datFetch: datFetch ?? this.datFetch,
      load: load ?? this.load,
      firmware: firmware ?? this.firmware,
      signal: signal ?? this.signal,
      descx: descx ?? this.descx,
      unitProfit: unitProfit ?? this.unitProfit,
      buyProfit: buyProfit ?? this.buyProfit,
      sellProfit: sellProfit ?? this.sellProfit,
      currency: currency ?? this.currency,
    );
  }
} 