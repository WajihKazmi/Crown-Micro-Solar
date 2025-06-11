import 'package:crown_micro_solar/view/auth/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:crown_micro_solar/view/splash/splash_screen.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:crown_micro_solar/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:crown_micro_solar/core/theme/app_theme.dart';
import 'package:crown_micro_solar/view/onboarding/onboarding_screen.dart';
import 'package:crown_micro_solar/view/auth/create_account_screen.dart';
import 'package:crown_micro_solar/view/auth/login_screen.dart';
import 'package:crown_micro_solar/view/auth/forgot_password_screen.dart';
import 'package:crown_micro_solar/view/auth/verification_screen.dart';
import 'package:crown_micro_solar/view/auth/reset_password_screen.dart';
import 'package:crown_micro_solar/view/auth/change_user_id_screen.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/energy_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => serviceLocator<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<PlantViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<DeviceViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<EnergyViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<AlarmViewModel>()),
      ],
      child: MaterialApp(
        title: 'Crown Micro Solar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: AppLocalizations.defaultLocale,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
