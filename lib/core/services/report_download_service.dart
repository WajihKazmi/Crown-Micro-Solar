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
    print(
        'ReportDownloadService: Starting download - collectorPn: $collectorPn, range: $range, date: $anchorDate');

    // Permissions (Android only)
    // Note: On Android 11+, MANAGE_EXTERNAL_STORAGE requires Play Store approval
    // We try to request it but continue with fallback paths if not granted
    if (Platform.isAndroid) {
      print('ReportDownloadService: Checking storage permissions...');

      // First try the regular storage permission (needed for Android < 10)
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        print('ReportDownloadService: Storage permission: $storageStatus');
      }

      // For Android 11+, try MANAGE_EXTERNAL_STORAGE but don't block if denied
      // Our _getDownloadsDirectory has fallback strategies that work without it
      final manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        print(
            'ReportDownloadService: MANAGE_EXTERNAL_STORAGE not granted, using fallback paths');
        // Don't throw - we have fallback strategies in _getDownloadsDirectory
      } else {
        print('ReportDownloadService: Full storage access granted');
      }
    }

    // Auth and app info (match legacy)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    if (token.isEmpty || secret.isEmpty) {
      print(
          'ReportDownloadService: Missing credentials - token: ${token.isEmpty ? "empty" : "present"}, secret: ${secret.isEmpty ? "empty" : "present"}');
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

  /// Get a writable Downloads directory that works across all Android versions.
  /// On Android 10+, we try multiple strategies to find a working path.
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Strategy 1: Try standard public Downloads path (works on most devices)
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        // Test if we can actually write to this directory
        try {
          final testFile = File('${publicDownloads.path}/.crown_test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          print('ReportDownloadService: Using public Downloads folder');
          return publicDownloads;
        } catch (e) {
          print('ReportDownloadService: Cannot write to public Downloads: $e');
        }
      }

      // Strategy 2: Try alternative public Download path (some devices use this)
      final altDownloads = Directory('/storage/emulated/0/Downloads');
      if (await altDownloads.exists()) {
        try {
          final testFile = File('${altDownloads.path}/.crown_test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          print('ReportDownloadService: Using alternative Downloads folder');
          return altDownloads;
        } catch (e) {
          print('ReportDownloadService: Cannot write to alt Downloads: $e');
        }
      }

      // Strategy 3: Use external storage directories (app-specific but accessible via file manager)
      final candidates =
          await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (candidates != null && candidates.isNotEmpty) {
        final dir = candidates.first;
        // Create directory if needed
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        print(
            'ReportDownloadService: Using app external Downloads: ${dir.path}');
        return dir;
      }

      // Strategy 4: Use general external storage directory
      final externalStorageDirs = await getExternalStorageDirectories();
      if (externalStorageDirs != null && externalStorageDirs.isNotEmpty) {
        final downloadDir =
            Directory('${externalStorageDirs.first.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        print(
            'ReportDownloadService: Using app external storage Downloads: ${downloadDir.path}');
        return downloadDir;
      }

      // Strategy 5: Last resort - use app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      print(
          'ReportDownloadService: Using app documents Downloads: ${downloadDir.path}');
      return downloadDir;
    }

    // iOS/Mac/Windows/Linux - use documents directory
    return await getApplicationDocumentsDirectory();
  }

  /// Download device-specific data report (uses queryDeviceDataOneDayPaging API)
  /// Creates a CSV file with device parameters for a specific date
  Future<String?> downloadDeviceDataReport({
    required String pn,
    required String sn,
    required String devcode,
    required String devaddr,
    required DateTime date,
    String filePrefix = 'crown_device_report',
    void Function(double progress)? onProgress,
  }) async {
    print('ReportDownloadService: Starting device data report download');

    // Permissions (Android only) - use fallback-friendly approach
    if (Platform.isAndroid) {
      print(
          'ReportDownloadService: Checking storage permissions for device report...');
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      // Don't block on MANAGE_EXTERNAL_STORAGE - _getDownloadsDirectory has fallbacks
    }

    // Auth and app info
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final secret = prefs.getString('Secret') ?? '';
    if (token.isEmpty || secret.isEmpty) {
      throw Exception('Missing token/secret');
    }

    final pkg = await PackageInfo.fromPlatform();
    final String appId = pkg.packageName;
    final String appVersion = pkg.version;
    final String platform = Platform.isAndroid ? 'android' : 'ios';
    const salt = '12345678';
    final postaction =
        '&source=1&app_id=$appId&app_version=$appVersion&app_client=$platform';

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Fetch device paging data
    List<Map<String, dynamic>> allRows = [];
    List<String> headers = [];
    int page = 0;
    const pageSize = 200;
    bool hasMore = true;

    onProgress?.call(0.1);

    while (hasMore) {
      final action =
          '&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=$dateStr&page=$page&pagesize=$pageSize&i18n=en_US';
      final parsed = Uri(query: action).query;
      final sign = sha1
          .convert(utf8.encode(salt + secret + token + parsed + postaction))
          .toString();
      final url =
          'http://api.dessmonitor.com/public/?sign=$sign&salt=$salt&token=$token$parsed$postaction';

      try {
        final response = await _dio.get(url);
        final data = response.data;

        if (data == null || data['err'] != 0) {
          print(
              'ReportDownloadService: API error - ${data?['desc'] ?? 'unknown'}');
          break;
        }

        final dat = data['dat'];
        if (dat == null) break;

        // Extract headers from first page
        if (headers.isEmpty && dat['title'] is List) {
          headers = (dat['title'] as List)
              .map((t) => (t['title']?.toString() ?? '').replaceAll(',', ' '))
              .toList();
        }

        // Extract rows
        final rows = dat['row'] as List? ?? [];
        if (rows.isEmpty) {
          hasMore = false;
        } else {
          for (final row in rows) {
            final fields = row['field'] as List? ?? [];
            final rowMap = <String, dynamic>{};
            for (int i = 0; i < headers.length && i < fields.length; i++) {
              rowMap[headers[i]] = fields[i]?.toString() ?? '';
            }
            allRows.add(rowMap);
          }
          page++;
          onProgress?.call(0.1 + 0.6 * (page / (page + 1)));

          // Check if we got less than pageSize (last page)
          if (rows.length < pageSize) {
            hasMore = false;
          }
        }
      } catch (e) {
        print('ReportDownloadService: Error fetching page $page: $e');
        break;
      }
    }

    if (allRows.isEmpty) {
      throw Exception('No data available for this date');
    }

    onProgress?.call(0.8);

    // Create CSV content
    final StringBuffer csv = StringBuffer();
    csv.writeln(headers.join(','));
    for (final row in allRows) {
      final values = headers.map((h) => row[h]?.toString() ?? '').toList();
      csv.writeln(values.join(','));
    }

    // Save to file
    final downloadsDir = await _getDownloadsDirectory();
    final filePath =
        '${downloadsDir.path}/${filePrefix}_${dateStr}_$devcode.csv';
    final file = File(filePath);
    await file.writeAsString(csv.toString());

    onProgress?.call(1.0);

    print('ReportDownloadService: Device report saved to $filePath');
    return filePath;
  }

  // (No weekly export supported by legacy exportCollectorsData)
}
