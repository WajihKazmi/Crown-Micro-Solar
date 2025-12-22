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
    if (devcode == 2449 || devcode == 2488) return DeviceModel.nova;
    // Xavier vs Nova ambiguity on 2451: prefer Xavier if alias hinted above, otherwise Nova
    if (devcode == 2451 || devcode == 2547) return DeviceModel.xavier;
    // Datalogger
    if (devcode == 2329) return DeviceModel.datalogger;

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
          'PV1 Input volts',
        ],
      ),
      PopupFieldConfig(
        label: 'PV2 Input volts',
        unit: 'V',
        apiCandidates: [
          'PV2 Input Voltage',
          'PV2 Input volts',
        ],
      ),
      PopupFieldConfig(
        label: 'PV1 watts',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
        ],
      ),
      PopupFieldConfig(
        label: 'PV2 watts',
        unit: 'W',
        apiCandidates: [
          'PV2 Charging Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: [
          'Battery Voltage',
          'Battery volts',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery Charging Current',
          'Battery Discharge Current',
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Type',
        unit: ' ',
        apiCandidates: [
          'Battery Type',
          'Bat Type',
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
        label: 'Load Watts',
        unit: 'W',
        apiCandidates: [
          'AC Output Active Power',
          'Ac Output Active power',
        ],
      ),
      PopupFieldConfig(
        label: 'Output Load Percentage',
        unit: '%',
        apiCandidates: [
          'Output Load Percent',
        ],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: [
          'Grid Voltage',
          'Grid Rating Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: [
          'Grid Frequency',
          'Grid frequency',
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
          'PV1 Input voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Input watts',
        unit: 'W',
        apiCandidates: [
          'PV1 Input Power',
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
        ],
      ),
      PopupFieldConfig(
        label: 'Battery Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery Charging Current',
          'Battery Discharging Current',
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
          'AC output voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Watts',
        unit: 'W',
        apiCandidates: ['AC Output Active Power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Output load percent'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: [
          'Grid Voltage',
          'Grid volts',
          'AC output voltage', // Elego reports grid voltage as AC output voltage
        ],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Grid Frequency', 'Grid frequency'],
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
        apiCandidates: ['PV1 Input Voltage', 'PV2 Input Voltage'],
      ),
      PopupFieldConfig(
        label: 'Input Watts',
        unit: 'W',
        apiCandidates: [
          'PV1 Charging Power',
          'PV2 Charging Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: ['Battery Voltage', 'Battery volts'],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
          'Battery Percentage',
        ],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: [
          'Battery Charging Current',
          'Battery Discharging Current',
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
          'AC1 Output Voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Watts',
        unit: 'W',
        apiCandidates: ['AC Output Active Power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Output Load Percent'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: ['Grid Voltage', 'Grid Volts'],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Grid Frequency'],
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
          'PV voltage',
          'PV volts',
        ],
      ),
      PopupFieldConfig(
        label: 'PV Current',
        unit: 'A',
        apiCandidates: [
          'PV current',
        ],
      ),
      PopupFieldConfig(
        label: 'PV Power',
        unit: 'W',
        apiCandidates: [
          'PV Input Power',
          'PV Power',
        ],
      ),
    ],
    batteryFields: [
      PopupFieldConfig(
        label: 'Battery Voltage',
        unit: 'V',
        apiCandidates: ['Battery Voltage', 'Battery Volts'],
      ),
      PopupFieldConfig(
        label: 'Battery Percentage',
        unit: '%',
        apiCandidates: [
          'Battery Capacity',
          'Battery SOC',
          'Battery Percentage'
        ],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: [
          'Charging current',
        ],
      ),
      // No Battery Type for Arceus
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'Output Voltage',
        unit: 'V',
        apiCandidates: [
          'Output voltage',
        ],
      ),
      PopupFieldConfig(
        label: 'Load Power',
        unit: 'W',
        apiCandidates: ['Output active power'],
      ),
      PopupFieldConfig(
        label: 'Load Percentage',
        unit: '%',
        apiCandidates: ['Load percentage'],
      ),
    ],
    gridFields: [
      PopupFieldConfig(
        label: 'Grid Voltage',
        unit: 'V',
        apiCandidates: ['Mains input voltage'],
      ),
      PopupFieldConfig(
        label: 'Grid Frequency',
        unit: 'Hz',
        apiCandidates: ['Mains frequency'],
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
