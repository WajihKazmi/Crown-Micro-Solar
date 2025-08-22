import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Crown Micro Solar';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  // Debug Configuration
  static bool get isDebugMode => kDebugMode;

  // Platform Configuration
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;

  // Support configuration
  // E.164 phone without '+' for wa.me
  static const String supportWhatsAppNumber = '15551234567';
  static const String supportWhatsAppMessage =
      'Hello, I need help with Crown Micro Solar.';

  // static Future<void> initialize() async {
  //   await dotenv.load(fileName: ".env");
  //   await Firebase.initializeApp(
  //     options: FirebaseOptions(
  //       apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
  //       appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
  //       messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
  //       projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
  //       storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
  //     ),
  //   );
  // }
}
