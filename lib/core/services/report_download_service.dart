import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Legacy-compatible ranges for collector report exports
enum CollectorReportRange { daily, monthly, yearly }

// Full/global report types following legacy actions
enum FullReportRange { daily, monthly, custom }

class ReportDownloadService {
  final Dio _dio;
  ReportDownloadService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ));

  // New: Download collector/device report using legacy-compatible exportCollectorsData
  // Requires collector PN and a daily/monthly/yearly selection.
  Future<String?> downloadCollectorReport({
    required String collectorPn,
    required CollectorReportRange range,
    required DateTime anchorDate,
    String filePrefix = 'crown_report',
    void Function(int received, int total)? onProgress,
  }) async {
    print('ReportDownloadService: Starting download - collectorPn: $collectorPn, range: $range, date: $anchorDate');
    
    // Permissions (Android only)
    if (Platform.isAndroid) {
      print('ReportDownloadService: Requesting storage permissions...');
      final manage = await Permission.manageExternalStorage.request();
      if (!manage.isGranted) {
        print('ReportDownloadService: Manage external storage not granted, trying regular storage...');
        final storage = await Permission.storage.request();
        if (!storage.isGranted) {
          print('ReportDownloadService: Storage permission denied');
          throw Exception('Storage permission not granted');
        }
      }
      print('ReportDownloadService: Storage permissions granted');
    }

    // Auth and app info (match legacy)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    if (token.isEmpty || secret.isEmpty) {
      print('ReportDownloadService: Missing credentials - token: ${token.isEmpty ? "empty" : "present"}, secret: ${secret.isEmpty ? "empty" : "present"}');
      throw Exception('Missing token/secret');
    }
    print('ReportDownloadService: Credentials loaded');
    
    final pkg = await PackageInfo.fromPlatform();
    final String appId = pkg.packageName;
    final String appVersion = pkg.version;
    final String platform = Platform.isAndroid ? 'android' : 'ios';
    const salt = '12345678';
    final postaction =
        '&source=1&app_id=$appId&app_version=$appVersion&app_client=$platform';

    // Build action for exportCollectorsData (always pass year/month/day keys)
    String year = '';
    String month = '';
    String day = '';
    String fileTag;
    switch (range) {
      case CollectorReportRange.daily:
        year = DateFormat('y').format(anchorDate);
        month = DateFormat('M').format(anchorDate);
        day = DateFormat('d').format(anchorDate);
        fileTag = 'daily_${DateFormat('yyyy-MM-dd').format(anchorDate)}';
        break;
      case CollectorReportRange.monthly:
        year = DateFormat('y').format(anchorDate);
        month = DateFormat('M').format(anchorDate);
        day = '';
        fileTag = 'monthly_${DateFormat('yyyy-MM').format(anchorDate)}';
        break;
      case CollectorReportRange.yearly:
        year = DateFormat('y').format(anchorDate);
        month = '';
        day = '';
        fileTag = 'yearly_${DateFormat('yyyy').format(anchorDate)}';
        break;
    }

    final action =
        '&action=exportCollectorsData&i18n=en_US&pns=$collectorPn&year=$year&month=$month&day=$day';
    final parsed = Uri(query: action).query;
    final sign = sha1
        .convert(utf8.encode(salt + secret + token + parsed + postaction))
        .toString();
    final url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$parsed$postaction';

    print('ReportDownloadService: Download URL prepared');

    final downloadsDir = await _getDownloadsDirectory();
    final filePath = '${downloadsDir.path}/${filePrefix}_$fileTag.xlsx';

    print('ReportDownloadService: Saving to: $filePath');
    print('ReportDownloadService: Starting download...');

    await _dio.download(url, filePath, onReceiveProgress: (received, total) {
      print('ReportDownloadService: Downloaded $received of $total bytes');
      if (onProgress != null) {
        onProgress(received, total);
      }
    });

    print('ReportDownloadService: Download completed successfully');
    print('ReportDownloadService: File saved at: $filePath');
    
    // Verify file exists
    final file = File(filePath);
    if (await file.exists()) {
      final size = await file.length();
      print('ReportDownloadService: File verified - size: $size bytes');
    } else {
      print('ReportDownloadService: WARNING - File not found after download!');
    }

    return filePath;
  }

  // Backward-compatible wrapper for "full report" dialog: use collector PN and legacy export
  Future<String?> downloadFullReportByCollector({
    required String collectorPn,
    required CollectorReportRange range,
    required DateTime anchorDate,
    void Function(int received, int total)? onProgress,
  }) async {
    return downloadCollectorReport(
      collectorPn: collectorPn,
      range: range,
      anchorDate: anchorDate,
      filePrefix: 'crown_full_report',
      onProgress: onProgress,
    );
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

  // (No weekly export supported by legacy exportCollectorsData)
}
