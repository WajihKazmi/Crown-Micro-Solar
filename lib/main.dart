import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:crown_micro_solar/core/network/api_service.dart';
import 'package:crown_micro_solar/presentation/repositories/auth_repository.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/core/config/app_config.dart';
import 'package:crown_micro_solar/localization/l10n.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;
import 'package:crown_micro_solar/core/utils/navigation_service.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/core/theme/theme_notifier.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize services
    await setupServiceLocator();

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // DEFER real-time data service start until after first frame to speed up app launch
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final realtimeService = getIt<RealtimeDataService>();
        realtimeService.start();
      });
    }

    // Initialize API Service
    final apiService = ApiService();

    // Initialize AuthRepository with both dependencies
    final authRepository = AuthRepository(apiService, prefs);

    final themeNotifier = await ThemeNotifier.loadFromPrefs();
    runApp(MyApp(authRepository: authRepository, themeNotifier: themeNotifier));
  } catch (e, stack) {
    print('Error during initialization: $e');
    print('Stack trace: $stack');
    // Show error UI or handle initialization failure
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class LocaleProvider extends ChangeNotifier {
  // Default to English explicitly
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!gen.AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    _persistLocale(locale);
    notifyListeners();
  }

  static const _localeKey = 'app_locale_code';

  static Future<LocaleProvider> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    // Use saved locale if valid; otherwise prefer device locale if supported
    Locale? locale;
    if (code != null) {
      final saved = Locale(code);
      if (gen.AppLocalizations.supportedLocales.contains(saved)) {
        locale = saved;
      }
    }
    locale ??= () {
      final device = WidgetsBinding.instance.platformDispatcher.locale;
      for (final s in gen.AppLocalizations.supportedLocales) {
        if (s.languageCode == device.languageCode) return s;
      }
      return const Locale('en');
    }();
    final provider = LocaleProvider();
    provider._locale = locale;
    return provider;
  }

  Future<void> _persistLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ThemeNotifier themeNotifier;

  const MyApp(
      {Key? key, required this.authRepository, required this.themeNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository),
        ),
        // Initialize locale provider synchronously with default, then restore from prefs
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) {
            final provider = LocaleProvider();
            // Fire-and-forget load persisted locale
            LocaleProvider.loadFromPrefs().then((loaded) {
              provider.setLocale(loaded.locale);
            });
            return provider;
          },
        ),
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
      ],
      child: Consumer2<LocaleProvider, ThemeNotifier>(
        builder: (context, localeProvider, themeNotifier, child) {
          return MaterialApp(
            navigatorKey:
                NavigationService.navigatorKey, // Use global navigator key
            title: AppConfig.appName,
            // Force light mode only per requirement: remove dark theme usage
            theme: themeNotifier.themeData,
            themeMode: ThemeMode.light,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            locale: localeProvider.locale,
            supportedLocales: L10nConfig.supportedLocales,
            localizationsDelegates: L10nConfig.localizationsDelegates,
            localeResolutionCallback: (device, supported) {
              if (device == null) return localeProvider.locale;
              for (final s in supported) {
                if (s.languageCode == device.languageCode) {
                  return s; // map ru_RU -> ru, etc.
                }
              }
              return localeProvider.locale;
            },
          );
        },
      ),
    );
  }
}
