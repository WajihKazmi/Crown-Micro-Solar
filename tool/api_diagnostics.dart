// Diagnostic script: run with `flutter pub run tool/api_diagnostics.dart`
// Logs end-to-end flows (login -> plant -> devices -> key parameters / paging) for verification.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// Credentials (DO NOT SHIP THESE IN PROD CODE). Provided for temporary diagnostics.
const userCreds = [
  {'u': 'aatif100', 'p': 'hamza1', 'label': 'user'},
  {'u': 'asfer', 'p': 'asfer90123', 'label': 'installer'},
];

const salt = '12345678';
const postaction =
    '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
const base = 'http://api.dessmonitor.com/public/';

Future<void> main() async {
  print('=== API Diagnostics Start ===');
  final now = DateTime.now();
  final today = now.toIso8601String().substring(0, 10); // yyyy-MM-dd
  final yearMonth = '${now.year}-${_two(now.month)}';
  final year = now.year.toString();
  for (final c in userCreds) {
    print('\n--- LOGIN ${c['label']} ${c['u']} ---');
    final auth = await _crownLogin(c['u']!, c['p']!);
    if (auth == null) {
      _logJson({'phase': 'login', 'user': c['u'], 'ok': false});
      continue;
    }
    _logJson({'phase': 'login', 'user': c['u'], 'ok': true});
    final plants = await _queryPlants(auth);
    _logJson({'phase': 'plants', 'count': plants.length});
    if (plants.isEmpty) continue;
    final plantId = plants.first['pid'].toString();
    final devices = await _queryDevices(auth, plantId);
    final collectors = await _queryCollectors(auth, plantId);
    _logJson({
      'phase': 'inventory',
      'plant': plantId,
      'devices': devices.length,
      'collectors': collectors.length
    });
    if (devices.isEmpty) continue;
    final sample = devices.first;
    final sn = sample['sn'].toString();
    final pn = sample['pn'].toString();
    final devcode = sample['devcode'].toString();
    final devaddr = sample['devaddr'].toString();
    _logJson({
      'phase': 'sampleDevice',
      'sn': sn,
      'pn': pn,
      'devcode': devcode,
      'devaddr': devaddr
    });
    // Core logical metrics (one-day key parameter)
    for (final logical in const [
      'LOAD_POWER',
      'GRID_POWER',
      'PV_OUTPUT_POWER',
      'BATTERY_SOC'
    ]) {
      final res = await _queryKeyParameter(
          auth, pn, sn, devcode, devaddr, logical, today);
      _logJson({'phase': 'keyParamOneDay', 'logical': logical, ...res});
    }
    // One-day paging (raw columns)
    final paging =
        await _queryDataOneDayPaging(auth, pn, sn, devcode, devaddr, today);
    if (paging != null) {
      final titles = (paging['dat']?['title'] as List?)
              ?.map((e) => e['title'])
              .cast<String?>()
              .toList() ??
          [];
      _logJson({
        'phase': 'pagingOneDayMeta',
        'titleCount': titles.length,
        'rowCount': paging['dat']?['total']
      });
      for (final name in const [
        'Output Power',
        'Load Power',
        'Grid Power',
        'PV Power',
        'Battery SOC',
        'SOC',
        'Input Power'
      ]) {
        final v = _extractLatestPagingValue(paging, name);
        if (v != null) {
          _logJson({'phase': 'pagingOneDayValue', 'title': name, 'latest': v});
        }
      }
    }
    // Month per day (device key param) for ENERGY_TODAY + PV_OUTPUT_POWER
    for (final param in const ['ENERGY_TODAY', 'PV_OUTPUT_POWER']) {
      final m = await _querySPDeviceKeyParameterMonthPerDay(
          auth, pn, sn, devcode, devaddr, param, yearMonth);
      _logJson({
        'phase': 'deviceMonthPerDay',
        'parameter': param,
        'ok': m['err'] == 0,
        'count': _countParamRows(m)
      });
    }
    // Year per month (device key param)
    for (final param in const ['ENERGY_TODAY', 'PV_OUTPUT_POWER']) {
      final y = await _querySPDeviceKeyParameterYearPerMonth(
          auth, pn, sn, devcode, devaddr, param, year);
      _logJson({
        'phase': 'deviceYearPerMonth',
        'parameter': param,
        'ok': y['err'] == 0,
        'count': _countParamRows(y)
      });
    }
    // Total per year (device key param - aggregated year sequence)
    for (final param in const ['ENERGY_TODAY', 'PV_OUTPUT_POWER']) {
      final t = await _querySPDeviceKeyParameterTotalPerYear(
          auth, pn, sn, devcode, devaddr, param);
      _logJson({
        'phase': 'deviceTotalPerYear',
        'parameter': param,
        'ok': t['err'] == 0,
        'count': _countParamRows(t)
      });
    }
    // Plant level daily (all plants / single) energy month per day & year per month
    final plantDaily =
        await _queryPlantEnergyMonthPerDay(auth, plantId, yearMonth);
    _logJson({
      'phase': 'plantEnergyMonthPerDay',
      'ok': plantDaily['err'] == 0,
      'count': (plantDaily['dat']?['perday'] as List?)?.length ?? 0
    });
    final plantYear = await _queryPlantEnergyYearPerMonth(auth, plantId, year);
    _logJson({
      'phase': 'plantEnergyYearPerMonth',
      'ok': plantYear['err'] == 0,
      'count': (plantYear['dat']?['permonth'] as List?)?.length ?? 0
    });
    // All plants (portfolio) energy month per day & year per month for comparison
    final allPlantsMonth = await _queryPlantsEnergyMonthPerDay(auth, yearMonth);
    _logJson({
      'phase': 'plantsEnergyMonthPerDay',
      'ok': allPlantsMonth['err'] == 0,
      'count': (allPlantsMonth['dat']?['perday'] as List?)?.length ?? 0
    });
    final allPlantsYear = await _queryPlantsEnergyYearPerMonth(auth, year);
    _logJson({
      'phase': 'plantsEnergyYearPerMonth',
      'ok': allPlantsYear['err'] == 0,
      'count': (allPlantsYear['dat']?['permonth'] as List?)?.length ?? 0
    });
    // Plant active output power (all plants vs single) — using single plant variant for precision
    final plantActive =
        await _queryPlantActiveOutputPowerOneDay(auth, plantId, today);
    _logJson({
      'phase': 'plantActiveOutputPowerOneDay',
      'ok': plantActive['err'] == 0,
      'count': (plantActive['dat']?['outputPower'] as List?)?.length ?? 0
    });
    // All plants active output power
    final plantsActive = await _queryPlantsActiveOutputPowerOneDay(auth, today);
    _logJson({
      'phase': 'plantsActiveOutputPowerOneDay',
      'ok': plantsActive['err'] == 0,
      'count': (plantsActive['dat']?['outputPower'] as List?)?.length ?? 0
    });
    // Plant total per year energy timeline
    final plantTotalPerYear =
        await _queryPlantEnergyTotalPerYear(auth, plantId);
    _logJson({
      'phase': 'plantEnergyTotalPerYear',
      'ok': plantTotalPerYear['err'] == 0,
      'count': (plantTotalPerYear['dat']?['peryear'] as List?)?.length ?? 0
    });
    // Device energy quintet (today aggregate metrics)
    final quint = await _queryDeviceEnergyQuintetOneDay(
        auth, pn, sn, devcode, devaddr, today);
    _logJson({
      'phase': 'deviceEnergyQuintetOneDay',
      'ok': quint['err'] == 0,
      'fields': quint['dat'] == null
          ? []
          : quint['dat']
              .keys
              .where((k) =>
                  k.toString().startsWith('energy') ||
                  k.toString().contains('output'))
              .toList()
    });
  }
  print('\n=== API Diagnostics Complete ===');
}

