import 'dart:convert';
import 'package:crown_micro_solar/presentation/models/alarm/alarm_model.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AlarmRepository {
  final Dio _dio = Dio();

  // Constructor accepts ApiClient for consistency with service locator but doesn't use it
  // since this repository uses Dio directly for the specific Growatt API
  AlarmRepository([ApiClient? apiClient]);

  Future<List<Alarm>> getAlarms(String plantId) async {
    // For now, return warnings as alarms since the API returns warnings
    return await getWarnings(plantId).then((warnings) => warnings
        .map((warning) => Alarm(
              id: warning.id,
              deviceId: warning.sn,
              plantId: plantId,
              type: warning.severityText,
              severity: warning.severityText.toLowerCase(),
              message: warning.desc,
              timestamp: warning.gts,
              isActive: !warning.handle,
              parameters: warning.toJson(),
            ))
        .toList());
  }

  Future<List<Warning>> getWarnings(
    String plantId, {
    String? startDate,
    String? endDate,
    String? deviceType,
    String? status,
    String? alarmType,
    String? sn,
  }) async {
    // Use DESS/ShineMonitor style like old app: webQueryPlantsWarning signed with sha1
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final secret = prefs.getString('Secret') ?? '';
      const salt = '12345678';

      if (token.isEmpty || secret.isEmpty) {
        print(
            'AlarmRepository: Missing token/secret, returning sample warnings');
        return _getSampleWarnings();
      }

      // Defaults like old app
      String level = '0101';
      String devtype = '0101';
      String handle = '0101';
      if (alarmType != null) {
        switch (alarmType) {
          case 'Warning':
          case 'WARNING':
            level = '0';
            break;
          case 'Error':
            level = '1';
            break;
          case 'Fault':
          case 'FAULT':
            level = '2';
            break;
        }
      }

      if (deviceType != null) {
        switch (deviceType) {
          case 'Inverter':
            devtype = '512';
            break;
          case 'Env-monitor':
            devtype = '768';
            break;
          case 'Smart meters':
          case 'Smart meter':
            devtype = '1024';
            break;
          case 'Combining manifolds':
            devtype = '1280';
            break;
          case 'Battery':
            devtype = '1792';
            break;
          case 'Charger':
            devtype = '2048';
            break;
          case 'Energy storage machine':
            devtype = '2452';
            break;
          default:
            // If deviceType is actually an SN from the dropdown, pass as sn filter
            sn = deviceType;
            devtype = '0101';
        }
      }

      if (status != null) {
        switch (status) {
          case 'Untreated':
            handle = 'false';
            break;
          case 'Processed':
            handle = 'true';
            break;
          default:
            handle = '0101';
        }
      }

      // Build action variants similar to old app
      String actionBase =
          '&action=webQueryPlantsWarning&source=1&i18n=en_US&page=0&pagesize=100&plantid=$plantId';
      if (sn != null && sn.isNotEmpty) actionBase += '&sn=$sn';

      String action = actionBase;
      if (level != '0101') action += '&level=$level';
      if (devtype != '0101') action += '&devtype=$devtype';
      if (handle != '0101') action += '&handle=$handle';

      // Date range
      if (startDate != null && endDate != null) {
        action += '&sdate=$startDate 00:00:00&edate=$endDate 23:59:59';
      }

      // Post action like old app (app info)
      const postaction =
          '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';

      final parsedAction = Uri(query: action).query;
      final signData = salt + secret + token + parsedAction + postaction;
      final sign = sha1.convert(utf8.encode(signData)).toString();
      final url =
          'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$parsedAction$postaction';

      print('AlarmRepository: Fetching warnings URL: $url');
      final response = await _dio.post(url,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        final data = response.data;
        print('AlarmRepository: warnings response: $data');
        if (data == null) return [];
        if (data is String && data.isEmpty) return [];
        if (data['err'] != 0) {
          print('AlarmRepository: API error: ${data['desc']}');
          return [];
        }
        if (data['dat'] != null && data['dat']['warning'] != null) {
          final List<dynamic> warningsJson = data['dat']['warning'];
          return warningsJson.map((j) => Warning.fromJson(j)).toList();
        }
        return [];
      }
      print('AlarmRepository: HTTP error ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching warnings: $e');
      return _getSampleWarnings();
    }
  }

  Future<bool> deleteWarning(String warningId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final username = prefs.getString('username');
      final appkey = prefs.getString('appkey');

      if (token == null || username == null || appkey == null) {
        throw Exception('Authentication required');
      }

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      String queryString =
          'action=delPlantWarning&warningId=$warningId&timeStamp=$timestamp&token=$token';

      // Generate signature
      final signatureInput = queryString + appkey;
      final bytes = utf8.encode(signatureInput);
      final digest = md5.convert(bytes);
      final sign = digest.toString();

      queryString += '&sign=$sign';

      final response = await _dio.get(
        'https://openapi.growatt.com/v1/plant/warning/del?$queryString',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200 && response.data['result'] == 1;
    } catch (e) {
      throw Exception('Error deleting warning: $e');
    }
  }

  Future<bool> acknowledgeAlarm(String alarmId) async {
    return await acknowledgeWarning(alarmId);
  }

  Future<bool> acknowledgeWarning(String warningId) async {
    try {
      // Map to DESS ignorePlantWarning like old app
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final secret = prefs.getString('Secret') ?? '';
      const salt = '12345678';

      if (token.isEmpty || secret.isEmpty) {
        throw Exception('Authentication required');
      }

      final action = '&action=ignorePlantWarning&i18n=en_US&id=$warningId';
      const postaction =
          '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
      final signData = salt + secret + token + action + postaction;
      final sign = sha1.convert(utf8.encode(signData)).toString();
      final url =
          'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$action$postaction';

      final response = await _dio.post(url,
          options: Options(headers: {'Content-Type': 'application/json'}));

      return response.statusCode == 200 && response.data['err'] == 0;
    } catch (e) {
      throw Exception('Error acknowledging warning: $e');
    }
  }

  // Sample warnings for testing UI when API is not available
  List<Warning> _getSampleWarnings() {
    return [
      Warning(
        id: 'sample_1',
        sn: 'INV001',
        pn: 'PLANT001',
        devcode: 530, // Inverter
        desc: 'High temperature detected in inverter module',
        level: 0, // Warning
        code: '101',
        gts: DateTime.now().subtract(const Duration(hours: 2)),
        handle: false,
      ),
      Warning(
        id: 'sample_2',
        sn: 'BAT001',
        pn: 'PLANT001',
        devcode: 1792, // Battery
        desc: 'Battery voltage below optimal range',
        level: 1, // Error
        code: '201',
        gts: DateTime.now().subtract(const Duration(hours: 6)),
        handle: false,
      ),
      Warning(
        id: 'sample_3',
        sn: 'MON001',
        pn: 'PLANT001',
        devcode: 768, // Env-monitor
        desc: 'Communication timeout with monitoring device',
        level: 2, // Fault
        code: '301',
        gts: DateTime.now().subtract(const Duration(days: 1)),
        handle: true,
      ),
      Warning(
        id: 'sample_4',
        sn: 'INV002',
        pn: 'PLANT001',
        devcode: 530, // Inverter
        desc: 'Grid frequency fluctuation detected',
        level: 0, // Warning
        code: '102',
        gts: DateTime.now().subtract(const Duration(hours: 4)),
        handle: false,
      ),
      Warning(
        id: 'sample_5',
        sn: 'CHG001',
        pn: 'PLANT001',
        devcode: 2048, // Charger
        desc: 'Charging current exceeded maximum limit',
        level: 1, // Error
        code: '202',
        gts: DateTime.now().subtract(const Duration(hours: 8)),
        handle: true,
      ),
    ];
  }
}
