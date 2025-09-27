import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/energy/energy_data_model.dart';
import 'package:crown_micro_solar/presentation/models/energy/profit_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnergyRepository {
  final ApiClient _apiClient;

  EnergyRepository(this._apiClient);

  Future<EnergySummary> getDailyEnergy(String plantId, String date) async {
    // Legacy DESS endpoint that returns daily energy (kWh) for a day range
    // Use sdate=edate=date to get a single-day result
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryPlantEnergyByDay&plantid=$plantId&sdate=$date&edate=$date';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    final baseDate = DateTime.tryParse(date) ?? DateTime.now();
    double totalKwh = 0.0;
    final timeline = <EnergyData>[];
    if (dataJson['dat'] != null) {
      final dat = dataJson['dat'];
      // Common shapes: energy/detail OR table (title/row) OR perday/parameter
      List items = (dat['energy'] as List?) ?? (dat['detail'] as List?) ?? [];
      if (items.isEmpty) {
        // Table-shape with title/row
        final rows = dat['row'] as List?;
        final titles = dat['title'] as List?;
        if (rows != null && rows.isNotEmpty) {
          int firstNumericIdx = 0;
          if (titles != null && titles.isNotEmpty) {
            final idxEnergy = titles.indexWhere((t) {
              try {
                final title =
                    (t is Map ? t['title'] : t)?.toString().toLowerCase();
                return title != null &&
                    (title.contains('energy') ||
                        title.contains('generation') ||
                        title.contains('kwh'));
              } catch (_) {
                return false;
              }
            });
            if (idxEnergy != -1) firstNumericIdx = idxEnergy;
          }
          for (final r in rows) {
            try {
              final timeStr = (r is Map ? r['time'] : null)?.toString();
              final fields = (r is Map ? r['field'] : null) as List?;
              if (fields == null || fields.isEmpty) continue;
              final raw = fields.length > firstNumericIdx
                  ? fields[firstNumericIdx]
                  : fields.first;
              final val = raw is num
                  ? raw.toDouble()
                  : double.tryParse(raw.toString()) ?? 0.0;
              totalKwh += val;
              DateTime ts;
              if (timeStr != null && timeStr.isNotEmpty) {
                // Expect 'YYYY-MM-DD' or similar
                ts = DateTime.tryParse(timeStr) ?? baseDate;
              } else {
                ts = baseDate;
              }
              timeline.add(EnergyData(
                deviceId: plantId,
                timestamp: ts,
                power: 0,
                energy: val,
                voltage: 0,
                current: 0,
                temperature: 0,
                additionalData: const {},
              ));
            } catch (_) {}
          }
        } else {
          // Other possible arrays
          items = (dat['perday'] as List?) ?? (dat['parameter'] as List?) ?? [];
        }
      }
      if (items.isNotEmpty) {
        for (final it in items) {
          try {
            final val = it is Map
                ? (double.tryParse(it['val']?.toString() ?? '0') ?? 0.0)
                : 0.0;
            totalKwh += val;
            final tsRaw = (it is Map ? it['ts'] : null)?.toString();
            final ts = tsRaw != null
                ? (DateTime.tryParse(tsRaw) ?? baseDate)
                : baseDate;
            timeline.add(EnergyData(
              deviceId: plantId,
              timestamp: ts,
              power: 0,
              energy: val,
              voltage: 0,
              current: 0,
              temperature: 0,
              additionalData: const {},
            ));
          } catch (_) {}
        }
      }
    }

    // If nothing parsed, return zero summary for the day
    if (timeline.isEmpty) {
      final zero = EnergyData(
        deviceId: plantId,
        timestamp: baseDate,
        power: 0,
        energy: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        additionalData: const {},
      );
      return EnergySummary(
        deviceId: plantId,
        date: baseDate,
        totalEnergy: 0,
        peakPower: 0,
        averagePower: 0,
        hourlyData: [zero],
      );
    }
    final peak =
        timeline.fold<double>(0, (m, e) => e.energy > m ? e.energy : m);
    final double avg = timeline.isEmpty ? 0.0 : (totalKwh / timeline.length);
    return EnergySummary(
      deviceId: plantId,
      date: baseDate,
      totalEnergy: totalKwh,
      peakPower: peak,
      averagePower: avg,
      hourlyData: timeline,
    );
  }

  Future<EnergySummary> getMonthlyEnergy(
      String plantId, String year, String month) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.getMonthlyGeneration}?plantId=$plantId&year=$year&month=$month',
      );
      final data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return EnergySummary.fromJson(data['data']);
      }
    } catch (_) {
      // fall through to DESS fallback
    }
    // Fallback to legacy DESS aggregated endpoint
    return await _getPlantEnergyMonthPerDayDess(
      plantId: plantId,
      year: year,
      month: month,
    );
  }

  Future<EnergySummary> getYearlyEnergy(String plantId, String year) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.getYearlyGeneration}?plantId=$plantId&year=$year',
      );
      final data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return EnergySummary.fromJson(data['data']);
      }
    } catch (_) {
      // fall through to DESS fallback
    }
    // Fallback to legacy DESS aggregated endpoint
    return await _getPlantEnergyYearPerMonthDess(
      plantId: plantId,
      year: year,
    );
  }

  // Returns a per-year energy timeline for the plant using DESS endpoint.
  Future<EnergySummary> getPlantEnergyTotalPerYear(String plantId) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final action =
        '&action=queryPlantEnergyTotalPerYear&plantid=$plantId&source=1';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final resp = await _apiClient.signedPost(url);
    final js = json.decode(resp.body);
    final now = DateTime.now();
    final baseDate = DateTime(now.year, 1, 1);
    final points = <EnergyData>[];
    if (js['err'] == 0 && js['dat'] != null) {
      final dat = js['dat'];
      List list = dat['peryear'] ?? dat['parameter'] ?? [];
      if (list.isNotEmpty) {
        for (final e in list) {
          try {
            final v = e['val'];
            final d = v is num ? v.toDouble() : double.tryParse('${v}') ?? 0.0;
            final tsRaw = e['ts']?.toString();
            DateTime ts;
            if (tsRaw != null) {
              // Expect 'YYYY' or 'YYYY-01-01'
              ts = DateTime.tryParse(tsRaw) ??
                  DateTime(int.tryParse(tsRaw) ?? now.year, 1, 1);
            } else {
              final y = e['year'] is num ? e['year'] as int : now.year;
              ts = DateTime(y, 1, 1);
            }
            points.add(EnergyData(
              deviceId: plantId,
              timestamp: ts,
              power: 0,
              energy: d,
              voltage: 0,
              current: 0,
              temperature: 0,
              additionalData: const {},
            ));
          } catch (_) {}
        }
      } else {
        // Try table shape: row/title
        final rows = dat['row'] as List?;
        final titles = dat['title'] as List?;
        if (rows != null && rows.isNotEmpty) {
          int firstNumericIdx = 0;
          if (titles != null && titles.isNotEmpty) {
            final idxEnergy = titles.indexWhere((t) {
              try {
                final title =
                    (t is Map ? t['title'] : t)?.toString().toLowerCase();
                return title != null &&
                    (title.contains('energy') ||
                        title.contains('generation') ||
                        title.contains('kwh'));
              } catch (_) {
                return false;
              }
            });
            if (idxEnergy != -1) firstNumericIdx = idxEnergy;
          }
          for (final r in rows) {
            try {
              final timeStr = (r is Map ? r['time'] : null)?.toString();
              final fields = (r is Map ? r['field'] : null) as List?;
              if (fields == null || fields.isEmpty) continue;
              final raw = fields.length > firstNumericIdx
                  ? fields[firstNumericIdx]
                  : fields.first;
              final val = raw is num
                  ? raw.toDouble()
                  : double.tryParse(raw.toString()) ?? 0.0;
              DateTime ts;
              if (timeStr != null && timeStr.isNotEmpty) {
                // Expect 'YYYY'
                final y = int.tryParse(timeStr) ?? now.year;
                ts = DateTime(y, 1, 1);
              } else {
                ts = DateTime(now.year - (rows.indexOf(r)), 1, 1);
              }
              points.add(EnergyData(
                deviceId: plantId,
                timestamp: ts,
                power: 0,
                energy: val,
                voltage: 0,
                current: 0,
                temperature: 0,
                additionalData: const {},
              ));
            } catch (_) {}
          }
        }
      }
    }
    double total = 0;
    double peak = 0;
    for (final p in points) {
      total += p.energy;
      if (p.energy > peak) peak = p.energy;
    }
    return EnergySummary(
      deviceId: plantId,
      date: baseDate,
      totalEnergy: total,
      peakPower: peak,
      averagePower: points.isEmpty ? 0 : total / (points.length),
      hourlyData: points,
    );
  }

  Future<List<EnergyData>> getRealTimeData(String deviceId) async {
    final response = await _apiClient
        .get('${ApiEndpoints.getDeviceData}&deviceId=$deviceId');
    final data = json.decode(response.body);

    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> energyDataJson = data['data'];
      print('Real-time energy data: $energyDataJson');
      return energyDataJson.map((json) => EnergyData.fromJson(json)).toList();
    }
    return [];
  }

  Future<EnergySummary> getProfitStatistic(String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$date';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    print('EnergyRepository: Fetching profit statistics for date $date');
    final response = await _apiClient.signedPost(url);
    print('Profit statistics raw response: \n${response.body}');

    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      return EnergySummary.fromJson(dataJson['dat']);
    }
    throw Exception('Failed to get profit statistic');
  }

  /// Get profit statistics matching old app behavior
  /// Date: 'all' for total profits, specific date (YYYY-MM-DD) for daily profits
  Future<ProfitStatistic?> queryPlantsProfitStatistic(
      {required String Date}) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action = Date == 'all'
        ? '&action=queryPlantsProfitStatistic&lang=zh_CN'
        : '&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=$Date';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    print('EnergyRepository: Fetching profit statistics for date $Date');
    try {
      final response = await _apiClient.signedPost(url);
      print('Profit statistics raw response: \n${response.body}');

      final dataJson = json.decode(response.body);
      if (dataJson['err'] == 0 && dataJson['dat'] != null) {
        final dat = dataJson['dat'];
        if (dat is Map<String, dynamic>) {
          // Direct map with values
          // Some responses come in table form with title/row
          if (dat.containsKey('row')) {
            try {
              final rows = (dat['row'] as List?) ?? const [];
              final titles = (dat['title'] as List?) ?? const [];
              if (rows.isNotEmpty) {
                final first = rows.first as Map;
                final fields = (first['field'] as List?) ?? const [];
                // Build title list in lowercase for matching
                final titleTexts = titles
                    .map((t) =>
                        (t is Map ? t['title'] : t)
                            ?.toString()
                            .toLowerCase()
                            .trim() ??
                        '')
                    .toList();

                int idxOf(List<String> candidates) {
                  for (final c in candidates) {
                    final i = titleTexts.indexWhere((t) => t.contains(c));
                    if (i != -1) return i;
                  }
                  return -1;
                }

                String valAt(int idx) {
                  if (idx >= 0 && idx < fields.length) {
                    final v = fields[idx];
                    return (v is num) ? v.toString() : (v?.toString() ?? '');
                  }
                  return '';
                }

                // Heuristics: pick profit/money/income column
                final profitIdx = idxOf(['profit', 'money', 'income']);
                final currencyIdx = idxOf(['currency', 'unit']);
                final energyIdx = idxOf(['energy', 'generation', 'kwh']);

                final profit = valAt(profitIdx).isNotEmpty
                    ? valAt(profitIdx)
                    : (dat['profit']?.toString() ?? '0.0');
                final currency = valAt(currencyIdx).isNotEmpty
                    ? valAt(currencyIdx)
                    : (dat['currency']?.toString() ??
                        dat['profitUnit']?.toString() ??
                        '');
                final energy = valAt(energyIdx).isNotEmpty
                    ? valAt(energyIdx)
                    : (dat['energy']?.toString() ?? '0.0000');
                return ProfitStatistic(
                  co2: dat['co2']?.toString() ?? '0.0000',
                  so2: dat['so2']?.toString() ?? '0.0000',
                  coal: dat['coal']?.toString() ?? '0.0000',
                  profit: profit.isEmpty ? '0.0' : profit,
                  energy: energy.isEmpty ? '0.0000' : energy,
                  currency: currency,
                );
              }
            } catch (_) {
              // fallthrough to fromJson
            }
          }
          return ProfitStatistic.fromJson(dat);
        }
      }
      print('Profit statistics error: ${dataJson['desc']}');
      return null;
    } catch (e) {
      print('Error fetching profit statistics: $e');
      return null;
    }
  }

  // --- DESS aggregated fallbacks ---
  Future<EnergySummary> _getPlantEnergyMonthPerDayDess({
    required String plantId,
    required String year,
    required String month,
  }) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final ym = '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}';
    final action =
        '&action=queryPlantEnergyMonthPerDay&plantid=$plantId&date=$ym';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final resp = await _apiClient.signedPost(url);
    final dataJson = json.decode(resp.body);
    final baseDate = DateTime(int.parse(year), int.parse(month), 1);
    final daysInMonth = DateTime(baseDate.year, baseDate.month + 1, 0).day;
    final points = <EnergyData>[];
    if (dataJson['dat'] != null) {
      final dat = dataJson['dat'];
      // Common shapes: energy/detail OR table (title/row) OR perday/parameter
      List items = (dat['energy'] as List?) ?? (dat['detail'] as List?) ?? [];
      if (items.isEmpty) {
        // Table-shape with title/row
        final rows = dat['row'] as List?;
        final titles = dat['title'] as List?;
        if (rows != null && rows.isNotEmpty) {
          // Pick first numeric column index
          int firstNumericIdx = 0;
          if (titles != null && titles.isNotEmpty) {
            // Try find a column named like Energy or Generation if present
            final idxEnergy = titles.indexWhere((t) {
              try {
                final title =
                    (t is Map ? t['title'] : t)?.toString().toLowerCase();
                return title != null &&
                    (title.contains('energy') || title.contains('generation'));
              } catch (_) {
                return false;
              }
            });
            if (idxEnergy != -1) firstNumericIdx = idxEnergy;
          }
          for (final r in rows) {
            try {
              final timeStr = (r is Map ? r['time'] : null)?.toString();
              final fields = (r is Map ? r['field'] : null) as List?;
              if (fields == null || fields.isEmpty) continue;
              final raw = fields.length > firstNumericIdx
                  ? fields[firstNumericIdx]
                  : fields.first;
              final val = raw is num
                  ? raw.toDouble()
                  : double.tryParse(raw.toString()) ?? 0.0;
              DateTime ts;
              if (timeStr != null && timeStr.isNotEmpty) {
                // time may be '1'..'31' or '2025-09-01'
                if (timeStr.contains('-')) {
                  ts = DateTime.tryParse(timeStr) ?? baseDate;
                } else {
                  final day = int.tryParse(timeStr) ?? 1;
                  ts = DateTime(baseDate.year, baseDate.month, day);
                }
              } else {
                ts = DateTime(
                    baseDate.year, baseDate.month, (points.length + 1));
              }
              points.add(EnergyData(
                deviceId: plantId,
                timestamp: ts,
                power: 0,
                energy: val,
                voltage: 0,
                current: 0,
                temperature: 0,
                additionalData: const {},
              ));
            } catch (_) {}
          }
        } else {
          // other possible arrays
          items = (dat['perday'] as List?) ?? (dat['parameter'] as List?) ?? [];
        }
      }
      if (items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          final it = items[i];
          try {
            final tsRaw = (it is Map ? it['ts'] : null)?.toString();
            final val = it is Map
                ? (double.tryParse(it['val']?.toString() ?? '0') ?? 0.0)
                : 0.0;
            DateTime ts;
            if (tsRaw != null) {
              ts = DateTime.tryParse(tsRaw) ??
                  DateTime(baseDate.year, baseDate.month, i + 1);
            } else {
              ts = DateTime(baseDate.year, baseDate.month, i + 1);
            }
            points.add(EnergyData(
              deviceId: plantId,
              timestamp: ts,
              power: 0,
              energy: val,
              voltage: 0,
              current: 0,
              temperature: 0,
              additionalData: const {},
            ));
          } catch (_) {}
        }
      }
    }
    // Pad to full month length with zeros
    while (points.length < daysInMonth) {
      final d = points.length + 1;
      points.add(EnergyData(
        deviceId: plantId,
        timestamp: DateTime(baseDate.year, baseDate.month, d),
        power: 0,
        energy: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        additionalData: const {},
      ));
    }
    double total = 0;
    double peak = 0;
    for (final p in points) {
      total += p.energy;
      if (p.energy > peak) peak = p.energy;
    }
    return EnergySummary(
      deviceId: plantId,
      date: baseDate,
      totalEnergy: total,
      peakPower: peak,
      averagePower: points.isEmpty ? 0 : total / points.length,
      hourlyData: points,
    );
  }

  Future<EnergySummary> _getPlantEnergyYearPerMonthDess({
    required String plantId,
    required String year,
  }) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryPlantEnergyYearPerMonth&plantid=$plantId&date=$year';
    const postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final resp = await _apiClient.signedPost(url);
    final dataJson = json.decode(resp.body);
    final baseDate = DateTime(int.parse(year), 1, 1);
    final points = <EnergyData>[];
    if (dataJson['dat'] != null) {
      final dat = dataJson['dat'];
      // Common shapes from DESS:
      // - permonth/parameter: [{ ts: 'YYYY-MM-01', val: number }, ...]
      // - energy/detail: legacy arrays
      // - row/title: table-like where row[i].time + row[i].field[j]
      List items = (dat['permonth'] as List?) ??
          (dat['parameter'] as List?) ??
          (dat['energy'] as List?) ??
          (dat['detail'] as List?) ??
          [];
      if (items.isEmpty) {
        // Try table shape
        final rows = dat['row'] as List?;
        final titles = dat['title'] as List?; // may contain column names
        if (rows != null && rows.isNotEmpty) {
          int firstNumericIdx = 0;
          if (titles != null && titles.isNotEmpty) {
            final idxEnergy = titles.indexWhere((t) {
              try {
                final title =
                    (t is Map ? t['title'] : t)?.toString().toLowerCase();
                return title != null &&
                    (title.contains('energy') ||
                        title.contains('generation') ||
                        title.contains('kwh'));
              } catch (_) {
                return false;
              }
            });
            if (idxEnergy != -1) firstNumericIdx = idxEnergy;
          }
          for (final r in rows) {
            try {
              final timeStr = (r is Map ? r['time'] : null)?.toString();
              final fields = (r is Map ? r['field'] : null) as List?;
              if (fields == null || fields.isEmpty) continue;
              final raw = fields.length > firstNumericIdx
                  ? fields[firstNumericIdx]
                  : fields.first;
              final val = raw is num
                  ? raw.toDouble()
                  : double.tryParse(raw.toString()) ?? 0.0;
              DateTime ts;
              if (timeStr != null && timeStr.isNotEmpty) {
                // Could be '1'..'12' or 'YYYY-MM'
                if (timeStr.contains('-')) {
                  // 'YYYY-MM' or 'YYYY-MM-01'
                  final parsed = DateTime.tryParse(
                      timeStr.length == 7 ? '$timeStr-01' : timeStr);
                  ts = parsed ?? baseDate;
                } else {
                  final m = int.tryParse(timeStr) ?? 1;
                  ts = DateTime(baseDate.year, m, 1);
                }
              } else {
                ts = DateTime(baseDate.year, (points.length + 1), 1);
              }
              points.add(EnergyData(
                deviceId: plantId,
                timestamp: ts,
                power: 0,
                energy: val,
                voltage: 0,
                current: 0,
                temperature: 0,
                additionalData: const {},
              ));
            } catch (_) {}
          }
        }
      }
      if (items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          final it = items[i];
          try {
            final tsRaw = (it is Map ? it['ts'] : null)?.toString();
            final val = it is Map
                ? (double.tryParse(it['val']?.toString() ?? '0') ?? 0.0)
                : 0.0;
            DateTime ts;
            if (tsRaw != null) {
              ts =
                  DateTime.tryParse(tsRaw) ?? DateTime(baseDate.year, i + 1, 1);
            } else {
              ts = DateTime(baseDate.year, i + 1, 1);
            }
            points.add(EnergyData(
              deviceId: plantId,
              timestamp: ts,
              power: 0,
              energy: val,
              voltage: 0,
              current: 0,
              temperature: 0,
              additionalData: const {},
            ));
          } catch (_) {}
        }
      }
    }
    // Ensure 12 months
    while (points.length < 12) {
      final m = points.length + 1;
      points.add(EnergyData(
        deviceId: plantId,
        timestamp: DateTime(baseDate.year, m, 1),
        power: 0,
        energy: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        additionalData: const {},
      ));
    }
    if (points.length > 12) {
      points.removeRange(12, points.length);
    }
    double total = 0;
    double peak = 0;
    for (final p in points) {
      total += p.energy;
      if (p.energy > peak) peak = p.energy;
    }
    return EnergySummary(
      deviceId: plantId,
      date: baseDate,
      totalEnergy: total,
      peakPower: peak,
      averagePower: points.isEmpty ? 0 : total / points.length,
      hourlyData: points,
    );
  }
}