class _AuthBundle {
  final String token;
  final String secret;
  final String userId;
  _AuthBundle(this.token, this.secret, this.userId);
}

Future<_AuthBundle?> _crownLogin(String user, String pass) async {
  final url = Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/Login');
  final body = jsonEncode({'UserName': user, 'Password': pass});
  final resp = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
      },
      body: body);
  if (resp.statusCode != 200) return null;
  final data = json.decode(resp.body);
  if (data['Token'] == null) return null;
  return _AuthBundle(data['Token'], data['Secret'], data['UserID'].toString());
}

String _sha1(String s) => sha1.convert(utf8.encode(s)).toString();

Future<List<dynamic>> _queryPlants(_AuthBundle auth) async {
  const action = '&action=webQueryPlants&page=0&pagesize=100';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  final js = json.decode(resp.body);
  return (js['dat']?['plant'] as List?) ?? [];
}

Future<Map<String, dynamic>> _queryPlantEnergyMonthPerDay(
    _AuthBundle auth, String plantId, String yearMonth) async {
  final action =
      '&action=queryPlantEnergyMonthPerDay&plantid=$plantId&date=$yearMonth';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantEnergyYearPerMonth(
    _AuthBundle auth, String plantId, String year) async {
  final action =
      '&action=queryPlantEnergyYearPerMonth&plantid=$plantId&date=$year';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantsEnergyMonthPerDay(
    _AuthBundle auth, String yearMonth) async {
  final action = '&action=queryPlantsEnergyMonthPerDay&date=$yearMonth';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantsEnergyYearPerMonth(
    _AuthBundle auth, String year) async {
  final action = '&action=queryPlantsEnergyYearPerMonth&date=$year';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantActiveOutputPowerOneDay(
    _AuthBundle auth, String plantId, String date) async {
  final action =
      '&action=queryPlantActiveOuputPowerOneDay&plantid=$plantId&date=$date';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantsActiveOutputPowerOneDay(
    _AuthBundle auth, String date) async {
  final action = '&action=queryPlantsActiveOuputPowerOneDay&date=$date';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryPlantEnergyTotalPerYear(
    _AuthBundle auth, String plantId) async {
  final action =
      '&action=queryPlantEnergyTotalPerYear&plantid=$plantId&source=1';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<List<dynamic>> _queryDevices(_AuthBundle auth, String plantId) async {
  final action =
      '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  final js = json.decode(resp.body);
  return (js['dat']?['device'] as List?) ?? [];
}

Future<List<dynamic>> _queryCollectors(_AuthBundle auth, String plantId) async {
  final action =
      '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  final js = json.decode(resp.body);
  return (js['dat']?['collector'] as List?) ?? [];
}

Future<Map<String, dynamic>?> _queryDataOneDayPaging(_AuthBundle auth,
    String pn, String sn, String devcode, String devaddr, String date) async {
  final action =
      '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date&page=0&pagesize=200&i18n=en_US';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  if (resp.statusCode != 200) return null;
  final js = json.decode(resp.body);
  return js;
}

Future<Map<String, dynamic>> _querySPDeviceKeyParameterMonthPerDay(
  _AuthBundle auth,
  String pn,
  String sn,
  String devcode,
  String devaddr,
  String parameter,
  String yearMonth,
) async {
  final action =
      '&action=querySPDeviceKeyParameterMonthPerDay&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false&date=$yearMonth';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _querySPDeviceKeyParameterYearPerMonth(
  _AuthBundle auth,
  String pn,
  String sn,
  String devcode,
  String devaddr,
  String parameter,
  String year,
) async {
  final action =
      '&action=querySPDeviceKeyParameterYearPerMonth&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false&date=$year';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _querySPDeviceKeyParameterTotalPerYear(
  _AuthBundle auth,
  String pn,
  String sn,
  String devcode,
  String devaddr,
  String parameter,
) async {
  final action =
      '&action=querySPDeviceKeyParameterTotalPerYear&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$parameter&chartStatus=false';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryDeviceEnergyQuintetOneDay(
  _AuthBundle auth,
  String pn,
  String sn,
  String devcode,
  String devaddr,
  String date,
) async {
  final action =
      '&action=queryDeviceEnergyQuintetOneDay&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date';
  final url = _signedUrl(auth, action);
  final resp = await http.post(Uri.parse(url));
  return json.decode(resp.body);
}

Future<Map<String, dynamic>> _queryKeyParameter(
    _AuthBundle auth,
    String pn,
    String sn,
    String devcode,
    String devaddr,
    String logical,
    String date) async {
  // Candidate list (subset) aligning with repository logic
  final candidatesMap = {
    'LOAD_POWER': ['LOAD_POWER', 'LOAD_ACTIVE_POWER', 'PLOAD', 'OUTPUT_POWER'],
    'GRID_POWER': [
      'GRID_POWER',
      'GRID_ACTIVE_POWER',
      'PGRID',
      'IMPORT_POWER',
      'EXPORT_POWER',
      'AC_INPUT_POWER',
      'UTILITY_POWER',
      'OUTPUT_POWER'
    ],
    'PV_OUTPUT_POWER': [
      'PV_OUTPUT_POWER',
      'PV_POWER',
      'INPUT_POWER',
      'PIN',
      'PV_POWER_P',
      'OUTPUT_POWER'
    ],
    'BATTERY_SOC': [
      'BATTERY_SOC',
      'SOC',
      'BAT_SOC',
      'BMS_SOC',
      'BATTERY_LEVEL',
      'SOC_PCT'
    ],
  };
  final cands = candidatesMap[logical] ?? [logical];
  for (final apiParam in cands) {
    final action =
        '&action=queryDeviceKeyParameterOneDay&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&parameter=$apiParam&date=$date&i18n=en_US';
    final url = _signedUrl(auth, action);
    final resp = await http.post(Uri.parse(url));
    if (resp.statusCode != 200) continue;
    final js = json.decode(resp.body);
    final err = js['err'];
    final desc = js['desc'];
    List rows = js['dat']?['parameter'] ?? js['dat']?['row'] ?? [];
    if (err == 0 && rows.isNotEmpty) {
      // find latest non-null value
      double? latest;
      String? ts;
      for (final r in rows) {
        final val = r['val'];
        final v = val is num ? val.toDouble() : double.tryParse(val.toString());
        if (v != null) {
          latest = v;
          ts = r['ts'];
        }
      }
      return {
        'err': err,
        'desc': desc,
        'latest': latest,
        'apiParam': apiParam,
        'count': rows.length,
        'ts': ts
      };
    }
    if (err == 0) {
      // but empty
      return {
        'err': err,
        'desc': 'EMPTY',
        'latest': null,
        'apiParam': apiParam,
        'count': 0
      };
    }
  }
  return {
    'err': -1,
    'desc': 'NO_SUCCESS',
    'latest': null,
    'apiParam': null,
    'count': 0
  };
}

String _signedUrl(_AuthBundle auth, String action) {
  final data = salt +
      auth.secret +
      auth.token +
      action +
      postaction; // order parallels repository logic
  final sign = _sha1(data);
  return '$base?sign=$sign&salt=$salt&token=${auth.token}$action$postaction';
}

void _logJson(Map<String, dynamic> m) {
  // Single-line JSON for easier downstream parsing / diffing
  print('DIAG:' + jsonEncode(m));
}

String _two(int v) => v < 10 ? '0$v' : '$v';

int _countParamRows(Map<String, dynamic> js) {
  final dat = js['dat'];
  if (dat == null) return 0;
  // various response shapes use `parameter`, `perday`, `permonth`, `peryear`
  for (final k in ['parameter', 'perday', 'permonth', 'peryear', 'row']) {
    final list = dat[k];
    if (list is List) return list.length;
  }
  return 0;
}

// Extract latest value by column title from paging response
num? _extractLatestPagingValue(Map<String, dynamic> paging, String title) {
  final dat = paging['dat'];
  if (dat == null) return null;
  final titles =
      (dat['title'] as List?)?.map((e) => e['title'] as String?).toList();
  final rows = (dat['row'] as List?);
  if (titles == null || rows == null || rows.isEmpty) return null;
  final idx =
      titles.indexWhere((t) => (t ?? '').toLowerCase() == title.toLowerCase());
  if (idx == -1) return null;
  final last = rows.last as Map<String, dynamic>;
  final field = last['field'] as List?;
  if (field == null || idx >= field.length) return null;
  final raw = field[idx];
  return raw is num ? raw : num.tryParse(raw.toString());
}
