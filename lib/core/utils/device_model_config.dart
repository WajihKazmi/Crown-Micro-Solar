/// Device Model Configuration
/// Defines popup fields and behavior for different device models (Nova, Elego, Xavier, Arceus)
///
/// Model detection:
/// - Nova: protocol 2451 or 2449, or alias contains "nova"
/// - Elego: protocol 2452, or alias contains "elego"
/// - Xavier: protocol 2451 (disambiguated by alias), or alias contains "xavier"
/// - Arceus: protocol 6451, or alias contains "arceus"
/// - Datalogger: protocol 2547 or 2329
///
/// Each model has specific fields for PV, Battery, Load, and Grid categories

enum DeviceModel {
  nova,
  elego,
  xavier,
  arceus,
  datalogger,
  unknown;

  /// Detect device model from devcode and alias
  static DeviceModel detect({required int devcode, required String alias}) {
    final aliasLower = alias.toLowerCase().trim();

    // Check alias first (most specific)
    if (aliasLower.contains('nova')) return DeviceModel.nova;
    if (aliasLower.contains('elego')) return DeviceModel.elego;
    if (aliasLower.contains('xavier')) return DeviceModel.xavier;
    if (aliasLower.contains('arceus')) return DeviceModel.arceus;

    // Fallback to protocol/devcode patterns (as provided by spec)
    // Arceus
    if (devcode == 6451) return DeviceModel.arceus;
    // Elego
    if (devcode == 2452) return DeviceModel.elego;
    // Nova explicit code
    if (devcode == 2449) return DeviceModel.nova;
    // Xavier vs Nova ambiguity on 2451: prefer Xavier if alias hinted above, otherwise Nova
    if (devcode == 2451) return DeviceModel.nova;
    // Datalogger
    if (devcode == 2547 || devcode == 2329) return DeviceModel.datalogger;

    return DeviceModel.unknown;
  }
}

/// Field configuration for a popup category (PV, Battery, Load, Grid)
class PopupFieldConfig {
  final String label;
  final String unit;
  final List<String> apiCandidates; // Possible API parameter names

  const PopupFieldConfig({
    required this.label,
    required this.unit,
    required this.apiCandidates,
  });
}

/// Model-specific popup configurations
class DeviceModelPopupConfig {
  final DeviceModel model;
  final List<PopupFieldConfig> pvFields;
  final List<PopupFieldConfig> batteryFields;
  final List<PopupFieldConfig> loadFields;
  final List<PopupFieldConfig> gridFields;

  const DeviceModelPopupConfig({
    required this.model,
    required this.pvFields,
    required this.batteryFields,
    required this.loadFields,
    required this.gridFields,
  });

