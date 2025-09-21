import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crown_micro_solar/presentation/models/device/device_data_one_day_query_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_live_signal_model.dart';

// Top-level helper classes for metric resolution results.
class MetricResolutionResult {
  final String logicalMetric;
  final String?
      apiParameter; // Resolved API param or indicator (paging_column / live_signal)
  final String
      source; // key_param_one_day | paging | live_signal | unsupported | none
  final double? latestValue;
  final int pointCount;
  final String? timestamp; // ISO8601 string of latest point
  final List<Map<String, dynamic>> series; // optional future expansion
  const MetricResolutionResult({
    required this.logicalMetric,
    required this.apiParameter,
    required this.source,
    required this.latestValue,
    required this.pointCount,
    required this.timestamp,
    required this.series,
  });
  bool get hasData => latestValue != null && pointCount > 0;
}

// Simplified energy flow model (subset of old app fields)
class DeviceEnergyFlowItem {
  final String par;
  final double? value;
  final String? unit;
  final int? status;
  DeviceEnergyFlowItem({required this.par, this.value, this.unit, this.status});
  factory DeviceEnergyFlowItem.fromJson(Map<String, dynamic> j) =>
      DeviceEnergyFlowItem(
        par: j['par']?.toString() ?? '',
        value: j['val'] != null ? double.tryParse(j['val'].toString()) : null,
        unit: j['unit']?.toString(),
        status: j['status'] is int
            ? j['status'] as int
            : int.tryParse(j['status']?.toString() ?? ''),
      );
}

