import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReportRange { week, month, year }

class ReportDownloadService {
  final Dio _dio;
  ReportDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> downloadPowerGenerationReport({
    required String plantId,
    required ReportRange range,
    required DateTime anchorDate,
    void Function(int received, int total)? onProgress,
  }) async {
    // Permissions (Android only)
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }
    }

    // Auth items from old app
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    const salt = '12345678';
    const postaction =
        '&source=1&app_id=crown.micro.app&app_version=1.0.0&app_client=android';

    if (token.isEmpty || secret.isEmpty) {
      throw Exception('Missing token/secret');
    }

    // Build action
    String action;
    String fileTag;
    switch (range) {
      case ReportRange.week:
        final start = _startOfWeek(anchorDate);
        final end = _endOfWeek(anchorDate);
        final s = DateFormat('yyyy-MM-dd').format(start);
        final e = DateFormat('yyyy-MM-dd').format(end);
        action =
            '&action=exportDeviceCustomData&plantid=$plantId&start=$s&end=$e';
        fileTag = 'week_${s}_to_${e}';
        break;
      case ReportRange.month:
        final d = DateFormat('yyyy-MM').format(anchorDate);
        // Old app uses exportDeviceMonthData
        action = '&action=exportDeviceMonthData&plantid=$plantId&date=$d-01';
        fileTag = 'month_${d}';
        break;
      case ReportRange.year:
        final y = DateFormat('yyyy').format(anchorDate);
        action =
            '&action=exportDeviceCustomData&plantid=$plantId&start=$y-01-01&end=$y-12-31';
        fileTag = 'year_${y}';
        break;
    }

    final parsed = Uri(query: action).query;
    final sign = sha1
        .convert(utf8.encode(salt + secret + token + parsed + postaction))
        .toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$parsed$postaction';

    final downloadsDir = await _getDownloadsDirectory();
    final filePath =
        '${downloadsDir.path}/crown_power_generation_$fileTag.xlsx';

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
    );

    return filePath;
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Try standard Downloads path; if missing, fallback to external storage directory
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      final candidates =
          await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (candidates != null && candidates.isNotEmpty) return candidates.first;
    }
    // iOS/Mac/Windows/Linux
    return await getApplicationDocumentsDirectory();
  }

  DateTime _startOfWeek(DateTime d) {
    final weekday = d.weekday; // 1=Mon..7=Sun
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    final start = _startOfWeek(d);
    return start.add(const Duration(days: 6));
  }
}
