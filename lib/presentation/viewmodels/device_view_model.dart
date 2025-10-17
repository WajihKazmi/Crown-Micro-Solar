import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/models/device/device_data_one_day_query_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_key_parameter_model.dart'
    as model;
import 'dart:async';

class DeviceViewModel extends ChangeNotifier {
  final DeviceRepository _deviceRepository;

  List<Device> _standaloneDevices = [];
  List<Map<String, dynamic>> _collectors = [];
  Map<String, List<Device>> _collectorDevices = {};
  List<Device> _allDevices = [];

  bool _isLoading = false;
  String? _error;
  Set<String> _expandedCollectors = {};

  // Cache management
  String? _cachedPlantId;
  DateTime? _lastDevicesFetch;
  static const _devicesCacheDuration =
      Duration(minutes: 15); // Device list rarely changes

  // Device Detail Fields - for device details page
  Device? _currentDevice;
  DeviceDataOneDayQueryModel? _deviceDayData;
  DeviceLiveSignalModel? _liveSignalData;
  Map<String, model.DeviceKeyParameterModel> _keyParameterData = {};
  Map<String, dynamic>? _realTimeData;
  bool _isAutoUpdateEnabled = false;
  bool _isDetailLoading = false;
  bool _isAddingDatalogger = false;
  String? _addError;

  DeviceViewModel(this._deviceRepository);

  // Getters
  List<Device> get standaloneDevices => _standaloneDevices;
  List<Map<String, dynamic>> get collectors => _collectors;
  Map<String, List<Device>> get collectorDevices => _collectorDevices;
  List<Device> get allDevices => _allDevices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get expandedCollectors => _expandedCollectors;

  // Device Detail Getters
  Device? get currentDevice => _currentDevice;
  DeviceDataOneDayQueryModel? get deviceDayData => _deviceDayData;
  DeviceLiveSignalModel? get liveSignalData => _liveSignalData;
  Map<String, model.DeviceKeyParameterModel> get keyParameterData =>
      _keyParameterData;
  Map<String, dynamic>? get realTimeData => _realTimeData;
  bool get isAutoUpdateEnabled => _isAutoUpdateEnabled;
  bool get isDetailLoading => _isDetailLoading;
  bool get isAddingDatalogger => _isAddingDatalogger;
  String? get addError => _addError;