class DeviceEnergyFlowModel {
  final List<DeviceEnergyFlowItem> btStatus;
  final List<DeviceEnergyFlowItem> pvStatus;
  final List<DeviceEnergyFlowItem> gdStatus;
  final List<DeviceEnergyFlowItem> bcStatus; // load?
  final List<DeviceEnergyFlowItem> olStatus; // output load
  DeviceEnergyFlowModel({
    required this.btStatus,
    required this.pvStatus,
    required this.gdStatus,
    required this.bcStatus,
    required this.olStatus,
  });
  factory DeviceEnergyFlowModel.fromJson(Map<String, dynamic> j) {
    List<DeviceEnergyFlowItem> _list(String key) => (j[key] is List)
        ? (j[key] as List)
            .whereType<Map>()
            .map((e) =>
                DeviceEnergyFlowItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <DeviceEnergyFlowItem>[];
    return DeviceEnergyFlowModel(
      btStatus: _list('bt_status'),
      pvStatus: _list('pv_status'),
      gdStatus: _list('gd_status'),
      bcStatus: _list('bc_status'),
      olStatus: _list('ol_status'),
    );
  }

  // NOTE: API mixes units (kW for pv/load, sometimes V for grid "active power").
  // We normalize returned power values to Watts (W) so UI formatters can divide by 1000 for kW display.
  double? get batterySoc {
    // Prefer an entry whose par name hints at SOC / capacity
    for (final b in btStatus) {
      final p = (b.par).toLowerCase();
      if (p.contains('soc') || p.contains('capacity')) {
        return b.value; // already %
      }
    }
    // Fallback: first value if plausible percentage (0-100)
    if (btStatus.isNotEmpty) {
      final v = btStatus.first.value;
      if (v != null && v >= 0 && v <= 100) return v;
    }
    return null;
  }

  double? get batteryPower {
    // Search for active power related entry (exclude soc/capacity)
    for (final b in btStatus) {
      final p = (b.par).toLowerCase();
      if (p.contains('power') &&
          !p.contains('capacity') &&
          !p.contains('soc')) {
        final unit = (b.unit ?? '').toLowerCase();
        if (unit == 'kw') return (b.value ?? 0) * 1000;
        return b.value;
      }
    }
    // Fallback: second element heuristic if it looks like power (value > 100 and not % style)
    if (btStatus.length > 1) {
      final cand = btStatus[1];
      final unit = (cand.unit ?? '').toLowerCase();
      if (unit == 'kw') return (cand.value ?? 0) * 1000;
      if (cand.value != null && (cand.value! > 100 || unit == 'w'))
        return cand.value;
    }
    return null;
  }

  double? get pvPower {
    if (pvStatus.isEmpty) return null;
    double sumW = 0;
    for (final p in pvStatus) {
      if (p.value == null) continue;
      final unit = (p.unit ?? '').toLowerCase();
      sumW += unit == 'kw' ? p.value! * 1000 : p.value!;
    }
    return sumW;
  }

  // Attempt to derive PV voltage if any pvStatus entry is in volts
  double? get pvVoltage {
    for (final p in pvStatus) {
      final unit = (p.unit ?? '').toLowerCase();
      final par = (p.par).toLowerCase();
      if (unit == 'v' || par.contains('volt')) return p.value;
    }
    return null;
  }

  // Battery voltage (typical range 12-60V or higher for stacks). Look for V unit or 'volt' keyword.
  double? get batteryVoltage {
    // Direct match on unit V or parameter name containing volt
    for (final b in btStatus) {
      final unit = (b.unit ?? '').toLowerCase();
      final par = (b.par).toLowerCase();
      if (unit == 'v' || par.contains('volt')) return b.value;
    }
    // Heuristic: look for a value in plausible battery stack voltage range (10-800V) that is
    // not a percentage (exclude soc / capacity) and not a power unit.
    DeviceEnergyFlowItem? candidate;
    for (final b in btStatus) {
      final unit = (b.unit ?? '').toLowerCase();
      final par = (b.par).toLowerCase();
      final val = b.value;
      if (val == null) continue;
      if (par.contains('soc') || par.contains('capacity')) continue;
      if (unit == 'kw' || unit == 'w' || unit == '%') continue;
      if (val >= 10 && val <= 800) {
        candidate = b;
        break; // first plausible
      }
    }
    return candidate?.value;
  }

  double? get gridPower {
    if (gdStatus.isEmpty) return null;
    // Prefer entry whose par mentions power / active
    DeviceEnergyFlowItem? best;
    for (final g in gdStatus) {
      final par = (g.par).toLowerCase();
      if (par.contains('power')) {
        best = g;
        break;
      }
    }
    // Fallback: any non-voltage unit entry
    best ??= gdStatus.firstWhere((g) => (g.unit ?? '').toLowerCase() != 'v',
        orElse: () => gdStatus.first);
    final unit = (best.unit ?? '').toLowerCase();
    if (unit == 'v') return null; // only voltage present
    if (unit == 'kw') return (best.value ?? 0) * 1000;
    return best.value; // assume already W
  }

  double? get gridVoltage {
    if (gdStatus.isEmpty) return null;
    // Find voltage entry either by unit V or par containing voltage
    for (final g in gdStatus) {
      final unit = (g.unit ?? '').toLowerCase();
      final par = (g.par).toLowerCase();
      if (unit == 'v' || par.contains('volt')) return g.value;
    }
    return null;
  }

  double? get loadPower {
    // Combine possible lists; prioritize explicit load/output active power names
    final combined = <DeviceEnergyFlowItem>[];
    combined.addAll(bcStatus);
    combined.addAll(olStatus);
    if (combined.isEmpty) return null;
    DeviceEnergyFlowItem? best;
    for (final l in combined) {
      final par = (l.par).toLowerCase();
      if (par.contains('active') && par.contains('power')) {
        best = l;
        break;
      }
    }
    best ??= combined.firstWhere((l) => (l.par).toLowerCase().contains('load'),
        orElse: () => combined.first);
    final unit = (best.unit ?? '').toLowerCase();
    if (unit == 'kw') return (best.value ?? 0) * 1000;
    return best.value;
  }

  int? get pvStatusDir => pvStatus.any((e) => (e.status ?? 0) > 0) ? 1 : 0;
  int? get loadStatusDir => bcStatus.isNotEmpty ? bcStatus.first.status : null;
  int? get gridStatusDir => gdStatus.isNotEmpty ? gdStatus.first.status : null;
  int? get batteryStatusDir =>
      btStatus.isNotEmpty ? btStatus.first.status : null;
}

class _PagingExtractResult {
  final double value;
  final int count;
  final String? ts;
  final List<String> candidatesTried;
  _PagingExtractResult(this.value, this.count, this.ts, this.candidatesTried);
}

class DeviceRepository {
  final ApiClient _apiClient;
  // Cache for successful logical parameter -> concrete API parameter resolution
  final Map<String, String> _parameterResolutionCache = {};
  // Negative cache to avoid repeated failing attempts (logical key -> timestamp)
  final Map<String, DateTime> _parameterNegativeCache = {};
  // Device capability map (devcode -> supported logical metrics)
  // Logical metrics: PV_OUTPUT_POWER, LOAD_POWER, GRID_POWER, BATTERY_SOC, AC2_OUTPUT_VOLTAGE, AC2_OUTPUT_CURRENT, PV_INPUT_VOLTAGE, PV_INPUT_CURRENT, GRID_FREQUENCY
  static final Map<int, Set<String>> _deviceCapabilities = {
    // Inverter
    512: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    // Env monitor (no power metrics)
    768: {},
    // Smart meter
    1024: {
      'GRID_POWER',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    // Battery
    1792: {
      'BATTERY_SOC',
      'LOAD_POWER',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
    },
    // Charger (limited metrics)
    2048: {
      'LOAD_POWER',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
    },
    // Energy storage machines (broad support) 2304 / 2400-range / 2449 / 2452
    2304: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'GRID_POWER',
      'BATTERY_SOC',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    2400: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'GRID_POWER',
      'BATTERY_SOC',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    2449: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'GRID_POWER',
      'BATTERY_SOC',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    2451: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'GRID_POWER',
      'BATTERY_SOC',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
    2452: {
      'PV_OUTPUT_POWER',
      'LOAD_POWER',
      'GRID_POWER',
      'BATTERY_SOC',
      'AC2_OUTPUT_VOLTAGE',
      'AC2_OUTPUT_CURRENT',
      'PV_INPUT_VOLTAGE',
      'PV_INPUT_CURRENT',
      'GRID_FREQUENCY',
    },
  };

  DeviceRepository(this._apiClient);

  // Structured result model (lightweight) for metric resolution; full model defined inline to avoid extra import churn.
  // If we later promote to its own file we can refactor usages without behavior change.
  // A point is represented as Map { 'ts': DateTime iso string, 'val': double }
  // Source values: key_param_one_day | paging | live_signal | unsupported | none
  // NOTE: Series population is partial for paging (future enhancement) – we focus on latest value mapping now.
  Future<MetricResolutionResult> resolveMetricOneDay({
    required String logicalMetric,
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
  }) async {
    // 1. Try key parameter (includes candidate resolution + live signal fallback)
    final keyRes = await fetchDeviceKeyParameterOneDay(
      sn: sn,
      pn: pn,
      devcode: devcode,
      devaddr: devaddr,
      parameter: logicalMetric,
      date: date,
    );
    if (keyRes is Map && keyRes['err'] == 0) {
      final dat = keyRes['dat'];
      final rows = (dat != null) ? (dat['parameter'] ?? dat['row']) : null;
      double? latest;
      String? ts;
      int count = 0;
      final series = <Map<String, dynamic>>[];
      if (rows is List) {
        count = rows.length;
        for (final r in rows) {
          if (r is Map) {
            final v = r['val'];
            final d = (v is num) ? v.toDouble() : double.tryParse(v.toString());
            final rTs = r['ts']?.toString();
            if (d != null) {
              latest = d;
              ts = rTs;
              if (rTs != null) {
                series.add({'ts': rTs, 'val': d});
              }
            }
          }
        }
      } else if (keyRes['source'] == 'live_signal') {
        // Single value live signal fallback
        latest = (keyRes['value'] is num)
            ? (keyRes['value'] as num).toDouble()
            : double.tryParse(keyRes['value'].toString());
        ts = DateTime.now().toIso8601String();
        count = latest == null ? 0 : 1;
        if (latest != null) {
          series.add({'ts': ts, 'val': latest});
        }
      }
      if (latest != null) {
        return MetricResolutionResult(
          logicalMetric: logicalMetric,
          apiParameter: keyRes['source'] == 'live_signal'
              ? keyRes['source']
              : _parameterResolutionCache.entries
                  .firstWhere((e) => e.key.contains(':$devaddr:$logicalMetric'),
                      orElse: () => MapEntry('', logicalMetric))
                  .value,
          source: keyRes['source'] == 'live_signal'
              ? 'live_signal'
              : 'key_param_one_day',
          latestValue: latest,
          pointCount: count,
          timestamp: ts,
          series: series,
        );
      }
    }

    // 2. If no success, try paging column extraction
    final paging = await fetchDeviceDataOneDayPaging(
      sn: sn,
      pn: pn,
      devcode: devcode,
      devaddr: devaddr,
      date: date,
      page: 0,
      pageSize: 200,
    );
    if (paging != null) {
      final latest = _extractFromPagingForLogical(paging, logicalMetric);
      if (latest != null) {
        // Build series from paging rows (improved mapping using real column titles)
        final dat = paging['dat'];
        final titles = (dat['title'] as List?)
                ?.map((e) => (e as Map)['title']?.toString() ?? '')
                .toList() ??
            [];
        final rows = (dat['row'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final tsCol = titles.indexWhere((t) =>
            t.toLowerCase().trim() == 'timestamp'); // timestamp column index
        int indexOf(String name) => titles.indexWhere(
            (t) => t.toLowerCase().trim() == name.toLowerCase().trim());
        double? toDouble(dynamic raw) =>
            raw is num ? raw.toDouble() : double.tryParse(raw.toString());

        // Pre-resolve key column indices we might need
        final pv1Idx = indexOf('PV1 Charging Power');
        final pv2Idx = indexOf('PV2 Charging power');
        final loadIdx = indexOf('AC Output Active Power');
        final batterySocIdx = indexOf('Battery Capacity');
        final gridFeedIdx = indexOf('Solar Feed To Grid Power');
        final acVoltIdx = indexOf('AC1 Output Voltage');
        final acCurrIdx = indexOf('AC Output Rating Current');
        final acPowerIdx = indexOf('AC Output Active Power');
        final pv1VoltIdx = indexOf('PV1 Input Voltage');
        final pv2VoltIdx = indexOf('PV2 Input voltage');

        // Fallback resolved single column index (if not multi-column)
        int? singleColIdx;
        for (final cand in latest.candidatesTried) {
          final idx = indexOf(cand);
          if (idx != -1) {
            singleColIdx = idx;
            break;
          }
        }

        final series = <Map<String, dynamic>>[];
        for (final r in rows) {
          final field = r['field'];
          if (field is! List) continue;
          String? ts;
          if (tsCol != -1 && tsCol < field.length) {
            final tsRaw = field[tsCol];
            ts = tsRaw?.toString();
          }
          // If timestamp missing, skip (cannot bucket properly)
          ts ??= DateTime.now().toIso8601String();
          double? value;
          switch (logicalMetric) {
            case 'PV_OUTPUT_POWER':
              double sum = 0;
              bool any = false;
              if (pv1Idx != -1 && pv1Idx < field.length) {
                final v = toDouble(field[pv1Idx]);
                if (v != null) {
                  sum += v;
                  any = true;
                }
              }
              if (pv2Idx != -1 && pv2Idx < field.length) {
                final v = toDouble(field[pv2Idx]);
                if (v != null) {
                  sum += v;
                  any = true;
                }
              }
              if (any)
                value = sum;
              else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'LOAD_POWER':
              if (loadIdx != -1 && loadIdx < field.length) {
                value = toDouble(field[loadIdx]);
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'GRID_POWER':
              if (gridFeedIdx != -1 && gridFeedIdx < field.length) {
                value = toDouble(field[gridFeedIdx]);
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'BATTERY_SOC':
              if (batterySocIdx != -1 && batterySocIdx < field.length) {
                value = toDouble(field[batterySocIdx]);
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'AC2_OUTPUT_VOLTAGE':
              if (acVoltIdx != -1 && acVoltIdx < field.length) {
                value = toDouble(field[acVoltIdx]);
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'AC2_OUTPUT_CURRENT':
              if (acCurrIdx != -1 && acCurrIdx < field.length) {
                value = toDouble(field[acCurrIdx]);
              } else if (acPowerIdx != -1 &&
                  acVoltIdx != -1 &&
                  acPowerIdx < field.length &&
                  acVoltIdx < field.length) {
                final p = toDouble(field[acPowerIdx]);
                final v = toDouble(field[acVoltIdx]);
                if (p != null && v != null && v > 0) value = p / v;
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'PV_INPUT_VOLTAGE':
              if (pv1VoltIdx != -1 && pv1VoltIdx < field.length) {
                value = toDouble(field[pv1VoltIdx]);
              } else if (pv2VoltIdx != -1 && pv2VoltIdx < field.length) {
                value = toDouble(field[pv2VoltIdx]);
              } else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            case 'PV_INPUT_CURRENT':
              double totalI = 0;
              bool anyI = false;
              if (pv1VoltIdx != -1 &&
                  pv1VoltIdx < field.length &&
                  pv1Idx != -1 &&
                  pv1Idx < field.length) {
                final vlt = toDouble(field[pv1VoltIdx]);
                final pow = toDouble(field[pv1Idx]);
                if (vlt != null && vlt > 0 && pow != null) {
                  totalI += pow / vlt;
                  anyI = true;
                }
              }
              if (pv2VoltIdx != -1 &&
                  pv2VoltIdx < field.length &&
                  pv2Idx != -1 &&
                  pv2Idx < field.length) {
                final vlt = toDouble(field[pv2VoltIdx]);
                final pow = toDouble(field[pv2Idx]);
                if (vlt != null && vlt > 0 && pow != null) {
                  totalI += pow / vlt;
                  anyI = true;
                }
              }
              if (anyI)
                value = totalI;
              else if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
              break;
            default:
              if (singleColIdx != null && singleColIdx < field.length) {
                value = toDouble(field[singleColIdx]);
              }
          }
          if (value != null) {
            series.add({'ts': ts, 'val': value});
          }
        }
        return MetricResolutionResult(
          logicalMetric: logicalMetric,
          apiParameter: 'paging_column',
          source: 'paging',
          latestValue: latest.value,
          pointCount: latest.count,
          timestamp: latest.ts,
          series: series,
        );
      }
    }

    // 3. Unsupported / none
    final supported = deviceSupportsParameter(devcode, logicalMetric);
    return MetricResolutionResult(
      logicalMetric: logicalMetric,
      apiParameter: null,
      source: supported ? 'none' : 'unsupported',
      latestValue: null,
      pointCount: 0,
      timestamp: null,
      series: const [],
    );
  }

  // Resolve a metric aggregated per-day for a month using SP endpoint.
  Future<MetricResolutionResult> resolveMetricMonthPerDay({
    required String logicalMetric,
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String yearMonth, // 'YYYY-MM'
  }) async {
    // Capability quick check
    if (!deviceSupportsParameter(devcode, logicalMetric)) {
      return const MetricResolutionResult(
        logicalMetric: '',
        apiParameter: null,
        source: 'unsupported',
        latestValue: null,
        pointCount: 0,
        timestamp: null,
        series: [],
      );
    }
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';

    final candidates = _parameterCandidates(logicalMetric, devcode);
    for (final apiParameter in candidates) {
      final action =
          '&action=querySPDeviceKeyParameterMonthPerDay&pn=$pn&sn=$validSn&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$apiParameter&chartStatus=false&date=$yearMonth';
      final data = salt + secret + token + action + postaction;
      final sign = sha1.convert(utf8.encode(data)).toString();
      final url =
          'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
      try {
        final response = await _apiClient.signedPost(url);
        final js = json.decode(response.body);
        if (js['err'] == 0) {
          final dat = js['dat'];
          List list = const [];
          if (dat is Map) {
            list = dat['perday'] ??
                dat['permonth'] ??
                dat['parameter'] ??
                dat['row'] ??
                const [];
          }
          final series = <Map<String, dynamic>>[];
          double? latest;
          String? ts;
          for (final e in list) {
            if (e is Map) {
              final v = e['val'];
              final d = v is num ? v.toDouble() : double.tryParse('${v}');
              final t = e['ts']?.toString();
              if (d != null) {
                latest = d;
                ts = t;
                series.add({'ts': t ?? '', 'val': d});
              }
            }
          }
          if (series.isNotEmpty) {
            return MetricResolutionResult(
              logicalMetric: logicalMetric,
              apiParameter: apiParameter,
              source: 'key_param_month_per_day',
              latestValue: latest,
              pointCount: series.length,
              timestamp: ts,
              series: series,
            );
          }
        }
      } catch (_) {
        // try next candidate
      }
    }
    return const MetricResolutionResult(
      logicalMetric: '',
      apiParameter: null,
      source: 'none',
      latestValue: null,
      pointCount: 0,
      timestamp: null,
      series: [],
    );
  }

  // Resolve a metric aggregated per-month for a year using SP endpoint.
  Future<MetricResolutionResult> resolveMetricYearPerMonth({
    required String logicalMetric,
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String year, // 'YYYY'
  }) async {
    if (!deviceSupportsParameter(devcode, logicalMetric)) {
      return const MetricResolutionResult(
        logicalMetric: '',
        apiParameter: null,
        source: 'unsupported',
        latestValue: null,
        pointCount: 0,
        timestamp: null,
        series: [],
      );
    }
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';

    final candidates = _parameterCandidates(logicalMetric, devcode);
    for (final apiParameter in candidates) {
      final action =
          '&action=querySPDeviceKeyParameterYearPerMonth&pn=$pn&sn=$validSn&devcode=$devcode&devaddr=$devaddr&i18n=en_US&parameter=$apiParameter&chartStatus=false&date=$year';
      final data = salt + secret + token + action + postaction;
      final sign = sha1.convert(utf8.encode(data)).toString();
      final url =
          'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
      try {
        final response = await _apiClient.signedPost(url);
        final js = json.decode(response.body);
        if (js['err'] == 0) {
          final dat = js['dat'];
          List list = const [];
          if (dat is Map) {
            list = dat['permonth'] ??
                dat['peryear'] ??
                dat['parameter'] ??
                dat['row'] ??
                const [];
          }
          final series = <Map<String, dynamic>>[];
          double? latest;
          String? ts;
          for (final e in list) {
            if (e is Map) {
              final v = e['val'];
              final d = v is num ? v.toDouble() : double.tryParse('${v}');
              final t = e['ts']?.toString();
              if (d != null) {
                latest = d;
                ts = t;
                series.add({'ts': t ?? '', 'val': d});
              }
            }
          }
          if (series.isNotEmpty) {
            return MetricResolutionResult(
              logicalMetric: logicalMetric,
              apiParameter: apiParameter,
              source: 'key_param_year_per_month',
              latestValue: latest,
              pointCount: series.length,
              timestamp: ts,
              series: series,
            );
          }
        }
      } catch (_) {
        // try next candidate
      }
    }
    return const MetricResolutionResult(
      logicalMetric: '',
      apiParameter: null,
      source: 'none',
      latestValue: null,
      pointCount: 0,
      timestamp: null,
      series: [],
    );
  }

  // Main method to fetch devices and collectors for a plant (matching old app)
  Future<Map<String, dynamic>> getDevicesAndCollectors(String plantId) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    // Validate inputs
    if (plantId.isEmpty) {
      print('DeviceRepository: ERROR - Plant ID is empty');
      throw Exception('Plant ID cannot be empty');
    }

    if (token.isEmpty || secret.isEmpty) {
      print(
          'DeviceRepository: ERROR - Authentication missing. Token: $token, Secret: $secret');
      throw Exception('Authentication required. Please log in again.');
    }

    print(
        'DeviceRepository: Fetching devices and collectors for plant $plantId');

    // 1. Fetch all devices for the plant
    final deviceAction =
        '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
    final deviceData = salt + secret + token + deviceAction + postaction;
    final deviceSign = sha1.convert(utf8.encode(deviceData)).toString();
    final deviceUrl =
        'http://api.dessmonitor.com/public/?sign=$deviceSign&salt=$salt&token=$token$deviceAction$postaction';

    print('DeviceRepository: Device URL: $deviceUrl');
    final deviceResponse = await _apiClient.signedPost(deviceUrl);
    final deviceJson = json.decode(deviceResponse.body);
    print('DeviceRepository: Device response: $deviceJson');

    List<Device> devices = [];
    if (deviceJson['err'] == 0 && deviceJson['dat']?['device'] != null) {
      devices = (deviceJson['dat']['device'] as List)
          .map((d) => Device.fromJson(d))
          .toList();
      print('DeviceRepository: Found ${devices.length} devices');
    } else {
      print(
          'DeviceRepository: No devices found or error: ${deviceJson['err']} - ${deviceJson['desc']}');
    }

    // 2. Fetch all collectors for the plant
    final collectorAction =
        '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
    final collectorData = salt + secret + token + collectorAction + postaction;
    final collectorSign = sha1.convert(utf8.encode(collectorData)).toString();
    final collectorUrl =
        'http://api.dessmonitor.com/public/?sign=$collectorSign&salt=$salt&token=$token$collectorAction$postaction';

    print('DeviceRepository: Collector URL: $collectorUrl');
    final collectorResponse = await _apiClient.signedPost(collectorUrl);
    final collectorJson = json.decode(collectorResponse.body);
    print('DeviceRepository: Collector response: $collectorJson');

    List<Map<String, dynamic>> collectors = [];
    if (collectorJson['err'] == 0 &&
        collectorJson['dat']?['collector'] != null) {
      collectors =
          List<Map<String, dynamic>>.from(collectorJson['dat']['collector']);
      print('DeviceRepository: Found ${collectors.length} collectors');
    } else {
      print(
          'DeviceRepository: No collectors found or error: ${collectorJson['err']} - ${collectorJson['desc']}');
    }

    // 3. For each collector, fetch subordinate devices
    Map<String, List<Device>> collectorDevices = {};
    Set<String> subordinateSNs = {};

    for (final collector in collectors) {
      final pn = collector['pn']?.toString() ?? '';
      if (pn.isNotEmpty) {
        final subDevices = await getDevicesForCollector(pn);
        collectorDevices[pn] = subDevices;
        subordinateSNs.addAll(subDevices.map((d) => d.sn));
        print(
            'DeviceRepository: Collector $pn has ${subDevices.length} subordinate devices');
      }
    }

    // 4. Standalone devices = all devices not under any collector
    final standaloneDevices =
        devices.where((d) => !subordinateSNs.contains(d.sn)).toList();
    print(
        'DeviceRepository: Found ${standaloneDevices.length} standalone devices');

    return {
      'standaloneDevices': standaloneDevices,
      'collectors': collectors,
      'collectorDevices': collectorDevices,
      'allDevices': devices,
    };
  }

  // Lightweight paging endpoint (old app style) to fetch multiple columns in one call
  Future<Map<String, dynamic>?> fetchDeviceDataOneDayPaging({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
    int page = 0,
    int pageSize = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const salt = '12345678';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';
    final action =
        '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$validSn&devaddr=$devaddr&devcode=$devcode&date=$date&page=$page&pagesize=$pageSize&i18n=en_US';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    try {
      final response = await _apiClient.signedPost(url);
      final jsonMap = json.decode(response.body);
      return jsonMap;
    } catch (e) {
      print('DeviceRepository: paging fetch failed: $e');
      return null;
    }
  }

  // Extract latest column value by (case-insensitive) title from paging response
  double? extractLatestPagingValue(Map<String, dynamic> jsonMap, String title) {
    try {
      final dat = jsonMap['dat'];
      if (dat == null) return null;
      final titles =
          (dat['title'] as List?)?.map((e) => e['title'] as String?).toList();
      final rows = (dat['row'] as List?);
      if (titles == null || rows == null || rows.isEmpty) return null;
      final idx = titles
          .indexWhere((t) => (t ?? '').toLowerCase() == title.toLowerCase());
      if (idx == -1) return null;
      final last = rows.last as Map<String, dynamic>;
      final field = last['field'] as List?;
      if (field == null || idx >= field.length) return null;
      final raw = field[idx];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  // Fetch subordinate devices for a collector (by PN) - matching old app
  Future<List<Device>> getDevicesForCollector(String collectorPn) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    final action =
        '&action=webQueryDeviceEs&pn=$collectorPn&page=0&pagesize=20';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    print('DeviceRepository: Fetching devices for collector $collectorPn');
    final response = await _apiClient.signedPost(url);
    final jsonData = json.decode(response.body);

    if (jsonData['err'] == 0 && jsonData['dat']?['device'] != null) {
      final devices = (jsonData['dat']['device'] as List)
          .map((d) => Device.fromJson(d))
          .toList();
      print(
          'DeviceRepository: Found ${devices.length} devices for collector $collectorPn');
      return devices;
    }

    print('DeviceRepository: No devices found for collector $collectorPn');
    return [];
  }

  // Fetch devices with specific status and device type (matching old app)
  Future<List<Device>> getDevicesWithFilters(String plantId,
      {String status = '0101', String deviceType = '0101'}) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    String action;
    if (status == '0101' && deviceType == '0101') {
      // All devices
      action = '&action=webQueryDeviceEs&page=0&pagesize=100&plantid=$plantId';
    } else if (status == '0101' &&
        deviceType != '0101' &&
        deviceType != '0110') {
      // Specific device type
      action =
          '&action=webQueryDeviceEs&devtype=$deviceType&page=0&pagesize=100&plantid=$plantId';
    } else if (status == '0101' && deviceType == '0110') {
      // Collectors
      action =
          '&action=webQueryCollectorsEs&page=0&pagesize=100&plantid=$plantId';
    } else if (status != '0101' && deviceType == '0110') {
      // Collectors with status
      action =
          '&action=webQueryCollectorsEs&status=$status&page=0&pagesize=100&plantid=$plantId';
    } else {
      // Devices with status and device type
      action =
          '&action=webQueryDeviceEs&status=$status&page=0&pagesize=100&plantid=$plantId';
    }

    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    print(
        'DeviceRepository: Fetching devices with filters - status: $status, deviceType: $deviceType');
    final response = await _apiClient.signedPost(url);
    final jsonData = json.decode(response.body);

    if (jsonData['err'] == 0) {
      if (jsonData['dat']?['device'] != null) {
        final devices = (jsonData['dat']['device'] as List)
            .map((d) => Device.fromJson(d))
            .toList();
        print('DeviceRepository: Found ${devices.length} devices with filters');
        return devices;
      } else if (jsonData['dat']?['collector'] != null) {
        // Convert collectors to devices for consistency
        final collectors = jsonData['dat']['collector'] as List;
        final devices = collectors.map((c) => Device.fromJson(c)).toList();
        print(
            'DeviceRepository: Found ${devices.length} collectors with filters');
        return devices;
      }
    }

    print('DeviceRepository: No devices found with filters');
    return [];
  }

  // Legacy method for backward compatibility
  Future<List<Device>> getDevices(String plantId) async {
    final result = await getDevicesAndCollectors(plantId);
    return result['allDevices'] ?? [];
  }

  // Add a datalogger (collector) to a plant (legacy endpoint: webManageDeviceEs opt=add_collectors)
  Future<Map<String, dynamic>> addDataLogger(
      String plantId, String pn, String name) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    if (plantId.isEmpty) {
      throw Exception('Plant ID is required');
    }
    if (pn.isEmpty) {
      throw Exception('PN is required');
    }
    if (name.isEmpty) {
      throw Exception('Datalogger name is required');
    }
    if (token.isEmpty || secret.isEmpty) {
      throw Exception('Authentication required. Please log in again.');
    }

    final action =
        '&action=webManageDeviceEs&plantid=$plantId&opt=add_collectors&pn=$pn&name=$name';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final response = await _apiClient.signedPost(url);
    final jsonData = json.decode(response.body);
    return Map<String, dynamic>.from(jsonData);
  }

  // Fetch real-time device data (separate call for detailed info)
  Future<Map<String, dynamic>> getDeviceRealTimeData(
      String pn, String sn, int devcode, int devaddr) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryDeviceCtrlField&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';

    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);

    if (dataJson['err'] == 0 && dataJson['dat'] != null) {
      return dataJson['dat'];
    }

    throw Exception('Failed to get device real-time data: ${dataJson['desc']}');
  }

  // Fetch device daily data
  Future<Map<String, dynamic>> getDeviceDailyData(
      String pn, String sn, int devcode, int devaddr, String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$date&page=0&pagesize=200&i18n=en_US';
    final data = salt + secret + token + action;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action';

    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);

    if (dataJson['err'] == 0 && dataJson['dat'] != null) {
      return dataJson['dat'];
    }

    throw Exception('Failed to get device daily data: ${dataJson['desc']}');
  }

  // Fetch device data for one day (for device detail page)
  Future<DeviceDataOneDayQueryModel?> fetchDeviceDataOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
    int page = 0,
  }) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    // Validate SN parameter - use dummy default if empty
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';
    print(
        'DeviceRepository: Using SN: $validSn (original: "$sn") for fetchDeviceDataOneDay');

    final action =
        '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$validSn&devcode=$devcode&devaddr=$devaddr&date=$date&page=$page&pagesize=200&i18n=en_US';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      final response = await _apiClient.signedPost(url);
      final dataJson = json.decode(response.body);

      if (dataJson['err'] == 0) {
        return DeviceDataOneDayQueryModel.fromJson(dataJson);
      } else {
        print(
            'DeviceRepository: Error fetching device data: ${dataJson['desc']}');
        return null;
      }
    } catch (e) {
      print('DeviceRepository: Exception fetching device data: $e');
      return null;
    }
  }

