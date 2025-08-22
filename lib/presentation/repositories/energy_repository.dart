import 'dart:convert';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crown_micro_solar/core/network/api_endpoints.dart';
import 'package:crown_micro_solar/presentation/models/energy/energy_data_model.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnergyRepository {
  final ApiClient _apiClient;

  EnergyRepository(this._apiClient);

  Future<EnergySummary> getDailyEnergy(String plantId, String date) async {
    const salt = '12345678';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';

    final action =
        '&action=queryPlantActiveOuputPowerOneDay&plantid=$plantId&date=$date';
    final postaction =
        '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
    final data = salt + secret + token + action + postaction;
    final sign = sha1.convert(utf8.encode(data)).toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

    final response = await _apiClient.signedPost(url);
    final dataJson = json.decode(response.body);
    if (dataJson['dat'] != null) {
      final dat = dataJson['dat'];
      // Map legacy DESS structure to our EnergySummary shape
      final List<dynamic> list =
          (dat['outputPower'] as List?) ?? (dat['detail'] as List?) ?? [];
      final hourly = <EnergyData>[];
      for (final item in list) {
        try {
          final tsRaw = item['ts'];
          DateTime ts;
          if (tsRaw is String) {
            ts = DateTime.tryParse(tsRaw) ??
                DateTime.parse('$date ${item['time'] ?? '00:00:00'}');
          } else if (tsRaw is Map) {
            // Some responses split into fields, e.g., {"year":2024,"month":6,"day":1,"hour":12,...}
            final y = tsRaw['year'] ?? DateTime.now().year;
            final m = tsRaw['month'] ?? 1;
            final d = tsRaw['day'] ?? 1;
            final h = tsRaw['hour'] ?? 0;
            final min = tsRaw['minute'] ?? 0;
            ts = DateTime(y, m, d, h, min);
          } else {
            ts = DateTime.now();
          }

          final valStr = item['val']?.toString() ?? '0';
          final power = double.tryParse(valStr) ?? 0.0;
          hourly.add(EnergyData(
            deviceId: plantId,
            timestamp: ts,
            power: power,
            energy: 0,
            voltage: 0,
            current: 0,
            temperature: 0,
            additionalData: {},
          ));
        } catch (_) {}
      }

      // Compute basic stats
      double peak = 0;
      double sum = 0;
      for (final e in hourly) {
        peak = e.power > peak ? e.power : peak;
        sum += e.power;
      }
      final double avg =
          hourly.isEmpty ? 0.0 : (sum / hourly.length.toDouble());

      return EnergySummary(
        deviceId: plantId,
        date: DateTime.tryParse(date) ?? DateTime.now(),
        totalEnergy: sum,
        peakPower: peak,
        averagePower: avg,
        hourlyData: hourly,
      );
    }

    // Graceful fallback for no data (e.g., err=12 or missing dat): return zeros instead of throwing
    final baseDate = DateTime.tryParse(date) ?? DateTime.now();
    final zeroHourly = List<EnergyData>.generate(24, (h) {
      final ts = DateTime(baseDate.year, baseDate.month, baseDate.day, h);
      return EnergyData(
        deviceId: plantId,
        timestamp: ts,
        power: 0,
        energy: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        additionalData: const {},
      );
    });
    return EnergySummary(
      deviceId: plantId,
      date: baseDate,
      totalEnergy: 0,
      peakPower: 0,
      averagePower: 0,
      hourlyData: zeroHourly,
    );
  }

  Future<EnergySummary> getMonthlyEnergy(
      String deviceId, String year, String month) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.getMonthlyGeneration}&deviceId=$deviceId&year=$year&month=$month',
    );
    final data = json.decode(response.body);

    if (data['success'] == true && data['data'] != null) {
      return EnergySummary.fromJson(data['data']);
    }
    throw Exception('Failed to get monthly energy data');
  }

  Future<EnergySummary> getYearlyEnergy(String deviceId, String year) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.getYearlyGeneration}&deviceId=$deviceId&year=$year',
    );
    final data = json.decode(response.body);

    if (data['success'] == true && data['data'] != null) {
      print('Yearly energy data: ${data['data']}');
      return EnergySummary.fromJson(data['data']);
    }
    throw Exception('Failed to get yearly energy data');
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
}