  // Load devices and collectors for a plant
  Future<void> loadDevicesAndCollectors(String plantId,
      {bool force = false}) async {
    try {
      // Check if we have valid cached data for this plant
      bool cacheValid = _cachedPlantId == plantId &&
          _lastDevicesFetch != null &&
          DateTime.now().difference(_lastDevicesFetch!) <
              _devicesCacheDuration &&
          (_allDevices.isNotEmpty || _collectors.isNotEmpty);

      if (!force && cacheValid) {
        print(
            'DeviceViewModel: Using cached device data for plant $plantId (${_allDevices.length} devices, ${_collectors.length} collectors)');
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'DeviceViewModel: Loading devices and collectors for plant $plantId');

      // 1) Quick path for instant UI paint, but only if list is empty
      // Skip if cache was already loaded (avoid redundant quick fetch)
      bool hadAny = _allDevices.isNotEmpty || _collectors.isNotEmpty;
      if (!hadAny) {
        print('DeviceViewModel: No data cached, fetching quick data');
        final quick =
            await _deviceRepository.getDevicesAndCollectorsQuick(plantId);
        _standaloneDevices = (quick['standaloneDevices'] ?? []) as List<Device>;
        _collectors = (quick['collectors'] ?? []) as List<Map<String, dynamic>>;
        _collectorDevices =
            (quick['collectorDevices'] ?? {}) as Map<String, List<Device>>;
        _allDevices = (quick['allDevices'] ?? []) as List<Device>;
        notifyListeners();
        // Save quick snapshot for cold starts
        await _saveDevicesCache(plantId);
      } else {
        print('DeviceViewModel: Cache already loaded, skipping quick fetch');
      }

      // 2) Background enrichment: fetch subordinate devices (does not block UI)
      try {
        final full = await _deviceRepository.getDevicesAndCollectors(plantId);
        // Only update if the new data is different (avoid flicker/ghosts)
        bool changed = false;
        List<Device> nextAll =
            (full['allDevices'] ?? _allDevices) as List<Device>;
        List<Device> nextStandalone =
            (full['standaloneDevices'] ?? _standaloneDevices) as List<Device>;
        List<Map<String, dynamic>> nextCollectors =
            (full['collectors'] ?? _collectors) as List<Map<String, dynamic>>;
        Map<String, List<Device>> nextCollectorDevices =
            (full['collectorDevices'] ?? _collectorDevices)
                as Map<String, List<Device>>;

        // Sort consistently by PN to stabilize ordering
        int byPn(Device a, Device b) => a.pn.compareTo(b.pn);
        nextAll.sort(byPn);
        nextStandalone.sort(byPn);
        for (final v in nextCollectorDevices.values) {
          v.sort(byPn);
        }

        String keyDevices(List<Device> list) => list.map((d) => d.pn).join('|');
        String keyCollectors(List<Map<String, dynamic>> list) =>
            list.map((c) => (c['pn'] ?? '').toString()).join('|');
        String keyCollectorMap(Map<String, List<Device>> m) {
          final keys = m.keys.toList()..sort();
          final parts = <String>[];
          for (final k in keys) {
            final devices = m[k]!..sort(byPn);
            parts.add('$k:${keyDevices(devices)}');
          }
          return parts.join('#');
        }

        if (keyDevices(nextAll) != keyDevices(_allDevices)) {
          _allDevices = nextAll;
          changed = true;
        }
        if (keyDevices(nextStandalone) != keyDevices(_standaloneDevices)) {
          _standaloneDevices = nextStandalone;
          changed = true;
        }
        if (keyCollectors(nextCollectors) != keyCollectors(_collectors)) {
          _collectors = nextCollectors;
          changed = true;
        }
        if (keyCollectorMap(nextCollectorDevices) !=
            keyCollectorMap(_collectorDevices)) {
          _collectorDevices = nextCollectorDevices;
          changed = true;
        }
        if (changed) notifyListeners();
        if (changed) await _saveDevicesCache(plantId);

        // Update cache metadata
        _cachedPlantId = plantId;
        _lastDevicesFetch = DateTime.now();
      } catch (e) {
        // keep quick results if full fails
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('DeviceViewModel: Error loading devices: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh devices
  Future<void> refreshDevices(String plantId) async {
    _lastDevicesFetch = null; // Invalidate cache
    await loadDevicesAndCollectors(plantId, force: true);
  }

  // ---- Persisted snapshot cache ----
  Future<bool> loadDevicesFromCache(String plantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('devices_cache_v1:$plantId');
      if (raw == null || raw.isEmpty) return false;
      final map = json.decode(raw) as Map<String, dynamic>;
      final allDevicesJson =
          (map['allDevices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final standaloneJson =
          (map['standaloneDevices'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      final collectors =
          (map['collectors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final collectorMap =
          (map['collectorDevices'] as Map?)?.cast<String, dynamic>() ?? {};

      List<Device> allDevices =
          allDevicesJson.map((e) => Device.fromJson(e)).toList();
      List<Device> standaloneDevices =
          standaloneJson.map((e) => Device.fromJson(e)).toList();
      Map<String, List<Device>> collectorDevices = {};
      collectorMap.forEach((k, v) {
        final list = (v as List).cast<Map<String, dynamic>>();
        collectorDevices[k] = list.map((e) => Device.fromJson(e)).toList();
      });

      // Sort for stable order
      int byPn(Device a, Device b) => a.pn.compareTo(b.pn);
      allDevices.sort(byPn);
      standaloneDevices.sort(byPn);
      for (final v in collectorDevices.values) v.sort(byPn);

      _allDevices = allDevices;
      _standaloneDevices = standaloneDevices;
      _collectors = collectors;
      _collectorDevices = collectorDevices;
      notifyListeners();
      return _allDevices.isNotEmpty || _collectors.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveDevicesCache(String plantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> map = {
        'allDevices': _allDevices.map((d) => d.toJson()).toList(),
        'standaloneDevices': _standaloneDevices.map((d) => d.toJson()).toList(),
        'collectors': _collectors,
        'collectorDevices': _collectorDevices
            .map((k, v) => MapEntry(k, v.map((d) => d.toJson()).toList())),
        'ts': DateTime.now().toIso8601String(),
      };
      await prefs.setString('devices_cache_v1:$plantId', json.encode(map));
    } catch (_) {
      // ignore cache errors
    }
  }

  // Device settings: query control fields (queryDeviceCtrlField)
  Future<Map<String, dynamic>?> fetchDeviceControlFields({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
  }) async {
    try {
      final dat = await _deviceRepository.getDeviceRealTimeData(
          pn, sn, devcode, devaddr);
      return Map<String, dynamic>.from(dat);
    } catch (e) {
      return null;
    }
  }

  // Device settings: write control field value and return API response
  Future<Map<String, dynamic>> setDeviceControlField({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String fieldId,
    required String value,
  }) async {
    return await _deviceRepository.setDeviceControlField(
      pn: pn,
      sn: sn,
      devcode: devcode,
      devaddr: devaddr,
      fieldId: fieldId,
      value: value,
    );
  }

  Future<String?> fetchSingleControlValue({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String fieldId,
  }) async {
    final res = await _deviceRepository.querySingleDeviceCtrlValue(
      pn: pn,
      sn: sn,
      devcode: devcode,
      devaddr: devaddr,
      fieldId: fieldId,
    );
    if (res['err'] == 0) {
      final dat = res['dat'];
      if (dat is Map && dat['val'] != null) {
        return dat['val'].toString();
      }
    }
    return null;
  }

  // Load devices with filters (matching old app functionality)
  Future<void> loadDevicesWithFilters(String plantId,
      {String status = '0101', String deviceType = '0101'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'DeviceViewModel: Loading devices with filters - status: $status, deviceType: $deviceType');

      final devices = await _deviceRepository.getDevicesWithFilters(plantId,
          status: status, deviceType: deviceType);

      // Clear previous data
      _standaloneDevices = [];
      _collectors = [];
      _collectorDevices = {};
      _allDevices = devices;

      // Separate collectors and devices
      for (final device in devices) {
        if (device.isCollector) {
          _collectors.add({
            'pn': device.pn,
            'alias': device.alias,
            'status': device.status,
            'load': device.load,
            'signal': device.signal,
            'firmware': device.firmware,
          });
        } else {
          _standaloneDevices.add(device);
        }
      }

      print(
          'DeviceViewModel: Loaded ${_standaloneDevices.length} standalone devices with filters');
      print(
          'DeviceViewModel: Loaded ${_collectors.length} collectors with filters');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DeviceViewModel: Error loading devices with filters: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle collector expansion
  void toggleCollectorExpansion(String collectorPn) {
    if (_expandedCollectors.contains(collectorPn)) {
      _expandedCollectors.remove(collectorPn);
    } else {
      _expandedCollectors.add(collectorPn);
    }
    notifyListeners();
  }

  // Get subordinate devices for a collector
  List<Device> getSubordinateDevices(String collectorPn) {
    return _collectorDevices[collectorPn] ?? [];
  }

  // Check if collector is expanded
  bool isCollectorExpanded(String collectorPn) {
    return _expandedCollectors.contains(collectorPn);
  }

  // Get device type text (matching old app)
  String getDeviceTypeText(int devcode) {
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

  // Get status text (matching old app)
  String getStatusText(int status) {
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

  // Get status color (matching old app)
  Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      case 2:
      case 3:
      case 4:
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get signal strength color (for collectors)
  Color getSignalColor(double? signal) {
    if (signal == null || signal == 0) return Colors.grey;
    if (signal <= 20) return Colors.red;
    if (signal <= 60) return Colors.orange;
    return Colors.green;
  }

  // Get signal strength rating (for collectors)
  double getSignalRating(double? signal) {
    if (signal == null || signal == 0) return 0.0;
    return signal / 20.0; // Normalize to 0-5 scale
  }

  // Clear all data
  void clear() {
    _standaloneDevices.clear();
    _collectors.clear();
    _collectorDevices.clear();
    _allDevices.clear();
    _expandedCollectors.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Add a datalogger then refresh lists
  Future<Map<String, dynamic>> addDatalogger(
      {required String plantId,
      required String pn,
      required String name}) async {
    _addError = null;
    _isAddingDatalogger = true;
    notifyListeners();
    try {
      // Basic validation
      if (pn.isEmpty || pn.length != 14) {
        throw Exception('PN must be 14 digits');
      }
      if (!RegExp(r'^\d{14}$').hasMatch(pn)) {
        throw Exception('PN must be numeric (14 digits)');
      }
      if (name.trim().isEmpty) {
        throw Exception('Datalogger name is required');
      }

      final res = await _deviceRepository.addDataLogger(plantId, pn, name);
      if (res['err'] == 0) {
        // Refresh
        await loadDevicesAndCollectors(plantId);
      } else {
        _addError = res['desc']?.toString() ?? 'Failed to add datalogger';
      }
      return res;
    } catch (e) {
      _addError = e.toString();
      rethrow;
    } finally {
      _isAddingDatalogger = false;
      notifyListeners();
    }
  }

  // Get total device count
  int get totalDeviceCount => _allDevices.length;

  // Get online device count
  int get onlineDeviceCount => _allDevices.where((d) => d.isOnline).length;

  // Get offline device count
  int get offlineDeviceCount => _allDevices.where((d) => !d.isOnline).length;

  // Get collector count
  int get collectorCount => _collectors.length;

  // Get standalone device count
  int get standaloneDeviceCount => _standaloneDevices.length;

  // Device detail: fetch device data for one day
  Future<DeviceDataOneDayQueryModel?> fetchDeviceDataOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
    int page = 0,
  }) async {
    return await _deviceRepository.fetchDeviceDataOneDay(
      sn: sn,
      pn: pn,
      devcode: devcode,
      devaddr: devaddr,
      date: date,
      page: page,
    );
  }

  // Device detail: fetch live device signal/current/voltage/flow data
  Future<DeviceLiveSignalModel?> fetchDeviceLiveSignal({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
  }) async {
    return await _deviceRepository.fetchDeviceLiveSignal(
      sn: sn,
      pn: pn,
      devcode: devcode,
      devaddr: devaddr,
    );
  }

  // Device detail: fetch key parameter data for one day
  Future<model.DeviceKeyParameterModel?> fetchDeviceKeyParameterOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String parameter,
    required String date,
  }) async {
    final response = await _deviceRepository.fetchDeviceKeyParameterOneDay(
      sn: sn,
      pn: pn,
      devcode: devcode,
      devaddr: devaddr,
      parameter: parameter,
      date: date,
    );

    if (response != null) {
      try {
        // Check if the response is a direct API response
        if (response is Map && response['source'] == 'live_signal') {
          print(
              'DeviceViewModel: Received live signal data for $parameter: ${response['value']}');

          // Create a DeviceKeyParameterModel with data from live signal
          // This ensures compatibility with the existing code expecting this model
          final model.DeviceKeyParameterModel liveSignalModel =
              _createKeyParameterModelFromLiveSignal(
            parameter: parameter,
            value: response['value'],
            date: date,
          );

          return liveSignalModel;
        } else {
          // Standard API response
          return model.DeviceKeyParameterModel.fromJson(response);
        }
      } catch (e) {
        print('DeviceViewModel: Error parsing key parameter data: $e');
        return null;
      }
    }
    return null;
  }

  // Helper method to create a KeyParameterModel from live signal data
  model.DeviceKeyParameterModel _createKeyParameterModelFromLiveSignal({
    required String parameter,
    required dynamic value,
    required String date,
  }) {
    print(
        'DeviceViewModel: Creating key parameter model from live signal. Parameter: $parameter, Value: $value');

    // Create a single data point from the live signal value
    final double doubleValue =
        value is double ? value : double.tryParse(value.toString()) ?? 0.0;

    final now = DateTime.now();
    final timeString = now.toString().substring(11, 16);
    final fullTimeString = now.toString();

    // Create a model with a single data point
    // This mimics the format of the actual API response with parameter array
    return model.DeviceKeyParameterModel(
      err: 0,
      desc: 'SUCCESS',
      dat: model.DeviceKeyParameterData(
        parameter: doubleValue.toString(),
        date: fullTimeString,
        total: 1,
        row: [
          model.DeviceKeyParameterRow(
            time: timeString,
            field: [doubleValue.toString()],
          ),
        ],
        title: [
          model.DeviceKeyParameterTitle(
            title: parameter,
            unit: _getParameterUnit(parameter),
          ),
        ],
      ),
    );
  }

  // Prepare graph data for visualization
  Future<Map<String, dynamic>> prepareGraphData({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String parameter,
    required String date,
    String timeUnit = 'day', // 'day', 'month', 'year'
  }) async {
    try {
      print(
          'DeviceViewModel: Preparing graph data for $parameter on $date (timeUnit: $timeUnit)');
      print('DeviceViewModel: Device code: $devcode, Device address: $devaddr');

      // Map parameter to device-specific parameter name
      String mappedParameter = _mapParameterToDeviceType(parameter, devcode);
      print(
          'DeviceViewModel: Mapped parameter $parameter to $mappedParameter for device type $devcode');

      // Fetch the data based on the parameter
      final model.DeviceKeyParameterModel? keyParameterData =
          await fetchDeviceKeyParameterOneDay(
        sn: sn,
        pn: pn,
        devcode: devcode,
        devaddr: devaddr,
        parameter: mappedParameter,
        date: date,
      );

      if (keyParameterData == null ||
          keyParameterData.dat == null ||
          keyParameterData.dat!.row == null ||
          keyParameterData.dat!.row!.isEmpty) {
        print('DeviceViewModel: No data available for graph');

        // Try fetching live signal data for current values
        final liveSignal = await fetchDeviceLiveSignal(
          sn: sn,
          pn: pn,
          devcode: devcode,
          devaddr: devaddr,
        );

        if (liveSignal != null) {
          print('DeviceViewModel: Using live signal data for current values');
          print('DeviceViewModel: Device code: $devcode');

          // Get the current value from live signal based on parameter
          double? currentValue;

          // Apply our API test findings for device type 2451
          if (devcode == 2451) {
            // For device type 2451, we know OUTPUT_POWER works well for all power-related parameters
            switch (parameter) {
              case 'PV_OUTPUT_POWER':
              case 'LOAD_POWER':
              case 'GRID_POWER':
                // Use output power for all power-related parameters based on our testing
                currentValue = liveSignal.outputPower;
                break;
              case 'BATTERY_SOC':
                currentValue = liveSignal.batteryLevel;
                break;
              case 'AC2_OUTPUT_VOLTAGE':
                currentValue = liveSignal.outputVoltage;
                break;
              case 'AC2_OUTPUT_CURRENT':
                currentValue = liveSignal.outputCurrent;
                break;
              case 'PV_INPUT_VOLTAGE':
                currentValue = liveSignal.inputVoltage;
                break;
              default:
                // For any other parameter on this device type, try output power as a fallback
                if (parameter.contains('POWER')) {
                  currentValue = liveSignal.outputPower;
                } else {
                  currentValue = null;
                }
            }
          } else {
            // For other device types, use standard mappings
            switch (parameter) {
              case 'PV_OUTPUT_POWER':
                currentValue = liveSignal.inputPower;
                break;
              case 'BATTERY_SOC':
                currentValue = liveSignal.batteryLevel;
                break;
              case 'LOAD_POWER':
                currentValue = liveSignal.outputPower;
                break;
              case 'GRID_POWER':
                currentValue = null; // No direct mapping in live signal
                break;
              case 'AC2_OUTPUT_VOLTAGE':
                currentValue = liveSignal.outputVoltage;
                break;
              case 'AC2_OUTPUT_CURRENT':
                currentValue = liveSignal.outputCurrent;
                break;
              case 'PV_INPUT_VOLTAGE':
                currentValue = liveSignal.inputVoltage;
                break;
              default:
                currentValue = null;
            }
          }

          // If we have a current value, create a simple graph with it
          if (currentValue != null) {
            print(
                'DeviceViewModel: Using current value for graph: $currentValue');

            // Create a minimal graph with the current value
            return {
              'labels': ['Now'],
              'datasets': [
                {
                  'label': _getParameterLabel(parameter),
                  'data': [currentValue],
                  'color': _getParameterColor(parameter),
                }
              ],
              'minValue': currentValue,
              'maxValue': currentValue,
              'avgValue': currentValue,
              'unit': _getParameterUnit(parameter),
              'isLiveData': true,
            };
          }
        }

        return {
          'labels': <String>[],
          'datasets': <Map<String, dynamic>>[
            {
              'label': parameter,
              'data': <double>[],
              'color': Colors.blue,
            }
          ],
          'minValue': 0.0,
          'maxValue': 0.0,
          'avgValue': 0.0,
          'unit': _getParameterUnit(parameter),
          'noData': true,
        };
      }

      // Extract value data for the graph
      final rows = keyParameterData.dat!.row!;
      final List<String> labels = [];
      final List<double> values = [];

      // Generate time labels based on the number of data points
      int dataPointCount = rows.length;

      for (int i = 0; i < dataPointCount; i++) {
        final row = rows[i];

        if (row.field != null && row.field!.isNotEmpty) {
          // Generate time label based on index and time unit
          String timeLabel = '';

          if (timeUnit == 'day') {
            // For daily data, generate hourly labels (0:00 to 23:00)
            final hour = (i * 24 ~/ dataPointCount).clamp(0, 23);
            timeLabel = '$hour:00';
          } else if (timeUnit == 'month') {
            // For monthly data, generate day labels (1 to 30/31)
            final day = (i * 30 ~/ dataPointCount).clamp(1, 30);
            timeLabel = '$day';
          } else if (timeUnit == 'year') {
            // For yearly data, generate month labels (Jan to Dec)
            final month = (i * 12 ~/ dataPointCount).clamp(0, 11);
            timeLabel = _getMonthAbbreviation(month + 1);
          }

          labels.add(timeLabel);

          // Extract value (handling nulls)
          final value = row.field!.first != null
              ? double.tryParse(row.field!.first.toString()) ?? 0.0
              : 0.0;
          values.add(value);
        }
      }

      // Calculate statistics
      double minValue = 0.0;
      double maxValue = 0.0;
      double avgValue = 0.0;

      if (values.isNotEmpty) {
        minValue = values.reduce((a, b) => a < b ? a : b);
        maxValue = values.reduce((a, b) => a > b ? a : b);
        avgValue = values.reduce((a, b) => a + b) / values.length;
      }

      print(
          'DeviceViewModel: Graph data prepared with ${labels.length} points');
      print('DeviceViewModel: Min: $minValue, Max: $maxValue, Avg: $avgValue');

      print('Graph data prepared:');
      print('- Labels: $labels');
      print('- Data points: ${values.length}');
      print('- Min: $minValue, Max: $maxValue, Avg: $avgValue');

      return {
        'labels': labels,
        'datasets': [
          {
            'label': _getParameterLabel(parameter),
            'data': values,
            'color': _getParameterColor(parameter),
          }
        ],
        'minValue': minValue,
        'maxValue': maxValue,
        'avgValue': avgValue,
        'unit': _getParameterUnit(parameter),
      };
    } catch (e) {
      print('DeviceViewModel: Error preparing graph data: $e');
      return {
        'labels': <String>[],
        'datasets': <Map<String, dynamic>>[
          {
            'label': parameter,
            'data': <double>[],
            'color': Colors.blue,
          }
        ],
        'minValue': 0.0,
        'maxValue': 0.0,
        'avgValue': 0.0,
        'unit': _getParameterUnit(parameter),
        'error': e.toString(),
      };
    }
  }

  // Map parameter names based on device type
  String _mapParameterToDeviceType(String parameter, int devcode) {
    print(
        'DeviceViewModel: Mapping parameter $parameter for device type $devcode');

    // Device type 2451: map only known aliases; otherwise, use the requested parameter as-is
    if (devcode == 2451) {
      switch (parameter) {
        case 'BATTERY_SOC':
          return 'SOC';
        case 'AC2_OUTPUT_VOLTAGE':
        case 'OUTPUT_VOLTAGE':
          return 'OUTPUT_VOLTAGE';
        case 'AC2_OUTPUT_CURRENT':
        case 'OUTPUT_CURRENT':
          return 'OUTPUT_CURRENT';
        default:
          return parameter;
      }
    }
    // For other energy storage machines (devcode 2400-2499)
    else if (devcode >= 2400 && devcode < 2500) {
      switch (parameter) {
        case 'BATTERY_SOC':
          return 'SOC';
        case 'PV_OUTPUT_POWER':
          // Try OUTPUT_POWER first based on our test findings
          return 'OUTPUT_POWER';
        case 'LOAD_POWER':
          // Try OUTPUT_POWER first based on our test findings
          return 'OUTPUT_POWER';
        case 'GRID_POWER':
          // Try OUTPUT_POWER first based on our test findings
          return 'OUTPUT_POWER';
        case 'AC2_OUTPUT_VOLTAGE':
          return 'OUTPUT_VOLTAGE';
        case 'AC2_OUTPUT_CURRENT':
          return 'OUTPUT_CURRENT';
        default:
          // For any power-related parameters, try OUTPUT_POWER as a fallback
          if (parameter.contains('POWER')) {
            return 'OUTPUT_POWER';
          }
          return parameter;
      }
    }

    // For inverters (devcode 512)
    if (devcode == 512) {
      switch (parameter) {
        case 'PV_OUTPUT_POWER':
          return 'OUTPUT_POWER';
        case 'AC2_OUTPUT_VOLTAGE':
          return 'AC_VOLTAGE';
        case 'AC2_OUTPUT_CURRENT':
          return 'AC_CURRENT';
        default:
          return parameter;
      }
    }

    // Default fallback for other device types
    return parameter;
  }

  // Helper function to get parameter label
  String _getParameterLabel(String parameter) {
    switch (parameter) {
      case 'PV_OUTPUT_POWER':
        return 'PV Output Power';
      case 'BATTERY_SOC':
        return 'Battery SOC';
      case 'LOAD_POWER':
        return 'Load Power';
      case 'GRID_POWER':
        return 'Grid Power';
      case 'AC2_OUTPUT_VOLTAGE':
        return 'AC2 Output Voltage';
      case 'AC2_OUTPUT_CURRENT':
        return 'AC2 Output Current';
      case 'PV_INPUT_VOLTAGE':
        return 'PV Input Voltage';
      case 'PV_INPUT_CURRENT':
        return 'PV Input Current';
      default:
        return parameter;
    }
  }

  // Helper function to get parameter unit
  String _getParameterUnit(String parameter) {
    if (parameter == 'BATTERY_SOC') {
      return '%';
    } else if (parameter.contains('POWER')) {
      return 'kW';
    } else if (parameter.contains('VOLTAGE')) {
      return 'V';
    } else if (parameter.contains('CURRENT')) {
      return 'A';
    } else {
      return '';
    }
  }

  // Helper function to get parameter color
  Color _getParameterColor(String parameter) {
    switch (parameter) {
      case 'PV_OUTPUT_POWER':
        return Colors.orange;
      case 'BATTERY_SOC':
        return Colors.green;
      case 'LOAD_POWER':
        return Colors.blue;
      case 'GRID_POWER':
        return Colors.purple;
      case 'AC2_OUTPUT_VOLTAGE':
      case 'AC2_OUTPUT_CURRENT':
        return Colors.red;
      case 'PV_INPUT_VOLTAGE':
      case 'PV_INPUT_CURRENT':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  // Helper function to get month abbreviation
  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Helper method to get the latest value for a parameter
  double getLatestValueForParameter(String parameter) {
    if (_keyParameterData.containsKey(parameter)) {
      return _keyParameterData[parameter]!.getLatestValue();
    }
    return 0.0;
  }
}
