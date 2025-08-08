class DeviceLiveSignalModel {
  final double? inputVoltage;
  final double? inputCurrent;
  final double? outputVoltage;
  final double? outputCurrent;
  final double? inputPower;
  final double? outputPower;
  final double? signalStrength;
  final double? batteryLevel; // Added battery level
  final DateTime? timestamp;
  final int? status;
  final String? desc;

  DeviceLiveSignalModel({
    this.inputVoltage,
    this.inputCurrent,
    this.outputVoltage,
    this.outputCurrent,
    this.inputPower,
    this.outputPower,
    this.signalStrength,
    this.batteryLevel, // Added battery level
    this.timestamp,
    this.status,
    this.desc,
  });

  factory DeviceLiveSignalModel.fromJson(Map<String, dynamic> json) {
    return DeviceLiveSignalModel(
      inputVoltage: (json['inputVoltage'] ?? json['vin'])?.toDouble(),
      inputCurrent: (json['inputCurrent'] ?? json['iin'])?.toDouble(),
      outputVoltage: (json['outputVoltage'] ?? json['vout'])?.toDouble(),
      outputCurrent: (json['outputCurrent'] ?? json['iout'])?.toDouble(),
      inputPower: (json['inputPower'] ?? json['pin'])?.toDouble(),
      outputPower: (json['outputPower'] ?? json['pout'])?.toDouble(),
      signalStrength: (json['signalStrength'] ?? json['signal'])?.toDouble(),
      batteryLevel:
          (json['batteryLevel'] ?? json['soc'] ?? json['SOC'])?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      status: json['err'],
      desc: json['desc'],
    );
  }
}
