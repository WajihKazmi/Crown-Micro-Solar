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
    'Energy Storage Machine Settings',
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
    print(
        'DataControlOld: Grouping ${all.length} fields for device - PN: ${widget.pn}, devcode: ${widget.devcode}, SN: ${widget.sn}');

    // DETECT DEVICE TYPE using DeviceModel (same detection used elsewhere)
    // Note: We don't have alias here, so detection is based on devcode and PN

    // 1. Arceus devices: devcode 6451 OR PN starts with F6000022
    final isArceusByDevcode = widget.devcode == 6451;
    final isArceusByPN = widget.pn.startsWith('F6000022');
    final isArceus = isArceusByDevcode || isArceusByPN;

    // 2. Detect other device types by devcode patterns
    // Nova: devcode 2304, 2449, 2452, 2400
    final isNova = [2304, 2449, 2452, 2400].contains(widget.devcode);

    // Elego: Typically devcode 512 with single PV input
    final isElego = widget.devcode == 512 && widget.pn.contains('ELEGO');

    // Xavier: Energy storage machine variants
    final isXavier = widget.devcode == 2048 || widget.devcode == 2560;

    print('DataControlOld: Device detection - devcode: ${widget.devcode}');
    print(
        'DataControlOld: Device type - Arceus: $isArceus, Nova: $isNova, Elego: $isElego, Xavier: $isXavier');

    // ARCEUS DEVICES: All fields go to "Other Settings" ONLY
    if (isArceus) {
      print(
          'DataControlOld: Arceus device detected (devcode=$isArceusByDevcode, PN=$isArceusByPN) - forcing all ${all.length} fields to Other Settings');
      for (final f in all) {
        print('  - Field: id=${f.id}, name=${f.name}');
      }
      final result = <String, List<Field>>{
        'Battery Settings': <Field>[],
        'Energy Storage Machine Settings': <Field>[],
        'System Settings': <Field>[],
        'Basic Settings': <Field>[],
        'Standard Settings': <Field>[],
        'Other Settings':
            List<Field>.from(all), // Copy all fields to Other Settings
      };
      print(
          'DataControlOld: Returning only Other Settings with ${result['Other Settings']!.length} fields');
      return result;
    }

    // Canonical label lists per category, ordered by device type
    // BATTERY SETTINGS - Comprehensive list covering all device models
    final batteryList = [
      // Core battery parameters (all devices)
      'Battery Type',
      'Battery Capacity',

      // Voltage settings (Nova, Elego, Xavier)
      'Bulk Charging Voltage',
      'Float Charging Voltage',
      'Equalization Voltage',
      'Battery Cut off Voltage',
      'Back To Grid Voltage',
      'Back To Discharge Voltage',

      // Current settings (Nova, Elego, Xavier)
      'Max. Charging Current',
      'Max Battery Discharge Current',
      'Max. AC Charging Current',
      'Battery Charging Current',

      // Capacity/SOC settings (Nova, Xavier)
      'Back to Grid Capacity',
      'Back to Discharge Capacity',
      'Battery Cut-off Capacity',

      // Charging priority and source (Nova, Elego)
      'Charging Source Priority',
      'Solar Supply Priority',
      'Charger Source Priority',

      // Equalization settings (Nova, Elego, Xavier)
      'Battery Equalization',
      'Real-time Activate Battery Equalization',
      'Battery Equalization Time-out',
      'Battery Equalization Time',
      'Equalization Period',

      // Lithium battery specific (Xavier, Nova)
      'Li-BattreyAuto Turnon',
      'Li-Battrey Immediately Turnon',
      'Lithium Battery Auto Turn On',
      'Lithium Battery Immediately Turn On',

      // Battery protection (all devices)
      'Battery Under Voltage',
      'Battery Over Voltage',
      'Battery Low Voltage Warning',
      'Battery Temperature Protection',

      // BMS settings (advanced devices)
      'BMS Protocol',
      'BMS Communication',
      'Battery Series Number',

      // Additional battery parameters
      'Battery Voltage Calibration',
      'Battery Current Calibration',
      'Battery Manufacturer',
      'Battery Model',

      // Elego specific battery extras
      'Battery Bulk Voltage',
      'Battery Float Voltage',
      'Charger Source Priority',

      // Nova specific battery extras - missing fields
      'Maximum Battery Discharge Current',
      'Battery Equalization Time out',
      'Battery Voltage to Turn On AC2',
      'Battery Voltage to Turn Off AC2',
      'Discharge Time to Turn Off AC2',
      'Discharge Time to Turn On AC2',
    ];

    // ENERGY STORAGE MACHINE SETTINGS - New category for Elego and similar devices
    final energyStorageMachineList = [
      'Solar supply priority (battery>load>utility or load>battery>utility)',
      'Solar Supply Priority',
      'reset pv energy storage (reset option)',
      'Reset PV energy storage',
      'country customized regulations(india germany or south-america)',
      'Country Customized Regulations',
      'start time for enabling AC charger working(input feild for time)',
      'Start Time For Enable AC Charger Working',
      'Start time for enable AC charger working',
      'ending time for enabling ac charger working(input feild for time)',
      'Ending Time For Enable AC Charger Working',
      'Ending time for enable AC charger working',
      'start time for anabling ac supply to load(input feild for time)',
      'Start time for enable AC supply the load',
      'Start Time for enable AC Supply to Load',
      'ending time for enabling ac supply to load(input feild for time)',
      'Ending time for enable AC supply the load',
      'Ending Time for enable AC Supply to Load',
      'set date time(caledar input feild)',
      'Set Date Time',
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
      // Old-app scheduling and priority variants (moved some to Energy Storage)
      'Input Voltage range',
      'Input Voltage Range',
      // Nova specific - missing fields
      'Time Turn On AC2',
      'Time Turn Off AC2',
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
      'Overload Restart',
      'Overload Bypass Function',
      'Alarm omn when primary source interuput',
      'Alarm omn when primary source interrupt',
      'Display Escape to default page after 1 min timeout',
      'Fault code record',
      'Solar Feed to Grid',
      'Li-Battery Auto Turn On',
      'Li-Battery Immediately TurnOn',
    ];
    final systemList = [
      'Restore to Default',
      'System Settings(Restore to default*)',
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
          // Core battery parameters
          'Battery Type': ['battery type', 'bat type'],
          'Battery Capacity': ['battery capacity', 'bat capacity'],

          // Voltage settings
          'Bulk Charging Voltage': [
            'bulk charge voltage',
            'bulk voltage',
            'bulk charging voltage'
          ],
          'Float Charging Voltage': [
            'float charge voltage',
            'float voltage',
            'float charging voltage'
          ],
          'Equalization Voltage': [
            'equalisation voltage',
            'equalization voltage'
          ],
          'Battery Cut off Voltage': [
            'battery cut-off voltage',
            'battery cutoff voltage',
            'battery cut off voltage',
            'cut off voltage'
          ],
          'Back To Grid Voltage': [
            'back to grid voltage',
            'return to grid voltage',
            'back to utility voltage'
          ],
          'Back To Discharge Voltage': [
            'back to discharge voltage',
            'return to discharge voltage',
            'back to battery voltage'
          ],
          'Battery Under Voltage': [
            'battery under voltage',
            'under voltage',
            'low voltage cutoff'
          ],
          'Battery Over Voltage': [
            'battery over voltage',
            'over voltage',
            'high voltage cutoff'
          ],
          'Battery Low Voltage Warning': [
            'battery low voltage warning',
            'low voltage warning'
          ],

          // Current settings
          'Max. Charging Current': [
            'max charging current',
            'maximum charging current',
            'max charge current',
            'max. charging current'
          ],
          'Max Battery Discharge Current': [
            'max. battery discharge current',
            'max discharge current',
            'maximum discharge current',
            'max. discharge current'
          ],
          'Max. AC Charging Current': [
            'max ac charging current',
            'maximum ac charging current',
            'max. ac charging current'
          ],
          'Battery Charging Current': [
            'battery charging current',
            'charging current',
            'charge current'
          ],

          // Capacity/SOC settings
          'Back to Grid Capacity': [
            'return to grid capacity',
            'back to utility capacity',
            'back to grid capacity',
            'return to grid soc'
          ],
          'Back to Discharge Capacity': [
            'return to discharge capacity',
            'back to discharge',
            'back to discharge capacity',
            'return to discharge soc'
          ],
          'Battery Cut-off Capacity': [
            'battery cut off capacity',
            'battery cutoff capacity',
            'battery cut-off capacity',
            'cut off capacity',
            'cutoff soc'
          ],

          // Charging priority
          'Charging Source Priority': [
            'charge source priority',
            'charging priority',
            'source priority (charging)',
            'charger source priority',
          ],
          'Solar Supply Priority': [
            'solar supply priority',
            'solar priority',
            'pv priority'
          ],
          'Charger Source Priority': [
            'charger source priority',
            'charger priority',
            'ac charger priority'
          ],

          // Equalization settings
          'Battery Equalization': [
            'battery equalisation',
            'equalization',
            'equalisation',
            'battery equalization enable'
          ],
          'Real-time Activate Battery Equalization': [
            'realtime activate battery equalization',
            'real time activate battery equalization',
            'activate battery equalization',
            'activation battery equalization',
            'start equalization',
            'real-time activate battery equalization'
          ],
          'Battery Equalization Time-out': [
            'battery equalization timeout',
            'equalization timeout',
            'equalisation timeout',
            'equalization time out',
            'battery equalization time-out'
          ],
          'Battery Equalization Time': [
            'equalization time',
            'equalisation time',
            'equalization duration',
            'battery equalization time'
          ],
          'Equalization Period': [
            'equalization cycle',
            'equalisation cycle',
            'equalization interval',
            'equalization period'
          ],

          // Lithium battery specific
          'Li-BattreyAuto Turnon': [
            'li-battery auto turn on',
            'li battery auto turn on',
            'li-battery auto turnon',
            'lithium auto turn on',
            'li-battreyauto turnon'
          ],
          'Li-Battrey Immediately Turnon': [
            'li-battery immediately turn on',
            'li battery immediately turn on',
            'li-battery immediately turnon',
            'lithium immediately turn on',
            'li-battrey immediately turnon'
          ],
          'Lithium Battery Auto Turn On': [
            'lithium battery auto turn on',
            'lithium auto turn on',
            'li battery auto on'
          ],
          'Lithium Battery Immediately Turn On': [
            'lithium battery immediately turn on',
            'lithium immediately turn on',
            'li battery immediate on'
          ],

          // Battery protection
          'Battery Temperature Protection': [
            'battery temperature protection',
            'battery temp protection',
            'temperature protection'
          ],

          // BMS settings
          'BMS Protocol': ['bms protocol', 'battery management protocol'],
          'BMS Communication': ['bms communication', 'bms comm'],
          'Battery Series Number': [
            'battery series number',
            'battery series',
            'cell series'
          ],

          // Additional parameters
          'Battery Voltage Calibration': [
            'battery voltage calibration',
            'voltage calibration'
          ],
          'Battery Current Calibration': [
            'battery current calibration',
            'current calibration'
          ],
          'Battery Manufacturer': [
            'battery manufacturer',
            'battery brand',
            'bat manufacturer'
          ],
          'Battery Model': ['battery model', 'bat model'],

          // Elego specific extras
          'Battery Bulk Voltage': [
            'battery bulk voltage',
            'bulk voltage',
            'bulk charge voltage'
          ],
          'Battery Float Voltage': [
            'battery float voltage',
            'float voltage',
            'float charge voltage'
          ],

          // Nova specific battery extras
          'Maximum Battery Discharge Current': [
            'maximum battery discharge current',
            'max battery discharge current',
            'max. battery discharge current',
            'maximum discharge current',
          ],
          'Battery Equalization Time out': [
            'battery equalization time out',
            'battery equalization timeout',
            'equalization time out',
            'equalization timeout',
          ],
          'Battery Voltage to Turn On AC2': [
            'battery voltage to turn on ac2',
            'battery voltage to turn on ac 2',
            'voltage to turn on ac2',
            'turn on ac2 voltage',
          ],
          'Battery Voltage to Turn Off AC2': [
            'battery voltage to turn off ac2',
            'battery voltage to turn off ac 2',
            'voltage to turn off ac2',
            'turn off ac2 voltage',
          ],
          'Discharge Time to Turn Off AC2': [
            'discharge time to turn off ac2',
            'discharge time to turn off ac 2',
            'discharge time turn off ac2',
          ],
          'Discharge Time to Turn On AC2': [
            'discharge time to turn on ac2',
            'discharge time to turn on ac 2',
            'discharge time turn on ac2',
          ],
        };

    // ENERGY STORAGE MACHINE SETTINGS synonyms
    Map<String, List<String>> energyStorageMachineSyn() => {
          'Solar supply priority (battery>load>utility or load>battery>utility)':
              [
            'solar supply priority (battery>load>utility or load>battery>utility)',
            'solar supply priority',
            'solar priority (battery>load>utility or load>battery>utility)',
            'solar priority',
            'pv supply priority',
          ],
          'Solar Supply Priority': [
            'solar supply priority',
            'solar priority',
            'pv priority',
            'solar first priority'
          ],
          'reset pv energy storage (reset option)': [
            'reset pv energy storage (reset option)',
            'reset pv energy storage',
            'reset pv energy',
            'reset energy storage',
          ],
          'Reset PV energy storage': [
            'reset pv energy storage',
            'reset pv energy',
            'reset energy storage',
          ],
          'country customized regulations(india germany or south-america)': [
            'country customized regulations(india germany or south-america)',
            'country customized regulations',
            'country regulations',
            'regional regulations',
          ],
          'Country Customized Regulations': [
            'country customized regulations',
            'country regulations',
            'regional regulations',
          ],
          'start time for enabling AC charger working(input feild for time)': [
            'start time for enabling ac charger working(input feild for time)',
            'start time for enabling ac charger working',
            'start time for enable ac charger working',
            'ac charger start time',
          ],
          'Start Time For Enable AC Charger Working': [
            'start time for enable ac charger working',
            'ac charger start time',
            'ac charger working start time',
          ],
          'Start time for enable AC charger working': [
            'start time for enable ac charger working',
            'ac charger start time',
          ],
          'ending time for enabling ac charger working(input feild for time)': [
            'ending time for enabling ac charger working(input feild for time)',
            'ending time for enabling ac charger working',
            'ending time for enable ac charger working',
            'ac charger end time',
            'ac charger ending time',
          ],
          'Ending Time For Enable AC Charger Working': [
            'ending time for enable ac charger working',
            'ac charger end time',
            'ac charger working end time',
          ],
          'Ending time for enable AC charger working': [
            'ending time for enable ac charger working',
            'ac charger end time',
          ],
          'start time for anabling ac supply to load(input feild for time)': [
            'start time for anabling ac supply to load(input feild for time)',
            'start time for enabling ac supply to load',
            'start time for enable ac supply to load',
            'start time for enable ac supply the load',
            'ac supply start time',
          ],
          'Start time for enable AC supply the load': [
            'start time for enable ac supply the load',
            'start time for enable ac supply to load',
            'ac supply start time',
            'ac supply to load start time',
          ],
          'Start Time for enable AC Supply to Load': [
            'start time for enable ac supply to load',
            'ac supply start time',
          ],
          'ending time for enabling ac supply to load(input feild for time)': [
            'ending time for enabling ac supply to load(input feild for time)',
            'ending time for enabling ac supply to load',
            'ending time for enable ac supply to load',
            'ending time for enable ac supply the load',
            'ac supply end time',
            'ac supply ending time',
          ],
          'Ending time for enable AC supply the load': [
            'ending time for enable ac supply the load',
            'ending time for enable ac supply to load',
            'ac supply end time',
            'ac supply to load end time',
          ],
          'Ending Time for enable AC Supply to Load': [
            'ending time for enable ac supply to load',
            'ac supply end time',
          ],
          'set date time(caledar input feild)': [
            'set date time(caledar input feild)',
            'set date time',
            'set datetime',
            'date time setting',
          ],
          'Set Date Time': [
            'set date time',
            'set datetime',
            'date time setting',
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
          // Nova specific basic settings
          'Time Turn On AC2': [
            'time turn on ac2',
            'time turn on ac 2',
            'ac2 turn on time',
            'turn on time ac2',
          ],
          'Time Turn Off AC2': [
            'time turn off ac2',
            'time turn off ac 2',
            'ac2 turn off time',
            'turn off time ac2',
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
        case 'Energy Storage Machine Settings':
          syn = energyStorageMachineSyn();
          canon = energyStorageMachineList;
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
    addIfMatch('Energy Storage Machine Settings', energyStorageMachineList);
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
    // ARCEUS DEVICES: Return all fields as-is without filtering
    // Detect Arceus by devcode 6451 or PN pattern
    final isArceusByDevcode = widget.devcode == 6451;
    final isArceusByPN = widget.pn.startsWith('F6000022');

    if ((isArceusByDevcode || isArceusByPN) && category == 'Other Settings') {
      print(
          'DataControlOld: Arceus device - returning all ${fields.length} fields for Other Settings without filtering');
      return fields; // Return all fields as-is for Arceus
    }

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
          // Elego specific
          'Battery Bulk Voltage',
          'Battery Float Voltage',
          'Charger Source Priority',
          // Nova specific
          'Maximum Battery Discharge Current',
          'Battery Equalization Time out',
          'Battery Voltage to Turn On AC2',
          'Battery Voltage to Turn Off AC2',
          'Discharge Time to Turn Off AC2',
          'Discharge Time to Turn On AC2',
        ];
        break;
      case 'Energy Storage Machine Settings':
        order = [
          'Solar supply priority (battery>load>utility or load>battery>utility)',
          'Solar Supply Priority',
          'reset pv energy storage (reset option)',
          'Reset PV energy storage',
          'country customized regulations(india germany or south-america)',
          'Country Customized Regulations',
          'start time for enabling AC charger working(input feild for time)',
          'Start Time For Enable AC Charger Working',
          'Start time for enable AC charger working',
          'ending time for enabling ac charger working(input feild for time)',
          'Ending Time For Enable AC Charger Working',
          'Ending time for enable AC charger working',
          'start time for anabling ac supply to load(input feild for time)',
          'Start time for enable AC supply the load',
          'Start Time for enable AC Supply to Load',
          'ending time for enabling ac supply to load(input feild for time)',
          'Ending time for enable AC supply the load',
          'Ending Time for enable AC Supply to Load',
          'set date time(caledar input feild)',
          'Set Date Time',
        ];
        break;
      case 'Basic Settings':
        order = [
          'Output Source Priority',
          'AC Input Range',
          'Input Voltage range',
          'Input Voltage Range',
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
          // Nova specific
          'Time Turn On AC2',
          'Time Turn Off AC2',
        ];
        break;
      case 'Standard Settings':
        order = [
          'LCD Auto-return to Main Screen',
          'Overload Auto Restart',
          'Overload Restart',
          'Buzzer',
          'Fault Code Record',
          'Fault code record',
          'Backlight',
          'Bypass Function',
          'Overload Bypass Function',
          'Solar Feed to Grid',
          'Beeps While Primary Source Interrupt',
          'Alarm omn when primary source interuput',
          'Alarm omn when primary source interrupt',
          'Over Temperature Auto Restart',
          'Power Saving Function',
          'Display Escape to default page after 1 min timeout',
          'Li-Battery Auto Turn On',
          'Li-Battery Immediately TurnOn',
        ];
        break;
      case 'System Settings':
        order = ['Restore to Default', 'System Settings(Restore to default*)'];
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