  // Fetch live device signal/current/voltage/flow data (for device detail page)
  Future<DeviceLiveSignalModel?> fetchDeviceLiveSignal({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
  }) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    // Validate SN parameter - use dummy default if empty
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';
    print('DeviceRepository: Using SN: $validSn (original: "$sn")');

    // Updated to match the old app implementation
    final action =
        '&action=queryDeviceCtrlField&pn=$pn&sn=$validSn&devcode=$devcode&devaddr=$devaddr&i18n=en_US';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    try {
      print('DeviceRepository: Fetching live signal data: $url');
      final response = await _apiClient.signedPost(url);
      print('DeviceRepository: Live signal response: ${response.body}');
      final dataJson = json.decode(response.body);

      if (dataJson['err'] == 0 && dataJson['dat'] != null) {
        final dat = dataJson['dat'];
        print('DeviceRepository: Raw signal data: $dat');

        // Check for supported parameters in field list
        List<String> supportedParameters = [];
        if (dat['field'] != null && dat['field'] is List) {
          for (var field in dat['field']) {
            if (field is Map && field['name'] != null) {
              String fieldName = field['name'].toString();
              String fieldId = field['id']?.toString() ?? '';
              print('DeviceRepository: Found field: $fieldName (id: $fieldId)');
              supportedParameters.add(fieldName);
            }
          }
        }

        print('DeviceRepository: Supported fields: $supportedParameters');

        // Additional field names specific to energy storage devices (2400-2499)
        List<String> batteryFields = [
          'batteryLevel',
          'soc',
          'SOC',
          'batSoc',
          'Soc',
          'bat_soc'
        ];
        List<String> inputVoltageFields = [
          'inputVoltage',
          'vin',
          'vinsP',
          'Vin',
          'PV_VOLTAGE',
          'pv_voltage'
        ];
        List<String> inputCurrentFields = [
          'inputCurrent',
          'iin',
          'iinsP',
          'Iin',
          'PV_CURRENT',
          'pv_current'
        ];
        List<String> outputVoltageFields = [
          'outputVoltage',
          'vout',
          'voutP',
          'Vout',
          'OUTPUT_VOLTAGE',
          'output_voltage',
          'AC_VOLTAGE'
        ];
        List<String> outputCurrentFields = [
          'outputCurrent',
          'iout',
          'ioutP',
          'Iout',
          'OUTPUT_CURRENT',
          'output_current',
          'AC_CURRENT'
        ];
        List<String> inputPowerFields = [
          'inputPower',
          'pin',
          'pinP',
          'Pin',
          'PV_POWER',
          'pv_power',
          'PV_OUTPUT_POWER'
        ];
        List<String> outputPowerFields = [
          'outputPower',
          'pout',
          'poutP',
          'Pout',
          'OUTPUT_POWER',
          'output_power',
          'LOAD_POWER',
          'LOAD_ACTIVE_POWER',
          'ac_output_active_power',
          'AC_OUTPUT_ACTIVE_POWER',
          'ac_output_power',
          'AC_OUTPUT_POWER',
        ];
        List<String> signalFields = ['signal', 'signalStrength', 'Signal'];

        // Parse different field names for compatibility
        double? inputVoltage = _parseDoubleFromMap(dat, inputVoltageFields);
        double? inputCurrent = _parseDoubleFromMap(dat, inputCurrentFields);
        double? outputVoltage = _parseDoubleFromMap(dat, outputVoltageFields);
        double? outputCurrent = _parseDoubleFromMap(dat, outputCurrentFields);
        double? inputPower = _parseDoubleFromMap(dat, inputPowerFields);
        double? outputPower = _parseDoubleFromMap(dat, outputPowerFields);
        double? signalStrength = _parseDoubleFromMap(dat, signalFields);
        double? batteryLevel = _parseDoubleFromMap(dat, batteryFields);

        // If battery level is not found directly, try to extract it from JSON structure
        if (batteryLevel == null && dat.containsKey('bat')) {
          if (dat['bat'] is Map && dat['bat'].containsKey('soc')) {
            batteryLevel = _parseDouble(dat['bat']['soc']);
          }
        }

        // Extract battery level from field list if available (improved: numeric scan of items array too)
        if (batteryLevel == null) {
          if (dat['field'] != null && dat['field'] is List) {
            for (var field in dat['field']) {
              if (field is! Map) continue;
              final name = field['name']?.toString().toLowerCase() ?? '';
              if (name.contains('battery') || name.contains('soc')) {
                // Direct val
                if (field['val'] != null) {
                  final v = _parseDouble(field['val']);
                  if (v > 0) {
                    batteryLevel = v;
                    print(
                        'DeviceRepository: Found battery level (val): $batteryLevel');
                    break;
                  }
                }
                // Some responses embed an 'item' list with key/val pairs; pick item whose key suggests current state
                if (batteryLevel == null && field['item'] is List) {
                  for (var opt in field['item']) {
                    if (opt is Map && opt['val'] != null) {
                      final v = _parseDouble(opt['val']);
                      // Heuristic: SOC will be within 0-100
                      if (v >= 0 && v <= 100) {
                        batteryLevel = v;
                        print(
                            'DeviceRepository: Found battery level (item): $batteryLevel');
                        break;
                      }
                    }
                  }
                }
              }
              if (batteryLevel != null) break;
            }
          }
        }

        // Set default battery level if still null
        if (batteryLevel == null) {
          print('DeviceRepository: Battery level is null, using default value');
          batteryLevel = 0.0;
        }

        // Normalize batteryLevel: if between 0-1 assume fraction -> percentage
        if (batteryLevel > 0 && batteryLevel <= 1) {
          batteryLevel = batteryLevel * 100.0;
        }

        // Derive outputPower if still null and voltage/current available
        if (outputPower == null &&
            outputVoltage != null &&
            outputCurrent != null) {
          final derived = outputVoltage * outputCurrent;
          if (derived > 0) {
            outputPower = derived;
            print(
                'DeviceRepository: Derived outputPower from V*I = $outputPower W');
          }
        }

        print('DeviceRepository: Parsed signal data:');
        print('- Input Voltage: $inputVoltage');
        print('- Input Current: $inputCurrent');
        print('- Output Voltage: $outputVoltage');
        print('- Output Current: $outputCurrent');
        print('- Input Power: $inputPower');
        print('- Output Power: $outputPower');
        print('- Signal Strength: $signalStrength');
        print('- Battery Level: $batteryLevel');

        return DeviceLiveSignalModel(
          inputVoltage: inputVoltage,
          inputCurrent: inputCurrent,
          outputVoltage: outputVoltage,
          outputCurrent: outputCurrent,
          inputPower: inputPower,
          outputPower: outputPower,
          signalStrength: signalStrength,
          batteryLevel: batteryLevel,
          timestamp: DateTime.now(),
          status: dat['status'] as int? ?? 0,
          desc: dat['desc'] as String? ?? '',
        );
      } else {
        print(
            'DeviceRepository: Error fetching live signal: ${dataJson['desc']}');

        return null;
      }
    } catch (e) {
      print('DeviceRepository: Exception fetching live signal: $e');
      return null;
    }
  }

