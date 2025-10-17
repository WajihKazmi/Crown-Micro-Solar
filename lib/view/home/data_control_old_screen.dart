import 'package:flutter/material.dart';
import 'package:crown_micro_solar/legacy/device_ctrl_fields_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'data_control_old_submenu_screen.dart';

// Exact copy-style of the old app's DataControl list UI, adapted to our project
class DataControlOldScreen extends StatefulWidget {
  final String pn;
  final String sn;
  final int devcode;
  final int devaddr;

  const DataControlOldScreen({
    super.key,
    required this.pn,
    required this.sn,
    required this.devcode,
    required this.devaddr,
  });

  factory DataControlOldScreen.fromDevice(Device device, {Key? key}) =>
      DataControlOldScreen(
        key: key,
        pn: device.pn,
        sn: device.sn,
        devcode: device.devcode,
        devaddr: device.devaddr,
      );

  @override
  State<DataControlOldScreen> createState() => _DataControlOldScreenState();
}

class _DataControlOldScreenState extends State<DataControlOldScreen> {
  bool _loading = true;
  Map<String, dynamic>? _resp;
  static const List<String> _tabsOrder = <String>[
    'Battery Settings',
    'System Settings',
    'Basic Settings',
    'Standard Settings',
    'Other Settings',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await DeviceCtrlFieldseModelQuery(
        context,
        SN: widget.sn,
        PN: widget.pn,
        devcode: widget.devcode.toString(),
        devaddr: widget.devaddr.toString(),
      );
      setState(() {
        _resp = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _resp = {'err': 404, 'desc': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            tooltip: 'Back',
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Device Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(size),
    );
  }

  Widget _buildBody(Size size) {
    final width = size.width;
    final data = _resp ?? const <String, dynamic>{'err': 404};
    final err = data['err'] as int? ?? 404;
    if (err == 1) return _msg(width, 'Failed (no device protocol)');
    if (err == 6) return _msg(width, 'Parameter error');
    if (err == 12) return _msg(width, 'No record found');
    if (err == 257) return _msg(width, 'Collector not found');
    if (err == 258) return _msg(width, 'Device could not be found');
    if (err == 260) return _msg(width, 'Power station not found');
    if (err == 404) return _msg(width, 'No response from server');

    if (err != 0 || data['dat'] == null || data['dat']['field'] == null) {
      return _msg(width, 'No response from server');
    }

    final model = DeviceCtrlFieldseModel.fromJson(data);
    final allFields = model.dat?.field ?? <Field>[];

    // Build strict grouping per the exact spec: include ONLY the fields defined per category
    final grouped = _strictGrouped(allFields);
    final nonEmptyTabs =
        _tabsOrder.where((t) => grouped[t]!.isNotEmpty).toList();

    // Show category buttons as the main screen (as per provided design)
    if (nonEmptyTabs.isEmpty) {
      return _msg(width, 'No settings available');
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 8),
        for (final cat in nonEmptyTabs)
          _CategoryCardButton(
            title: cat,
            count: grouped[cat]!.length,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CategoryScreen(
                    category: cat,
                    fields: _orderCategoryFields(cat, grouped[cat]!),
                    pn: widget.pn,
                    sn: widget.sn,
                    devaddr: widget.devaddr,
                    devcode: widget.devcode,
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Strict grouping and ordering
  Map<String, List<Field>> _strictGrouped(List<Field> all) {
    // Canonical label lists per category, ordered
    final batteryList = [
      'Battery Type',
      'Bulk Charging Voltage',
      'Float Charging Voltage',
      'Max. Charging Current',
      'Max Battery Discharge Current',
      'Max. AC Charging Current',
      'Charging Source Priority',
      'Battery Equalization',
      'Real-time Activate Battery Equalization',
      'Battery Equalization Time-out',
      'Battery Equalization Time',
      'Equalization Period',
      'Equalization Voltage',
      'Back to Grid Capacity',
      'Back to Discharge Capacity',
      'Battery Cut-off Capacity',
      // Old-app variants seen on Energy Storage devices
      'Battery Cut off Voltage',
      'Back To Grid Voltage',
      'Back To Discharge Voltage',
      'Li-BattreyAuto Turnon',
      'Li-Battrey Immediately Turnon',
    ];
    final basicList = [
      'Output Source Priority',
      'AC Input Range',
      'AC Output Mode',
      'Phase 1 Of 3 Phase Output',
      'Phase 2 Of 3 Phase Output',
      'Phase 3 Of 3 Phase Output',
      'Battery Capacity to Turn Off AC2',
      'Discharge Time to turn Off AC2',
      'Time Interval to Turn Off AC2',
      'Time Interval to Turn On AC2',
      'Charge Time to turn off AC2',
      'Battery Capacity to turn On AC2',
      // Old-app scheduling and priority variants
      'Start Time For Enable AC Charger Working',
      'Ending Time For Enable AC Charger Working',
      'Start time for enable AC supply the load',
      'Ending time for enable AC supply the load',
      'Solar Supply Priority',
    ];
    final standardList = [
      'LCD Auto-return to Main Screen',
      'Overload Auto Restart',
      'Buzzer',
      'Fault Code Record',
      'Backlight',
      'Bypass Function',
      'Solar Feed to Grid',
      'Beeps While Primary Source Interrupt',
      'Over Temperature Auto Restart',
      'Power Saving Function',
    ];
    final systemList = [
      'Restore to Default',
    ];
    final otherList = [
      'Output Voltage',
      'Output Frequency',
      'LED Status',
      'LED Speed',
      'LED Effect',
      'LED Brightness',
      'LED Data',
      'LED Color 1',
      'LED Color 2',
      'LED Color 3',
      // Old-app variants & utilities
      'AC Output Rating Voltage',
      'AC Output Rating Frequency',
      'On-Off control for RGB LED',
      'Lighting speed of RGB LED',
      'Brightness of RGB LED',
      'RGB LED effects',
      'Data Presentation of data color',
      'Set Date Time',
      'Country Customized Regulations',
      'Reset PV energy storaget',
    ];

    String norm(String s) => s.trim().toLowerCase().replaceAll('_', ' ');
    bool eq(String a, String b) => norm(a) == norm(b);

    // Synonym maps: canonical -> variants
    Map<String, List<String>> batterySyn() => {
          'Battery Type': ['battery type'],
          'Bulk Charging Voltage': ['bulk charge voltage', 'bulk voltage'],
          'Float Charging Voltage': ['float charge voltage', 'float voltage'],
          'Max. Charging Current': [
            'max charging current',
            'maximum charging current',
            'max charge current'
          ],
          'Max Battery Discharge Current': [
            'max. battery discharge current',
            'max discharge current',
            'maximum discharge current'
          ],
          'Max. AC Charging Current': [
            'max ac charging current',
            'maximum ac charging current'
          ],
          'Charging Source Priority': [
            'charge source priority',
            'charging priority',
            'source priority (charging)',
            'charger source priority',
            'solar supply priority',
          ],
          'Battery Equalization': [
            'battery equalisation',
            'equalization',
            'equalisation'
          ],
          'Real-time Activate Battery Equalization': [
            'realtime activate battery equalization',
            'real time activate battery equalization',
            'activate battery equalization',
            'activation battery equalization',
            'start equalization',
          ],
          'Battery Equalization Time-out': [
            'battery equalization timeout',
            'equalization timeout',
            'equalisation timeout',
            'equalization time out'
          ],
          'Battery Equalization Time': [
            'equalization time',
            'equalisation time',
            'equalization duration'
          ],
          'Equalization Period': [
            'equalization cycle',
            'equalisation cycle',
            'equalization interval'
          ],
          'Equalization Voltage': ['equalisation voltage'],
          'Back to Grid Capacity': [
            'return to grid capacity',
            'back to utility capacity'
          ],
          'Back to Discharge Capacity': [
            'return to discharge capacity',
            'back to discharge'
          ],
          'Battery Cut-off Capacity': [
            'battery cut off capacity',
            'battery cutoff capacity'
          ],
          'Battery Cut off Voltage': [
            'battery cut-off voltage',
            'battery cutoff voltage'
          ],
          'Back To Grid Voltage': [
            'back to grid voltage',
            'return to grid voltage'
          ],
          'Back To Discharge Voltage': [
            'back to discharge voltage',
            'return to discharge voltage'
          ],
          'Li-BattreyAuto Turnon': [
            'li-battery auto turn on',
            'li battery auto turn on',
            'li-battery auto turnon',
          ],
          'Li-Battrey Immediately Turnon': [
            'li-battery immediately turn on',
            'li battery immediately turn on',
            'li-battery immediately turnon',
          ],
        };
    Map<String, List<String>> basicSyn() => {
          'Output Source Priority': [
            'output priority',
            'source priority (output)'
          ],
          'AC Input Range': [
            'ac input range (apl/ups)',
            'input voltage range',
          ],
          'AC Output Mode': ['output mode'],
          'Phase 1 Of 3 Phase Output': [
            'phase 1 of three phase output',
            'phase 1 of 3-phase output'
          ],
          'Phase 2 Of 3 Phase Output': [
            'phase 2 of three phase output',
            'phase 2 of 3-phase output'
          ],
          'Phase 3 Of 3 Phase Output': [
            'phase 3 of three phase output',
            'phase 3 of 3-phase output'
          ],
          'Battery Capacity to Turn Off AC2': [
            'turn off ac2 battery capacity',
            'battery capacity to turn off ac 2'
          ],
          'Discharge Time to turn Off AC2': ['discharge time to turn off ac 2'],
          'Time Interval to Turn Off AC2': [
            'ac2 off interval',
            'time interval to turn off ac 2'
          ],
          'Time Interval to Turn On AC2': [
            'ac2 on interval',
            'time interval to turn on ac 2'
          ],
          'Charge Time to turn off AC2': ['charge time to turn off ac 2'],
          'Battery Capacity to turn On AC2': [
            'turn on ac2 battery capacity',
            'battery capacity to turn on ac 2'
          ],
          'Start Time For Enable AC Charger Working': [
            'start time for enable ac charger working',
            'ac charger start time'
          ],
          'Ending Time For Enable AC Charger Working': [
            'ending time for enable ac charger working',
            'ac charger end time'
          ],
          'Start time for enable AC supply the load': [
            'start time for enable ac supply the load',
            'ac supply start time'
          ],
          'Ending time for enable AC supply the load': [
            'ending time for enable ac supply the load',
            'ac supply end time'
          ],
          'Solar Supply Priority': [
            'solar supply priority',
            'solar priority',
            'solar first priority'
          ],
        };
    Map<String, List<String>> standardSyn() => {
          'LCD Auto-return to Main Screen': [
            'lcd auto return to main screen',
            'lcd auto-return',
            'auto return to main',
            'return to main screen',
            'lcd return time'
          ],
          'Overload Auto Restart': [
            'overload restart',
            'restart after overload'
          ],
          'Buzzer': ['beep', 'beeps', 'beeping', 'audio alarm'],
          'Fault Code Record': [
            'fault record',
            'fault log',
            'error code record',
            'error log',
            'alarm log'
          ],
          'Backlight': [
            'back light',
            'lcd light',
            'screen light',
            'display backlight',
            'lcd brightness'
          ],
          'Bypass Function': ['bypass enable', 'bypass mode', 'bypass'],
          'Solar Feed to Grid': [
            'feed to grid',
            'grid feed',
            'pv to grid',
            'pv feed to grid',
            'solar to grid',
            'export to grid',
            'grid export'
          ],
          'Beeps While Primary Source Interrupt': [
            'beep on primary source interrupt',
            'beep when primary source interrupt',
            'beep on source interrupt',
            'beep when source interrupt',
            'beep when ac lost',
            'beep on ac input lost',
            'beep on grid fail'
          ],
          'Over Temperature Auto Restart': [
            'over-temperature auto restart',
            'over temperature restart',
            'over temp auto restart',
            'over temp restart'
          ],
          'Power Saving Function': [
            'power saving',
            'energy saving',
            'eco mode',
            'eco',
            'sleep mode'
          ],
        };
    Map<String, List<String>> otherSyn() => {
          'Output Voltage': ['output voltage'],
          'Output Frequency': ['output frequency'],
          'LED Status': [
            'led status',
            'on-off control for rgb led',
            'on off control for rgb led'
          ],
          'LED Speed': ['led speed', 'lighting speed of rgb led'],
          'LED Effect': ['led effect', 'rgb led effects'],
          'LED Brightness': ['led brightness', 'brightness of rgb led'],
          'LED Data': ['led data', 'data presentation of data color'],
          'LED Color 1': ['led colour 1', 'led color1'],
          'LED Color 2': ['led colour 2', 'led color2'],
          'LED Color 3': ['led colour 3', 'led color3'],
          'AC Output Rating Voltage': ['ac output rating voltage'],
          'AC Output Rating Frequency': ['ac output rating frequency'],
          'Set Date Time': ['set date time', 'set datetime'],
          'Country Customized Regulations': ['country customized regulations'],
          'Reset PV energy storaget': [
            'reset pv energy storage',
            'reset pv energy'
          ],
        };
    Map<String, List<String>> systemSyn() => {
          'Restore to Default': [
            'restore default',
            'factory reset',
            'reset to default',
            'restore defaults'
          ]
        };

    String? canonicalFor(String category, String? name) {
      if (name == null || name.trim().isEmpty) return null;
      final n = norm(name);
      Map<String, List<String>> syn;
      List<String> canon;
      switch (category) {
        case 'Battery Settings':
          syn = batterySyn();
          canon = batteryList;
          break;
        case 'Basic Settings':
          syn = basicSyn();
          canon = basicList;
          break;
        case 'Standard Settings':
          syn = standardSyn();
          canon = standardList;
          break;
        case 'System Settings':
          syn = systemSyn();
          canon = systemList;
          break;
        default:
          syn = otherSyn();
          canon = otherList;
      }
      // exact canonical
      for (final c in canon) {
        if (eq(c, n)) return c;
      }
      // synonym hit
      for (final entry in syn.entries) {
        if (eq(entry.key, n)) return entry.key;
        for (final v in entry.value) {
          if (eq(v, n)) return entry.key;
        }
      }
      return null;
    }

    final grouped = <String, List<Field>>{
      for (final t in _tabsOrder) t: <Field>[]
    };

    // Helper: add if the field name matches any canonical item for that category
    void addIfMatch(String category, List<String> canon) {
      for (final f in all) {
        final name = f.name ?? '';
        final canonName = canonicalFor(category, name);
        if (canonName != null) {
          grouped[category]!.add(f);
        }
      }
      // keep only those that match canon list or synonyms; others will be ignored
    }

    addIfMatch('Battery Settings', batteryList);
    addIfMatch('Basic Settings', basicList);
    addIfMatch('Standard Settings', standardList);
    addIfMatch('System Settings', systemList);
    addIfMatch('Other Settings', otherList);

    // De-duplicate and finalize
    for (final k in grouped.keys) {
      final byId = <String, Field>{};
      for (final f in grouped[k]!) {
        byId[(f.id ?? f.name ?? '').toLowerCase()] = f;
      }
      grouped[k]!
        ..clear()
        ..addAll(byId.values);
    }

    return grouped;
  }

  List<Field> _orderCategoryFields(String category, List<Field> fields) {
    List<String> order;
    switch (category) {
      case 'Battery Settings':
        order = [
          'Battery Type',
          'Bulk Charging Voltage',
          'Float Charging Voltage',
          'Max. Charging Current',
          'Max Battery Discharge Current',
          'Max. AC Charging Current',
          'Charging Source Priority',
          'Battery Equalization',
          'Real-time Activate Battery Equalization',
          'Battery Equalization Time-out',
          'Battery Equalization Time',
          'Equalization Period',
          'Equalization Voltage',
          'Back to Grid Capacity',
          'Back to Discharge Capacity',
          'Battery Cut-off Capacity',
          // Expanded legacy variants
          'Battery Cut off Voltage',
          'Back To Grid Voltage',
          'Back To Discharge Voltage',
          'Li-BattreyAuto Turnon',
          'Li-Battrey Immediately Turnon',
        ];
        break;
      case 'Basic Settings':
        order = [
          'Output Source Priority',
          'AC Input Range',
          'AC Output Mode',
          'Phase 1 Of 3 Phase Output',
          'Phase 2 Of 3 Phase Output',
          'Phase 3 Of 3 Phase Output',
          'Battery Capacity to Turn Off AC2',
          'Discharge Time to turn Off AC2',
          'Time Interval to Turn Off AC2',
          'Time Interval to Turn On AC2',
          'Charge Time to turn off AC2',
          'Battery Capacity to turn On AC2',
          // Expanded scheduling/priorities
          'Start Time For Enable AC Charger Working',
          'Ending Time For Enable AC Charger Working',
          'Start time for enable AC supply the load',
          'Ending time for enable AC supply the load',
          'Solar Supply Priority',
        ];
        break;
      case 'Standard Settings':
        order = [
          'LCD Auto-return to Main Screen',
          'Overload Auto Restart',
          'Buzzer',
          'Fault Code Record',
          'Backlight',
          'Bypass Function',
          'Solar Feed to Grid',
          'Beeps While Primary Source Interrupt',
          'Over Temperature Auto Restart',
          'Power Saving Function',
        ];
        break;
      case 'System Settings':
        order = ['Restore to Default'];
        break;
      default: // Other Settings
        order = [
          'Output Voltage',
          'Output Frequency',
          'LED Status',
          'LED Speed',
          'LED Effect',
          'LED Brightness',
          'LED Data',
          'LED Color 1',
          'LED Color 2',
          'LED Color 3',
          // Expanded legacy variants/utilities
          'AC Output Rating Voltage',
          'AC Output Rating Frequency',
          'On-Off control for RGB LED',
          'Lighting speed of RGB LED',
          'Brightness of RGB LED',
          'RGB LED effects',
          'Data Presentation of data color',
          'Set Date Time',
          'Country Customized Regulations',
          'Reset PV energy storaget',
        ];
    }
    String norm(String s) => s.trim().toLowerCase();
    // use canonical mapping for ordering; drop items that don't map to a canonical
    String? canon(String n) => _canonicalFor(category, n);
    int idxOf(String name) {
      final c = canon(name);
      if (c == null) return 1 << 20;
      final i = order.indexWhere((o) => norm(o) == norm(c));
      return i < 0 ? 1 << 20 : i; // unknowns pushed to end (should be none)
    }

    final sorted = [...fields]
      ..sort((a, b) => idxOf(a.name ?? '').compareTo(idxOf(b.name ?? '')));
    // Keep only those that map to a canonical in the desired list
    return sorted.where((f) => canon(f.name ?? '') != null).toList();
  }

  // Expose canonical resolution for order function
  String? _canonicalFor(String category, String name) {
    String norm(String s) => s.trim().toLowerCase().replaceAll('_', ' ');
    final n = norm(name);
    // reuse the same logic as strictGrouped's canonicalFor via local copy
    // (Keep in sync with _strictGrouped canonicalFor)
    final batteryList = [
      'Battery Type',
      'Bulk Charging Voltage',
      'Float Charging Voltage',
      'Max. Charging Current',
      'Max Battery Discharge Current',
      'Max. AC Charging Current',
      'Charging Source Priority',
      'Battery Equalization',
      'Real-time Activate Battery Equalization',
      'Battery Equalization Time-out',
      'Battery Equalization Time',
      'Equalization Period',
      'Equalization Voltage',
      'Back to Grid Capacity',
      'Back to Discharge Capacity',
      'Battery Cut-off Capacity',
      // Expanded legacy variants
      'Battery Cut off Voltage',
      'Back To Grid Voltage',
      'Back To Discharge Voltage',
      'Li-BattreyAuto Turnon',
      'Li-Battrey Immediately Turnon',
    ];
    final basicList = [
      'Output Source Priority',
      'AC Input Range',
      'AC Output Mode',
      'Phase 1 Of 3 Phase Output',
      'Phase 2 Of 3 Phase Output',
      'Phase 3 Of 3 Phase Output',
      'Battery Capacity to Turn Off AC2',
      'Discharge Time to turn Off AC2',
      'Time Interval to Turn Off AC2',
      'Time Interval to Turn On AC2',
      'Charge Time to turn off AC2',
      'Battery Capacity to turn On AC2',
      // Expanded scheduling/priorities
      'Start Time For Enable AC Charger Working',
      'Ending Time For Enable AC Charger Working',
      'Start time for enable AC supply the load',
      'Ending time for enable AC supply the load',
      'Solar Supply Priority',
    ];
    final standardList = [
      'LCD Auto-return to Main Screen',
      'Overload Auto Restart',
      'Buzzer',
      'Fault Code Record',
      'Backlight',
      'Bypass Function',
      'Solar Feed to Grid',
      'Beeps While Primary Source Interrupt',
      'Over Temperature Auto Restart',
      'Power Saving Function',
    ];
    final systemList = ['Restore to Default'];
    final otherList = [
      'Output Voltage',
      'Output Frequency',
      'LED Status',
      'LED Speed',
      'LED Effect',
      'LED Brightness',
      'LED Data',
      'LED Color 1',
      'LED Color 2',
      'LED Color 3',
      // Expanded legacy variants/utilities
      'AC Output Rating Voltage',
      'AC Output Rating Frequency',
      'On-Off control for RGB LED',
      'Lighting speed of RGB LED',
      'Brightness of RGB LED',
      'RGB LED effects',
      'Data Presentation of data color',
      'Set Date Time',
      'Country Customized Regulations',
      'Reset PV energy storaget',
    ];
    Map<String, List<String>> syn;
    List<String> canon;
    switch (category) {
      case 'Battery Settings':
        syn = {
          'Battery Type': ['battery type'],
          'Bulk Charging Voltage': ['bulk charge voltage', 'bulk voltage'],
          'Float Charging Voltage': ['float charge voltage', 'float voltage'],
          'Max. Charging Current': [
            'max charging current',
            'maximum charging current',
            'max charge current'
          ],
          'Max Battery Discharge Current': [
            'max. battery discharge current',
            'max discharge current',
            'maximum discharge current'
          ],
          'Max. AC Charging Current': [
            'max ac charging current',
            'maximum ac charging current'
          ],
          'Charging Source Priority': [
            'charge source priority',
            'charging priority',
            'source priority (charging)',
            'solar supply priority',
          ],
          'Battery Equalization': [
            'battery equalisation',
            'equalization',
            'equalisation'
          ],
          'Real-time Activate Battery Equalization': [
            'realtime activate battery equalization',
            'real time activate battery equalization',
            'activate battery equalization',
            'activation battery equalization',
            'start equalization',
          ],
          'Battery Equalization Time-out': [
            'battery equalization timeout',
            'equalization timeout',
            'equalisation timeout',
            'equalization time out'
          ],
          'Battery Equalization Time': [
            'equalization time',
            'equalisation time',
            'equalization duration'
          ],
          'Equalization Period': [
            'equalization cycle',
            'equalisation cycle',
            'equalization interval'
          ],
          'Equalization Voltage': ['equalisation voltage'],
          'Back to Grid Capacity': [
            'return to grid capacity',
            'back to utility capacity'
          ],
          'Back to Discharge Capacity': [
            'return to discharge capacity',
            'back to discharge'
          ],
          'Battery Cut-off Capacity': [
            'battery cut off capacity',
            'battery cutoff capacity'
          ],
          // Expanded legacy variants
          'Battery Cut off Voltage': [
            'battery cut-off voltage',
            'battery cutoff voltage'
          ],
          'Back To Grid Voltage': [
            'back to grid voltage',
            'return to grid voltage'
          ],
          'Back To Discharge Voltage': [
            'back to discharge voltage',
            'return to discharge voltage'
          ],
          'Li-BattreyAuto Turnon': [
            'li-battery auto turn on',
            'li battery auto turn on',
            'li-battery auto turnon',
          ],
          'Li-Battrey Immediately Turnon': [
            'li-battery immediately turn on',
            'li battery immediately turn on',
            'li-battery immediately turnon',
          ],
        };
        canon = batteryList;
        break;
      case 'Basic Settings':
        syn = {
          'Output Source Priority': [
            'output priority',
            'source priority (output)'
          ],
          'AC Input Range': ['ac input range (apl/ups)', 'input voltage range'],
          'AC Output Mode': ['output mode'],
          'Phase 1 Of 3 Phase Output': [
            'phase 1 of three phase output',
            'phase 1 of 3-phase output'
          ],
          'Phase 2 Of 3 Phase Output': [
            'phase 2 of three phase output',
            'phase 2 of 3-phase output'
          ],
          'Phase 3 Of 3 Phase Output': [
            'phase 3 of three phase output',
            'phase 3 of 3-phase output'
          ],
          'Battery Capacity to Turn Off AC2': [
            'turn off ac2 battery capacity',
            'battery capacity to turn off ac 2'
          ],
          'Discharge Time to turn Off AC2': ['discharge time to turn off ac 2'],
          'Time Interval to Turn Off AC2': [
            'ac2 off interval',
            'time interval to turn off ac 2'
          ],
          'Time Interval to Turn On AC2': [
            'ac2 on interval',
            'time interval to turn on ac 2'
          ],
          'Charge Time to turn off AC2': ['charge time to turn off ac 2'],
          'Battery Capacity to turn On AC2': [
            'turn on ac2 battery capacity',
            'battery capacity to turn on ac 2'
          ],
          'Start Time For Enable AC Charger Working': [
            'start time for enable ac charger working',
            'ac charger start time'
          ],
          'Ending Time For Enable AC Charger Working': [
            'ending time for enable ac charger working',
            'ac charger end time'
          ],
          'Start time for enable AC supply the load': [
            'start time for enable ac supply the load',
            'ac supply start time'
          ],
          'Ending time for enable AC supply the load': [
            'ending time for enable ac supply the load',
            'ac supply end time'
          ],
          'Solar Supply Priority': [
            'solar supply priority',
            'solar priority',
            'solar first priority'
          ],
        };
        canon = basicList;
        break;
      case 'Standard Settings':
        syn = {
          'LCD Auto-return to Main Screen': [
            'lcd auto return to main screen',
            'lcd auto-return',
            'auto return to main',
            'return to main screen',
            'lcd return time',
            'display escape to default page after 1min timeout'
          ],
          'Overload Auto Restart': [
            'overload restart',
            'restart after overload'
          ],
          'Buzzer': ['beep', 'beeps', 'beeping', 'audio alarm'],
          'Fault Code Record': [
            'fault record',
            'fault log',
            'error code record',
            'error log',
            'alarm log'
          ],
          'Backlight': [
            'back light',
            'lcd light',
            'screen light',
            'display backlight',
            'lcd brightness'
          ],
          'Bypass Function': ['bypass enable', 'bypass mode', 'bypass'],
          'Solar Feed to Grid': [
            'feed to grid',
            'grid feed',
            'pv to grid',
            'pv feed to grid',
            'solar to grid',
            'export to grid',
            'grid export'
          ],
          'Beeps While Primary Source Interrupt': [
            'beep on primary source interrupt',
            'beep when primary source interrupt',
            'beep on source interrupt',
            'beep when source interrupt',
            'beep when ac lost',
            'beep on ac input lost',
            'beep on grid fail'
          ],
          'Over Temperature Auto Restart': [
            'over-temperature auto restart',
            'over temperature restart',
            'over temp auto restart',
            'over temp restart'
          ],
          'Power Saving Function': [
            'power saving',
            'energy saving',
            'eco mode',
            'eco',
            'sleep mode'
          ],
        };
        canon = standardList;
        break;
      case 'System Settings':
        syn = {
          'Restore to Default': [
            'restore default',
            'factory reset',
            'reset to default',
            'restore defaults'
          ]
        };
        canon = systemList;
        break;
      default:
        syn = {
          'Output Voltage': ['output voltage'],
          'Output Frequency': ['output frequency'],
          'LED Status': [
            'led status',
            'on-off control for rgb led',
            'on off control for rgb led'
          ],
          'LED Speed': ['led speed', 'lighting speed of rgb led'],
          'LED Effect': ['led effect', 'rgb led effects'],
          'LED Brightness': ['led brightness', 'brightness of rgb led'],
          'LED Data': ['led data', 'data presentation of data color'],
          'LED Color 1': ['led colour 1', 'led color1'],
          'LED Color 2': ['led colour 2', 'led color2'],
          'LED Color 3': ['led colour 3', 'led color3'],
          'AC Output Rating Voltage': ['ac output rating voltage'],
          'AC Output Rating Frequency': ['ac output rating frequency'],
          'Set Date Time': ['set date time', 'set datetime'],
          'Country Customized Regulations': ['country customized regulations'],
          'Reset PV energy storaget': [
            'reset pv energy storage',
            'reset pv energy'
          ],
          'On-Off control for RGB LED': [
            'on-off control for rgb led',
            'on off control for rgb led'
          ],
          'Lighting speed of RGB LED': [
            'lighting speed of rgb led',
            'led speed'
          ],
          'Brightness of RGB LED': ['brightness of rgb led', 'led brightness'],
          'RGB LED effects': ['rgb led effects', 'led effects', 'led effect'],
          'Data Presentation of data color': [
            'data presentation of data color',
            'led data'
          ],
        };
        canon = otherList;
    }
    for (final c in canon) {
      if (norm(c) == n) return c;
    }
    for (final entry in syn.entries) {
      if (norm(entry.key) == n) return entry.key;
      for (final v in entry.value) {
        if (norm(v) == n) return entry.key;
      }
    }
    return null;
  }

  Widget _msg(double width, String text) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 0.035 * width,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

// Simple pretty button card used on the main screen
class _CategoryCardButton extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  const _CategoryCardButton({
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: onTap,
      ),
    );
  }
}

// Category screen that lists fields using the existing legacy submenu
class _CategoryScreen extends StatelessWidget {
  final String category;
  final List<Field> fields;
  final String pn;
  final String sn;
  final int devcode;
  final int devaddr;
  const _CategoryScreen({
    required this.category,
    required this.fields,
    required this.pn,
    required this.sn,
    required this.devcode,
    required this.devaddr,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          category,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: fields.length,
        itemBuilder: (context, index) {
          final f = fields[index];
          final items = f.item ?? const <Item>[];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 18),
              ),
              title: Text(
                f.name ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              subtitle: _buildSub(f),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DataControlOldSubmenuScreen(
                      pn: pn,
                      sn: sn,
                      devaddr: devaddr,
                      devcode: devcode,
                      id: f.id ?? '',
                      fieldname: f.name ?? '',
                      unit: f.unit,
                      hint: f.hint,
                      items: items,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget? _buildSub(Field f) {
    final hasUnit = (f.unit != null && f.unit!.trim().isNotEmpty);
    final hasHint = (f.hint != null && f.hint!.trim().isNotEmpty);
    if (!hasUnit && !hasHint) return null;
    final pieces = <String>[];
    if (hasUnit) pieces.add('Unit: ${f.unit}');
    if (hasHint) pieces.add('Hint: ${f.hint}');
    return Text(
      pieces.join(' · '),
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
  }
}
