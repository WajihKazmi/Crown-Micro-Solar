/// Device Model Configuration
/// Defines popup fields and behavior for different device models (Nova, Elego, Xavier, Arceus)
///
/// Model detection:
/// - Nova: devcode 2452, 2400-2449, or alias contains "nova"
/// - Elego: devcode 2451, or alias contains "elego"
/// - Xavier: alias contains "xavier"
/// - Arceus: alias contains "arceus"
///
/// Each model has specific fields for PV, Battery, Load, and Grid categories

enum DeviceModel {
  nova,
  elego,
  xavier,
  arceus,
  unknown;

  /// Detect device model from devcode and alias
  static DeviceModel detect({required int devcode, required String alias}) {
    final aliasLower = alias.toLowerCase().trim();
    
    // Check alias first (most specific)
    if (aliasLower.contains('nova')) return DeviceModel.nova;
    if (aliasLower.contains('elego')) return DeviceModel.elego;
    if (aliasLower.contains('xavier')) return DeviceModel.xavier;
    if (aliasLower.contains('arceus')) return DeviceModel.arceus;
    
    // Fallback to devcode patterns
    if (devcode == 2451) return DeviceModel.elego;
    if (devcode == 2452 || (devcode >= 2400 && devcode < 2450)) {
      return DeviceModel.nova;
    }
    
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
        label: 'PV1 Input Voltage',
        unit: 'V',
        apiCandidates: ['PV1 Input Voltage', 'PV1 Input voltage', 'PV1 Voltage'],
      ),
      PopupFieldConfig(
        label: 'PV2 Input Voltage',
        unit: 'V',
        apiCandidates: ['PV2 Input Voltage', 'PV2 Input voltage', 'PV2 Voltage'],
      ),
      PopupFieldConfig(
        label: 'PV1 Input Power',
        unit: 'W',
        apiCandidates: ['PV1 Charging Power', 'PV1 Input Power', 'PV1 Active Power', 'PV1 Power'],
      ),
      PopupFieldConfig(
        label: 'PV2 Input Power',
        unit: 'W',
        apiCandidates: ['PV2 Charging power', 'PV2 Input Power', 'PV2 Active Power', 'PV2 Power'],
      ),
      PopupFieldConfig(
        label: 'PV1 Input Current',
        unit: 'A',
        apiCandidates: ['PV1 Input Current', 'PV1 Input current', 'PV1 Current'],
      ),
      PopupFieldConfig(
        label: 'PV2 Input Current',
        unit: 'A',
        apiCandidates: ['PV2 Input Current', 'PV2 Input current', 'PV2 Current'],
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
        apiCandidates: ['Battery Capacity', 'Battery SOC', 'SOC', 'Battery Percentage'],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: ['Battery charging current', 'Charging Current', 'Battery Current', 'Charge Current'],
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
        apiCandidates: ['AC Output Voltage', 'AC2 Output Voltage', 'Output Voltage', 'Load Voltage'],
      ),
      PopupFieldConfig(
        label: 'Load Power',
        unit: 'W',
        apiCandidates: ['AC Output Active Power', 'Load Power', 'Output Power', 'AC Power'],
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

  /// Elego model configuration (single PV input)
  static const elego = DeviceModelPopupConfig(
    model: DeviceModel.elego,
    pvFields: [
      PopupFieldConfig(
        label: 'Input Voltage',
        unit: 'V',
        apiCandidates: ['PV1 Input Voltage', 'PV Input Voltage', 'Input Voltage', 'PV Voltage'],
      ),
      PopupFieldConfig(
        label: 'Input Current',
        unit: 'A',
        apiCandidates: ['PV1 Input Current', 'PV Input Current', 'Input Current', 'PV Current'],
      ),
      PopupFieldConfig(
        label: 'Input Power',
        unit: 'W',
        apiCandidates: ['PV1 Charging Power', 'PV Input Power', 'Input Power', 'PV Power'],
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
        apiCandidates: ['Battery Capacity', 'Battery SOC', 'SOC', 'Battery Percentage'],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: ['Battery charging current', 'Charging Current', 'Battery Current'],
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
        apiCandidates: ['AC Output Voltage', 'AC2 Output Voltage', 'Output Voltage'],
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
        apiCandidates: ['PV1 Input Voltage', 'PV Input Voltage', 'Input Voltage', 'PV Voltage'],
      ),
      PopupFieldConfig(
        label: 'Input Current',
        unit: 'A',
        apiCandidates: ['PV1 Input Current', 'PV Input Current', 'Input Current', 'PV Current'],
      ),
      PopupFieldConfig(
        label: 'Input Power',
        unit: 'W',
        apiCandidates: ['PV1 Charging Power', 'PV Input Power', 'Input Power', 'PV Power'],
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
        apiCandidates: ['Battery Capacity', 'Battery SOC', 'SOC', 'Battery Percentage'],
      ),
      PopupFieldConfig(
        label: 'Charging Current',
        unit: 'A',
        apiCandidates: ['Battery charging current', 'Charging Current', 'Battery Current'],
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
        apiCandidates: ['AC Output Voltage', 'AC2 Output Voltage', 'Output Voltage'],
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
        apiCandidates: ['PV1 Input Voltage', 'PV Input Voltage', 'PV Voltage', 'Input Voltage'],
      ),
      PopupFieldConfig(
        label: 'PV Current',
        unit: 'A',
        apiCandidates: ['PV1 Input Current', 'PV Input Current', 'PV Current', 'Input Current'],
      ),
      PopupFieldConfig(
        label: 'PV Power',
        unit: 'W',
        apiCandidates: ['PV1 Charging Power', 'PV Input Power', 'PV Power', 'Input Power'],
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
        apiCandidates: ['Battery charging current', 'Charging Current', 'Battery Current'],
      ),
      // No Battery Type for Arceus
    ],
    loadFields: [
      PopupFieldConfig(
        label: 'Output Voltage',
        unit: 'V',
        apiCandidates: ['AC Output Voltage', 'AC2 Output Voltage', 'Output Voltage'],
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
      case DeviceModel.unknown:
        // Default to Nova configuration for unknown models
        return nova;
    }
  }
}