  /// Get fields for a specific category
  List<PopupFieldConfig> getFieldsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'pv':
        return pvFields;
      case 'battery':
        return batteryFields;
      case 'load':
        return loadFields;
      case 'grid':
        return gridFields;
      default:
        return [];
    }
  }

  /// Nova model configuration (dual PV inputs)
  static const nova = DeviceModelPopupConfig(
    model: DeviceModel.nova,
    pvFields: [
      PopupFieldConfig(
        label: 'PV1 Input volts',
        unit: 'V',
        apiCandidates: [
          'PV1 Input Voltage',
          'PV1 Input voltage',
          'PV1 Voltage',
          'PV1 input voltage',
          'PV1 voltage',
          'PV1 Vol',
          'pv1_input_voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'PV2 Input volts',
        unit: 'V',
        apiCandidates: [
          'PV2 Input Voltage',
          'PV2 Input voltage',
          'PV2 Voltage',
          'PV2 input voltage',
          'PV2 voltage',
          'PV2 Vol',
          'pv2_input_voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'PV1 watts',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
          'PV1 Charging power',
          'PV1 Input Power',
          'PV1 Input power',
          'PV1 Active Power',
          'PV1 Power',
          'PV1 power',
          'PV1 input power',
          'pv1_input_power',
          'pv1_power',
        ],
      ),
      PopupFieldConfig(
        label: 'PV2 watts',
        unit: 'W',
        apiCandidates: [
          'PV2 Charging power',
          'PV2 Charging Power',
          'PV2 Input Power',
          'PV2 Input power',
          'PV2 Active Power',
          'PV2 Power',
          'PV2 power',
          'PV2 input power',
          'pv2_input_power',
          'pv2_power',
        ],
      ),
      PopupFieldConfig(
        label: 'PV1 Input Current',
        unit: 'A',
        apiCandidates: [
          'PV1 Input Current',
          'PV1 Input current',
          'PV1 Current',
          'PV1 current',
          'PV1 input current',
          'pv1_input_current',
        ],
      ),
      PopupFieldConfig(
        label: 'PV2 Input Current',
        unit: 'A',
        apiCandidates: [
          'PV2 Input Current',
          'PV2 Input current',
          'PV2 Current',
          'PV2 current',
          'PV2 input current',
          'pv2_input_current',
        ],
      ),
      PopupFieldConfig(
        label: 'PV Output Power',
        unit: 'W',
        apiCandidates: [
          'PV Charging Power',
          'PV Output Power',
          'PV output power',
          'Total PV Power',
          'PV Total Power',
          'PV Power',
          'pv_output_power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Capacity',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
          'Battery capacity',
          'Bat Capacity',
          'Battery SOC',
          'Battery soc',
          'SOC',
          'Soc',
          'Battery Percentage',
          'battery_capacity',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: [
          'Battery Voltage',
          'Battery voltage',
          'Bat Voltage',
          'Battery Vol',
          'Bat Vol',
          'battery_voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery charging current',
          'Battery Charging Current',
          'Charging Current',
          'Battery Current',
          'Charge Current',
          'Battery current',
          'Bat Charging Current',
          'battery_charging_current',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Type',
        unit: '',
        apiCandidates: [
          'Battery Type',
          'Bat Type',
          'Battery type',
          'battery_type',
        ],
      ),
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'AC Output Voltage',
        unit: 'V',
        apiCandidates: [
          'AC Output Voltage',
          'AC Output voltage',
          'AC1 Output Voltage',
          'AC output voltage',
          'Output Voltage',
          'Load Voltage',
          'AC Vol',
          'ac_output_voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'AC Output Frequency',
        unit: 'Hz',
        apiCandidates: [
          'AC Output Frequency',
          'AC Output frequency',
          'AC1 Output Frequency',
          'Output Frequency',
          'AC Frequency',
          'AC Freq',
          'Frequency',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Watts',
        unit: 'W',
        apiCandidates: [
          'AC Output Active Power',
          'AC Output Active power',
          'AC output active power',
          'Load Active Power',
          'Output Active Power',
          'Load Power',
          'Load Watts',
          'Output Power',
          'AC Power',
          'AC Active Power',
          'load_watts',
        ],
      ),
      PopupFieldConfig(
        label: 'Output Load Percentage',
        unit: '%',
        apiCandidates: [
          'Output Load Percentage',
          'Output load percentage',
          'Load Percentage',
          'Load %',
          'Load percentage',
          'output_load_percentage',
        ],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: [
          'Grid Voltage',
          'Grid voltage',
          'AC Input Voltage',
          'Input Voltage',
          'Grid Vol',
          'grid_voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: [
          'Grid Frequency',
          'Grid frequency',
          'AC Grid Frequency',
          'AC Input Frequency',
          'Grid Freq',
          'Frequency',
          'grid_frequency',
        ],
      ),
      PopupFieldConfig(
        label: 'Grid Power',
        unit: 'W',
        apiCandidates: [
          'Grid Active Power',
          'Grid active power',
          'Grid Power',
          'Grid power',
          'AC Input Power',
          'Input Power',
          'grid_power',
        ],
      ),
    ],
  );

  /// Elego model configuration (single PV input)
  static const elego = DeviceModelPopupConfig(
    model: DeviceModel.elego,
    pvFields: [
      PopupFieldConfig(
        label: 'Input Voltage',
        unit: 'V',
        apiCandidates: [
          'PV1 Input Voltage',
          'PV Input Voltage',
          'Input Voltage',
          'PV Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Input Current',
        unit: 'A',
        apiCandidates: [
          'PV1 Input Current',
          'PV Input Current',
          'Input Current',
          'PV Current',
        ],
      ),
      PopupFieldConfig(
        label: 'Input Power',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
          'PV Input Power',
          'Input Power',
          'PV Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: ['Battery Voltage', 'Bat Voltage', 'Battery Vol'],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
          'Battery SOC',
          'SOC',
          'Battery Percentage',
        ],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery charging current',
          'Charging Current',
          'Battery Current',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Type',
        unit: '',
        apiCandidates: ['Battery Type', 'Bat Type'],
      ),
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'Output Voltage',
        unit: 'V',
        apiCandidates: [
          'AC Output Voltage',
          'AC2 Output Voltage',
          'Output Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Power',
        unit: 'W',
        apiCandidates: ['AC Output Active Power', 'Load Power', 'Output Power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Output Load Percentage', 'Load Percentage', 'Load %'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: ['Grid Voltage', 'AC Input Voltage', 'Input Voltage'],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Grid Frequency', 'AC Input Frequency', 'Frequency'],
      ),
    ],
  );

  /// Xavier model configuration (same as Elego)
  static const xavier = DeviceModelPopupConfig(
    model: DeviceModel.xavier,
    pvFields: [
      PopupFieldConfig(
        label: 'Input Voltage',
        unit: 'V',
        apiCandidates: [
          'PV1 Input Voltage',
          'PV Input Voltage',
          'Input Voltage',
          'PV Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Input Current',
        unit: 'A',
        apiCandidates: [
          'PV1 Input Current',
          'PV Input Current',
          'Input Current',
          'PV Current',
        ],
      ),
      PopupFieldConfig(
        label: 'Input Power',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
          'PV Input Power',
          'Input Power',
          'PV Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: ['Battery Voltage', 'Bat Voltage', 'Battery Vol'],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
          'Battery SOC',
          'SOC',
          'Battery Percentage',
        ],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery charging current',
          'Charging Current',
          'Battery Current',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Type',
        unit: '',
        apiCandidates: ['Battery Type', 'Bat Type'],
      ),
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'Output Voltage',
        unit: 'V',
        apiCandidates: [
          'AC Output Voltage',
          'AC2 Output Voltage',
          'Output Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Power',
        unit: 'W',
        apiCandidates: ['AC Output Active Power', 'Load Power', 'Output Power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Output Load Percentage', 'Load Percentage', 'Load %'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: ['Grid Voltage', 'AC Input Voltage', 'Input Voltage'],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Grid Frequency', 'AC Input Frequency', 'Frequency'],
      ),
    ],
  );

  /// Arceus model configuration (single PV, no battery type)
  static const arceus = DeviceModelPopupConfig(
    model: DeviceModel.arceus,
    pvFields: [
      PopupFieldConfig(
        label: 'PV Voltage',
        unit: 'V',
        apiCandidates: [
          'PV1 Input Voltage',
          'PV Input Voltage',
          'PV Voltage',
          'Input Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'PV Current',
        unit: 'A',
        apiCandidates: [
          'PV1 Input Current',
          'PV Input Current',
          'PV Current',
          'Input Current',
        ],
      ),
      PopupFieldConfig(
        label: 'PV Power',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
          'PV Input Power',
          'PV Power',
          'Input Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: ['Battery Voltage', 'Bat Voltage'],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: ['Battery Capacity', 'Battery SOC', 'SOC'],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery charging current',
          'Charging Current',
          'Battery Current',
        ],
      ),
      // No Battery Type for Arceus
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'Output Voltage',
        unit: 'V',
        apiCandidates: [
          'AC Output Voltage',
          'AC2 Output Voltage',
          'Output Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Power',
        unit: 'W',
        apiCandidates: ['AC Output Active Power', 'Load Power', 'Output Power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Output Load Percentage', 'Load Percentage'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: ['Grid Voltage', 'AC Input Voltage'],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Grid Frequency', 'AC Input Frequency'],
      ),
    ],
  );

  /// Datalogger model configuration (no PV/Battery/Load/Grid specifics)
  static const datalogger = DeviceModelPopupConfig(
    model: DeviceModel.datalogger,
    pvFields: [],
    batteryFields: [],
    loadFields: [],
    gridFields: [],
  );

  /// Get configuration for a device model
  static DeviceModelPopupConfig forModel(DeviceModel model) {
    switch (model) {
      case DeviceModel.nova:
        return nova;
      case DeviceModel.elego:
        return elego;
      case DeviceModel.xavier:
        return xavier;
      case DeviceModel.arceus:
        return arceus;
      case DeviceModel.datalogger:
        return datalogger;
      case DeviceModel.unknown:
        // Default to Nova configuration for unknown models
        return nova;
    }
  }
}

/// Canonical protocol code per model for downstream aggregation logic
int canonicalProtocolFor(DeviceModel model) {
  switch (model) {
    case DeviceModel.nova:
      // Nova can be 2451 or 2449; choose 2451 as the canonical protocol
      return 2451;
    case DeviceModel.elego:
      return 2452;
    case DeviceModel.xavier:
      return 2451;
    case DeviceModel.arceus:
      return 6451;
    case DeviceModel.datalogger:
      // Prefer 2547 as canonical
      return 2547;
    case DeviceModel.unknown:
      // Fallback to Nova canonical for unknowns (maintain previous behavior)
      return 2451;
  }
}
