import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:crown_micro_solar/core/theme/app_theme.dart';
import 'package:crown_micro_solar/core/network/api_service.dart';
import 'package:crown_micro_solar/presentation/repositories/auth_repository.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/core/config/app_config.dart';
import 'package:crown_micro_solar/view/auth/login_screen.dart';
import 'package:crown_micro_solar/localization/app_localizations.dart';
import 'package:crown_micro_solar/core/utils/navigation_service.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';

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

    // Start real-time data service if user is logged in
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      final realtimeService = getIt<RealtimeDataService>();
      realtimeService.start();
    }

    // Initialize API Service
    final apiService = ApiService();

    // Initialize AuthRepository with both dependencies
    final authRepository = AuthRepository(apiService, prefs);

    runApp(MyApp(authRepository: authRepository));
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
  Locale _locale = AppLocalizations.defaultLocale;
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({Key? key, required this.authRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey, // Use global navigator key
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.lightTheme,
            initialRoute: AppRoutes.login,
            routes: AppRoutes.routes,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          );
        },
      ),
    );
  }
}