  // --- Energy Flow (webQueryDeviceEnergyFlowEs) --- //
  Future<DeviceEnergyFlowModel?> fetchDeviceEnergyFlow({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
  }) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';
    final action =
        '&action=webQueryDeviceEnergyFlowEs&devcode=$devcode&pn=$pn&devaddr=$devaddr&sn=$validSn';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    try {
      final response = await _apiClient.signedPost(url);
      final j = json.decode(response.body);
      if (j['err'] != 0) {
        print('DeviceRepository: Energy flow err=${j['desc']}');
        return null;
      }
      final dat = j['dat'] as Map<String, dynamic>?;
      if (dat == null) return null;
      final model = DeviceEnergyFlowModel.fromJson(dat);
      // Debug log of parsed energy flow entries for diagnostics
      void logList(String label, List<DeviceEnergyFlowItem> items) {
        for (final i in items) {
          print(
              'EnergyFlow [$label] par=${i.par} val=${i.value} unit=${i.unit} status=${i.status}');
        }
      }

      logList('bt_status', model.btStatus);
      logList('pv_status', model.pvStatus);
      logList('gd_status', model.gdStatus);
      logList('bc_status', model.bcStatus);
      logList('ol_status', model.olStatus);
      print(
          'EnergyFlow derived -> pvW=${model.pvPower} loadW=${model.loadPower} gridW=${model.gridPower} batSoc=${model.batterySoc} batPower=${model.batteryPower}');
      return model;
    } catch (e) {
      print('DeviceRepository: Energy flow exception: $e');
      return null;
    }
  }

  /// Extract latest realtime-like values from a paging response (queryDeviceDataOneDayPaging) for fallback.
  /// Returns values in a normalized map with keys: pvPowerW, loadPowerW, batterySocPct, gridVoltage, gridPowerW (nullable).
  Map<String, dynamic>? extractRealtimeFromPaging(
      Map<String, dynamic> pagingJson) {
    try {
      final dat = pagingJson['dat'];
      if (dat == null) return null;
      final titles = (dat['title'] as List?)
              ?.map((e) => (e as Map)['title']?.toString() ?? '')
              .toList() ??
          [];
      final rows = (dat['row'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (titles.isEmpty || rows.isEmpty) return null;
      // Choose the first row with realtime=true if present, else last row.
      Map<String, dynamic> latest = rows
          .firstWhere((r) => r['realtime'] == true, orElse: () => rows.last);
      final field = latest['field'];
      if (field is! List) return null;
      int idxOf(String contains) =>
          titles.indexWhere((t) => t.toLowerCase() == contains.toLowerCase());
      // Battery SOC
      final socIdx = idxOf('Battery Capacity');
      final pv1Idx = idxOf('PV1 Charging Power');
      final pv2Idx = idxOf('PV2 Charging power');
      // Some devices may label without case consistency; fallback partial match.
      int idxLike(String pattern) {
        final pLower = pattern.toLowerCase();
        final i = titles.indexWhere((t) => t.toLowerCase().contains(pLower));
        return i;
      }

      final loadIdx = idxOf('AC Output Active Power') != -1
          ? idxOf('AC Output Active Power')
          : idxLike('Output Active Power');
      final gridVoltIdx = idxOf('Grid Voltage') != -1
          ? idxOf('Grid Voltage')
          : idxLike('Grid Voltage');
      double parseVal(int i) {
        if (i < 0 || i >= field.length) return 0;
        final raw = field[i];
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString()) ?? 0;
      }

      final pv1 = parseVal(pv1Idx);
      final pv2 = parseVal(pv2Idx);
      final pvSum = pv1 + pv2; // Already W
      final load = parseVal(loadIdx);
      final soc = parseVal(socIdx);
      final gridV = parseVal(gridVoltIdx);
      return {
        'pvPowerW': pvSum > 0 ? pvSum : null,
        'loadPowerW': load > 0 ? load : null,
        'batterySocPct': soc >= 0 ? soc : null,
        'gridVoltage': gridV > 0 ? gridV : null,
        // grid power not directly available in paging set provided
      };
    } catch (e) {
      print('DeviceRepository: extractRealtimeFromPaging failed: $e');
      return null;
    }
  }

  /// Convenience: attempt to obtain current PV power (W) for a list of devices prioritizing energy flow, then paging, then key parameter resolution.
  Future<double> aggregateCurrentPvPowerWatts(List<Device> devices) async {
    double sum = 0;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    for (final d in devices) {
      try {
        final devcode = d.devcode;
        final devaddr = d.devaddr;
        final sn = d.sn;
        final pn = d.pn;
        // 1. Energy flow
        final flow = await fetchDeviceEnergyFlow(
            sn: sn, pn: pn, devcode: devcode, devaddr: devaddr);
        double? pvW = flow?.pvPower; // already normalized to W
        // 2. Paging fallback
        if (pvW == null || pvW <= 0) {
          final paging = await fetchDeviceDataOneDayPaging(
              sn: sn,
              pn: pn,
              devcode: devcode,
              devaddr: devaddr,
              date: date,
              page: 0,
              pageSize: 50);
          final realtime =
              paging != null ? extractRealtimeFromPaging(paging) : null;
          pvW = realtime?['pvPowerW'] as double?;
        }
        // 3. Key parameter / metric resolution fallback
        if (pvW == null || pvW <= 0) {
          final res = await resolveMetricOneDay(
              logicalMetric: 'PV_OUTPUT_POWER',
              sn: sn,
              pn: pn,
              devcode: devcode,
              devaddr: devaddr,
              date: date);
          if (res.latestValue != null && res.latestValue! > 0)
            pvW = res.latestValue; // latestValue assumed W
        }
        if (pvW != null && pvW > 0) sum += pvW;
      } catch (e) {
        // ignore per-device errors
      }
    }
    return sum;
  }

  // Helper method to parse double values from various field names
  double? _parseDoubleFromMap(
      Map<String, dynamic> map, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (map.containsKey(key) && map[key] != null) {
        return _parseDouble(map[key]);
      }
    }
    return null;
  }

  // Fetch key parameter data for one day (e.g., PV_OUTPUT_POWER, current, voltage)
  Future<dynamic> fetchDeviceKeyParameterOneDay({
    required String sn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String parameter,
    required String date,
  }) async {
    // Capability check first
    if (!deviceSupportsParameter(devcode, parameter)) {
      return {
        'err': 99,
        'desc': 'UNSUPPORTED_PARAMETER: $parameter for devcode $devcode'
      };
    }
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

    // Validate SN parameter - use dummy default if empty
    final validSn = sn.isNotEmpty ? sn : 'DEFAULT_SN';
    print(
        'DeviceRepository: Using SN: $validSn (original: "$sn") for parameter $parameter');

    final cacheKey = '$devcode:$devaddr:$parameter';
    // Negative cache TTL (avoid hammering) 10 minutes
    final now = DateTime.now();
    if (_parameterNegativeCache.containsKey(cacheKey)) {
      final ts = _parameterNegativeCache[cacheKey]!;
      if (now.difference(ts).inMinutes < 10) {
        print(
            'DeviceRepository: Skipping $parameter for $devcode (negative cache)');
        return {
          'err': 98,
          'desc': 'CACHED_FAILURE: $parameter unresolved recently'
        };
      } else {
        _parameterNegativeCache.remove(cacheKey);
      }
    }

    // If we already resolved this logical parameter, try cached first
    if (_parameterResolutionCache.containsKey(cacheKey)) {
      final resolved = _parameterResolutionCache[cacheKey]!;
      print(
          'DeviceRepository: Using cached API parameter $resolved for logical $parameter ($cacheKey)');
      final res = await _attemptParameterFetch(
          apiParameter: resolved,
          validSn: validSn,
          pn: pn,
          devcode: devcode,
          devaddr: devaddr,
          date: date,
          salt: salt,
          secret: secret,
          token: token,
          postaction: postaction);
      // If cache failed (e.g. device reboot changed field), fall through to full resolution
      if (res != null) return res;
      print(
          'DeviceRepository: Cached parameter $resolved failed, re-resolving...');
      _parameterResolutionCache.remove(cacheKey);
    }

    // Try multiple candidate parameter names until one succeeds
    final candidates = _parameterCandidates(parameter, devcode);
    print(
        'DeviceRepository: Candidates for $parameter on $devcode: $candidates');

    Map<String, dynamic>? lastError;
    for (final apiParameter in candidates) {
      final res = await _attemptParameterFetch(
          apiParameter: apiParameter,
          validSn: validSn,
          pn: pn,
          devcode: devcode,
          devaddr: devaddr,
          date: date,
          salt: salt,
          secret: secret,
          token: token,
          postaction: postaction);
      if (res != null) {
        // Cache success and return
        _parameterResolutionCache[cacheKey] = apiParameter;
        return res;
      }
    }

    // Mark negative cache if all fail
    _parameterNegativeCache[cacheKey] = DateTime.now();

    // As a final fallback, try live signal mapping for a single value
    try {
      final liveSignal = await fetchDeviceLiveSignal(
        sn: sn,
        pn: pn,
        devcode: devcode,
        devaddr: devaddr,
      );
      if (liveSignal != null) {
        double? val;
        switch (parameter) {
          case 'PV_OUTPUT_POWER':
            val = liveSignal.inputPower;
            break;
          case 'LOAD_POWER':
            val = liveSignal.outputPower;
            break;
          case 'BATTERY_SOC':
            val = liveSignal.batteryLevel;
            break;
          case 'AC2_OUTPUT_VOLTAGE':
            val = liveSignal.outputVoltage;
            break;
          case 'AC2_OUTPUT_CURRENT':
            val = liveSignal.outputCurrent;
            break;
          case 'PV_INPUT_VOLTAGE':
            val = liveSignal.inputVoltage;
            break;
          case 'PV_INPUT_CURRENT':
            val = liveSignal.inputCurrent;
            break;
          default:
            val = null;
        }
        if (val != null) {
          return {
            'err': 0,
            'desc': 'SUCCESS',
            'source': 'live_signal',
            'value': val,
            'dat': {
              'parameter': [
                {'ts': DateTime.now().toIso8601String(), 'val': val}
              ]
            }
          };
        }
      }
    } catch (e) {
      print('DeviceRepository: Live signal fallback failed: $e');
    }

    return lastError ?? {'err': -1, 'desc': 'No valid parameter found'};
  }

  // Helper method to map our parameter names to the ones expected by the API
  List<String> _parameterCandidates(String parameter, int devcode) {
    // Base candidates by parameter
    List<String> base;
    switch (parameter) {
      case 'PV_OUTPUT_POWER':
        base = [
          'PV_OUTPUT_POWER',
          'PV_POWER',
          'INPUT_POWER',
          'PIN',
          'PV_POWER_P'
        ];
        break;
      case 'LOAD_POWER':
        base = ['LOAD_POWER', 'LOAD_ACTIVE_POWER', 'PLOAD'];
        break;
      case 'GRID_POWER':
        base = [
          'GRID_POWER',
          'GRID_ACTIVE_POWER',
          'PGRID',
          'IMPORT_POWER',
          'EXPORT_POWER',
          'AC_INPUT_POWER',
          'UTILITY_POWER'
        ];
        break;
      case 'AC2_OUTPUT_VOLTAGE':
        base = [
          'AC2_OUTPUT_VOLTAGE',
          'AC_OUTPUT_VOLTAGE',
          'OUTPUT_VOLTAGE',
          'AC_VOLTAGE',
          'VOUT',
          'GRID_VOLTAGE'
        ];
        break;
      case 'AC2_OUTPUT_CURRENT':
        base = [
          'AC2_OUTPUT_CURRENT',
          'AC_OUTPUT_CURRENT',
          'OUTPUT_CURRENT',
          'AC_CURRENT',
          'IOUT'
        ];
        break;
      case 'PV_INPUT_VOLTAGE':
        base = [
          'PV_INPUT_VOLTAGE',
          'PV_VOLTAGE',
          'INPUT_VOLTAGE',
          'VIN',
          'PV1_VOLTAGE',
          'PV2_VOLTAGE',
          'PV_VOLT'
        ];
        break;
      case 'PV_INPUT_CURRENT':
        base = [
          'PV_INPUT_CURRENT',
          'PV_CURRENT',
          'INPUT_CURRENT',
          'IIN',
          'PV1_CURRENT',
          'PV2_CURRENT',
          'PV_CUR'
        ];
        break;
      case 'GRID_FREQUENCY':
        base = [
          'GRID_FREQUENCY',
          'AC_FREQUENCY',
          'FREQUENCY',
          'FREQ',
          'OUTPUT_FREQUENCY'
        ];
        break;
      case 'BATTERY_SOC':
        base = [
          'BATTERY_SOC',
          'SOC',
          'BAT_SOC',
          'battery_soc',
          'bat_soc',
          'BMS_SOC',
          'BATT_SOC',
          'SOC_PCT',
          'BATTERY_LEVEL',
          'BAT_LEVEL',
          'SOC_PERCENT',
          'SOC_PERCENTAGE'
        ];
        break;
      default:
        base = [parameter];
    }

    // Device-type tweaks
    final isStorage = devcode >= 2400 && devcode < 2500;
    // For very specific model (e.g., 2451) we prioritize OUTPUT_* early based on observed API behaviour
    final isStorage2451 = devcode == 2451;
    if (isStorage) {
      // Storage devices often use OUTPUT_* aliases; append as fallbacks
      if (parameter == 'PV_OUTPUT_POWER' && !base.contains('OUTPUT_POWER')) {
        base = [...base, 'OUTPUT_POWER'];
      }
      if (parameter == 'LOAD_POWER' && !base.contains('OUTPUT_POWER')) {
        // For devices like devcode 2451, OUTPUT_POWER often represents load/active power
        base = [...base, 'OUTPUT_POWER'];
      }
      if (parameter == 'GRID_POWER' && !base.contains('OUTPUT_POWER')) {
        base = [...base, 'OUTPUT_POWER'];
      }
      if (!base.contains('OUTPUT_VOLTAGE') &&
          parameter == 'AC2_OUTPUT_VOLTAGE') {
        base = [...base, 'OUTPUT_VOLTAGE'];
      }
      if (!base.contains('OUTPUT_CURRENT') &&
          parameter == 'AC2_OUTPUT_CURRENT') {
        base = [...base, 'OUTPUT_CURRENT'];
      }
      // Some storage models expose PV metrics as generic INPUT_* names
      if (parameter == 'PV_INPUT_VOLTAGE' && !base.contains('INPUT_VOLTAGE')) {
        base = [...base, 'INPUT_VOLTAGE'];
      }
      if (parameter == 'PV_INPUT_CURRENT' && !base.contains('INPUT_CURRENT')) {
        base = [...base, 'INPUT_CURRENT'];
      }
    }

    // Reorder for 2451: OUTPUT_POWER first for power metrics, SOC early for battery
    if (isStorage2451) {
      if (parameter == 'PV_OUTPUT_POWER') {
        // For PV output power we still sometimes need OUTPUT_POWER early
        base.removeWhere((e) => e == 'OUTPUT_POWER');
        base = ['OUTPUT_POWER', ...base];
      }
      // For LOAD_POWER and GRID_POWER keep specific tokens first; OUTPUT_POWER stays as fallback already appended above.
      if (parameter == 'BATTERY_SOC') {
        // Ensure SOC alias leads
        base.removeWhere((e) => e.toUpperCase() == 'SOC');
        base = ['SOC', ...base];
      }
    }

    // Inverters often use OUTPUT_* for PV/Load too; add as late fallbacks
    final isInverter = devcode >= 500 && devcode < 1000;
    if (isInverter) {
      if (parameter == 'PV_OUTPUT_POWER' && !base.contains('OUTPUT_POWER')) {
        base = [...base, 'OUTPUT_POWER'];
      }
      if (parameter == 'LOAD_POWER' && !base.contains('OUTPUT_POWER')) {
        base = [...base, 'OUTPUT_POWER'];
      }
    }

    // Ensure uniqueness while preserving order
    final seen = <String>{};
    final unique = <String>[];
    for (final p in base) {
      if (p.isEmpty) continue;
      if (seen.add(p)) unique.add(p);
    }
    return unique;
  }

  // Helper method to parse double values from API response
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool deviceSupportsParameter(int devcode, String parameter) {
    final caps = _deviceCapabilities[devcode];
    if (caps == null) return true; // unknown devices: attempt anyway
    if (caps.isEmpty) return false; // explicitly unsupported device type
    return caps.contains(parameter);
  }

  _PagingExtractResult? _extractFromPagingForLogical(
      Map<String, dynamic> paging, String logical) {
    final columnCandidates = <String>[];
    // We adapt candidates to real titles observed in paging JSON the user supplied.
    // Titles sample include (subset):
    // 'PV2 Input voltage','Grid Voltage','PV2 Charging power','PV1 Input Voltage','PV1 Charging Power',
    // 'Battery Capacity','AC1 Output Voltage','AC Output Active Power','Solar Feed To Grid Power', etc.
    switch (logical) {
      case 'PV_OUTPUT_POWER':
        // We will SPECIAL-CASE below to sum PV1 + PV2 charging power if present; still include generic fallbacks.
        columnCandidates.addAll([
          'PV1 Charging Power',
          'PV2 Charging power',
          'PV Power',
          'PV Output Power',
          'Input Power',
          'Output Power'
        ]);
        break;
      case 'LOAD_POWER':
        columnCandidates.addAll([
          'AC Output Active Power', // preferred real active load power (W)
          'Load Power',
          'AC1 Output Apparent Power', // may be VA, fallback only
          'Output Power'
        ]);
        break;
      case 'GRID_POWER':
        columnCandidates.addAll([
          'Solar Feed To Grid Power', // observed export / feed-in power
          'Grid Power',
          'AC Input Power',
          'Utility Power',
          'Output Power'
        ]);
        break;
      case 'BATTERY_SOC':
        columnCandidates.addAll([
          'Battery Capacity', // actual title in paging sample
          'Battery SOC',
          'SOC'
        ]);
        break;
      case 'AC2_OUTPUT_VOLTAGE':
        columnCandidates.addAll([
          'AC1 Output Voltage', // actual title (voltage)
          'Output Voltage',
          'AC Output Rating Voltage',
          'AC Voltage'
        ]);
        break;
      case 'AC2_OUTPUT_CURRENT':
        columnCandidates.addAll([
          'AC Output Rating Current', // rated current (A) if realtime current absent
          'Output Current',
          'AC Current',
          'AC1 Output Apparent Power' // can derive I = P/(V) when only apparent power given
        ]);
        break;
      case 'PV_INPUT_VOLTAGE':
        columnCandidates.addAll([
          'PV1 Input Voltage',
          'PV2 Input voltage',
          'PV Voltage',
          'Input Voltage'
        ]);
        break;
      case 'PV_INPUT_CURRENT':
        columnCandidates.addAll([
          'PV1 Charging Power', // used to derive current with voltage
          'PV2 Charging power',
          'PV Current',
          'Input Current'
        ]);
        break;
      case 'GRID_FREQUENCY':
        columnCandidates
            .addAll(['Grid Frequency', 'AC1 Output Frequency', 'Frequency']);
        break;
      default:
        columnCandidates.add(logical);
    }
    final dat = paging['dat'];
    if (dat == null) return null;
    final titles = (dat['title'] as List?)
            ?.map((e) => (e as Map)['title']?.toString() ?? '')
            .toList() ??
        [];
    final rows = (dat['row'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (titles.isEmpty || rows.isEmpty) return null;
    // Helper to find column index (case-insensitive exact match)
    int? findIdx(String cand) {
      final idx = titles.indexWhere(
          (t) => t.toLowerCase().trim() == cand.toLowerCase().trim());
      return idx == -1 ? null : idx;
    }

    // Special handling for PV_OUTPUT_POWER: sum PV1 + PV2 charging power if available.
    if (logical == 'PV_OUTPUT_POWER') {
      final pv1Idx = findIdx('PV1 Charging Power');
      final pv2Idx = findIdx('PV2 Charging power');
      if (pv1Idx != null || pv2Idx != null) {
        double? latestVal;
        String? ts;
        for (final r in rows) {
          final field = r['field'];
          if (field is List) {
            double sum = 0;
            bool any = false;
            if (pv1Idx != null && pv1Idx < field.length) {
              final raw = field[pv1Idx];
              final v =
                  raw is num ? raw.toDouble() : double.tryParse(raw.toString());
              if (v != null) {
                sum += v;
                any = true;
              }
            }
            if (pv2Idx != null && pv2Idx < field.length) {
              final raw = field[pv2Idx];
              final v =
                  raw is num ? raw.toDouble() : double.tryParse(raw.toString());
              if (v != null) {
                sum += v;
                any = true;
              }
            }
            if (any) {
              latestVal =
                  sum; // last non-null sum wins (rows appear chronological older->newer)
              ts = r['ts']?.toString();
            }
          }
        }
        if (latestVal != null) {
          return _PagingExtractResult(latestVal, rows.length, ts,
              ['PV1 Charging Power', 'PV2 Charging power']);
        }
      }
    }

    // GRID_POWER special: look for feed-in / grid import/export columns.
    if (logical == 'GRID_POWER') {
      final feedIdx = findIdx('Solar Feed To Grid Power');
      if (feedIdx != null) {
        double? latestVal;
        String? ts;
        for (final r in rows) {
          final field = r['field'];
          if (field is List && feedIdx < field.length) {
            final raw = field[feedIdx];
            final v =
                raw is num ? raw.toDouble() : double.tryParse(raw.toString());
            if (v != null) {
              latestVal = v;
              ts = r['ts']?.toString();
            }
          }
        }
        if (latestVal != null) {
          return _PagingExtractResult(
              latestVal, rows.length, ts, ['Solar Feed To Grid Power']);
        }
      }
    }

    // BATTERY_SOC special: Battery Capacity column.
    if (logical == 'BATTERY_SOC') {
      final socIdx = findIdx('Battery Capacity');
      if (socIdx != null) {
        double? latestVal;
        String? ts;
        for (final r in rows) {
          final field = r['field'];
          if (field is List && socIdx < field.length) {
            final raw = field[socIdx];
            final v =
                raw is num ? raw.toDouble() : double.tryParse(raw.toString());
            if (v != null) {
              latestVal = v;
              ts = r['ts']?.toString();
            }
          }
        }
        if (latestVal != null) {
          return _PagingExtractResult(
              latestVal, rows.length, ts, ['Battery Capacity']);
        }
      }
    }

    // AC2_OUTPUT_VOLTAGE special mapping to AC1 Output Voltage.
    if (logical == 'AC2_OUTPUT_VOLTAGE') {
      final vIdx =
          findIdx('AC1 Output Voltage') ?? findIdx('AC Output Rating Voltage');
      if (vIdx != null) {
        double? latestVal;
        String? ts;
        for (final r in rows) {
          final field = r['field'];
          if (field is List && vIdx < field.length) {
            final raw = field[vIdx];
            final v =
                raw is num ? raw.toDouble() : double.tryParse(raw.toString());
            if (v != null) {
              latestVal = v;
              ts = r['ts']?.toString();
            }
          }
        }
        if (latestVal != null) {
          return _PagingExtractResult(
              latestVal, rows.length, ts, ['AC1 Output Voltage']);
        }
      }
    }

    // AC2_OUTPUT_CURRENT: direct column or derive from P/V when possible.
    if (logical == 'AC2_OUTPUT_CURRENT') {
      final iIdx = findIdx('AC Output Rating Current');
      final pIdx = findIdx('AC Output Active Power');
      final vIdx = findIdx('AC1 Output Voltage');
      double? latestVal;
      String? ts;
      for (final r in rows) {
        final field = r['field'];
        if (field is List) {
          double? cur;
          if (iIdx != null && iIdx < field.length) {
            final raw = field[iIdx];
            cur = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
          } else if (pIdx != null &&
              vIdx != null &&
              pIdx < field.length &&
              vIdx < field.length) {
            final pRaw = field[pIdx];
            final vRaw = field[vIdx];
            final p = pRaw is num
                ? pRaw.toDouble()
                : double.tryParse(pRaw.toString());
            final v = vRaw is num
                ? vRaw.toDouble()
                : double.tryParse(vRaw.toString());
            if (p != null && v != null && v > 0) {
              cur = p / v; // approximate active current
            }
          }
          if (cur != null) {
            latestVal = cur;
            ts = r['ts']?.toString();
          }
        }
      }
      if (latestVal != null) {
        return _PagingExtractResult(latestVal, rows.length, ts, [
          'AC Output Rating Current',
          'AC Output Active Power',
          'AC1 Output Voltage'
        ]);
      }
    }

    // PV_INPUT_VOLTAGE: prefer PV1 then PV2; if both capture latest PV1.
    if (logical == 'PV_INPUT_VOLTAGE') {
      final pv1Idx = findIdx('PV1 Input Voltage');
      final pv2Idx = findIdx('PV2 Input voltage');
      double? latestVal;
      String? ts;
      for (final r in rows) {
        final field = r['field'];
        if (field is List) {
          int? useIdx = pv1Idx ?? pv2Idx; // prefer pv1
          if (useIdx != null && useIdx < field.length) {
            final raw = field[useIdx];
            final v =
                raw is num ? raw.toDouble() : double.tryParse(raw.toString());
            if (v != null) {
              latestVal = v;
              ts = r['ts']?.toString();
            }
          }
        }
      }
      if (latestVal != null) {
        return _PagingExtractResult(latestVal, rows.length, ts,
            ['PV1 Input Voltage', 'PV2 Input voltage']);
      }
    }

    // PV_INPUT_CURRENT: derive from power/voltage if no direct column.
    if (logical == 'PV_INPUT_CURRENT') {
      final pv1VoltIdx = findIdx('PV1 Input Voltage');
      final pv2VoltIdx = findIdx('PV2 Input voltage');
      final pv1PowIdx = findIdx('PV1 Charging Power');
      final pv2PowIdx = findIdx('PV2 Charging power');
      double? latestVal;
      String? ts;
      for (final r in rows) {
        final field = r['field'];
        if (field is List) {
          double totalCurrent = 0;
          bool any = false;
          if (pv1VoltIdx != null &&
              pv1PowIdx != null &&
              pv1VoltIdx < field.length &&
              pv1PowIdx < field.length) {
            final vRaw = field[pv1VoltIdx];
            final pRaw = field[pv1PowIdx];
            final v = vRaw is num
                ? vRaw.toDouble()
                : double.tryParse(vRaw.toString());
            final p = pRaw is num
                ? pRaw.toDouble()
                : double.tryParse(pRaw.toString());
            if (v != null && v > 0 && p != null) {
              totalCurrent += p / v;
              any = true;
            }
          }
          if (pv2VoltIdx != null &&
              pv2PowIdx != null &&
              pv2VoltIdx < field.length &&
              pv2PowIdx < field.length) {
            final vRaw = field[pv2VoltIdx];
            final pRaw = field[pv2PowIdx];
            final v = vRaw is num
                ? vRaw.toDouble()
                : double.tryParse(vRaw.toString());
            final p = pRaw is num
                ? pRaw.toDouble()
                : double.tryParse(pRaw.toString());
            if (v != null && v > 0 && p != null) {
              totalCurrent += p / v;
              any = true;
            }
          }
          if (any) {
            latestVal = totalCurrent;
            ts = r['ts']?.toString();
          }
        }
      }
      if (latestVal != null) {
        return _PagingExtractResult(latestVal, rows.length, ts, [
          'PV1 Charging Power',
          'PV1 Input Voltage',
          'PV2 Charging power',
          'PV2 Input voltage'
        ]);
      }
    }

    // Generic fallback: first matching candidate column exact name.
    int? colIdx;
    for (final cand in columnCandidates) {
      final idx = findIdx(cand);
      if (idx != null) {
        colIdx = idx;
        break;
      }
    }
    if (colIdx == null) return null;
    double? latestVal;
    String? ts;
    for (final r in rows) {
      final field = r['field'];
      if (field is List && colIdx < field.length) {
        final raw = field[colIdx];
        final v = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
        if (v != null) {
          latestVal = v;
          ts = r['ts']?.toString();
        }
      }
    }
    if (latestVal == null) return null;
    return _PagingExtractResult(latestVal, rows.length, ts, columnCandidates);
  }

  Future<Map<String, dynamic>?> _attemptParameterFetch({
    required String apiParameter,
    required String validSn,
    required String pn,
    required int devcode,
    required int devaddr,
    required String date,
    required String salt,
    required String secret,
    required String token,
    required String postaction,
  }) async {
    final action =
        '&action=queryDeviceKeyParameterOneDay&pn=$pn&sn=$validSn&devcode=$devcode&devaddr=$devaddr&parameter=$apiParameter&date=$date&i18n=en_US';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';
    try {
      print('DeviceRepository: Try parameter "$apiParameter" -> $url');
      final response = await _apiClient.signedPost(url);
      final dataJson = json.decode(response.body);
      if (dataJson['err'] == 0) {
        // Accept both legacy 'row' format and new 'parameter' array format
        final rows = dataJson['dat']?['row'];
        final params = dataJson['dat']?['parameter'];
        final hasRows = rows is List && rows.isNotEmpty;
        final hasParams = params is List && params.isNotEmpty;
        if (hasRows || hasParams) {
          print(
              'DeviceRepository: Success with parameter $apiParameter (format: '
              '${hasParams ? 'parameter[]' : 'row[]'})');
          return dataJson;
        }
      }
      final desc = dataJson['desc']?.toString() ?? '';
      final extra =
          (dataJson['err'] == 0) ? ' (empty dat: row/parameter missing)' : '';
      print('DeviceRepository: Failed with $apiParameter -> $desc$extra');
      return null;
    } catch (e) {
      print('DeviceRepository: Exception with $apiParameter -> $e');
      return null;
    }
  }
}
