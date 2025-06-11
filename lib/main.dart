import 'dart:async';

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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  late ThemeData themeData = RedTheme;
  String _theme;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      await Firebase.initializeApp(
          options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      ));

      final prefs = await SharedPreferences.getInstance();
      _theme = prefs.getString("theme").toString();
      if (_theme == 'RedTheme') {
        themeData = RedTheme;
      } else if (_theme == 'yellowtheme') {
        themeData = yellowTheme;
      } else if (_theme == 'greentheme') {
        themeData = greentheme;
      } else if (_theme == 'bluetheme') {
        themeData = blueTheme;
      } else {
        print('object');
        themeData = RedTheme;
      }
      runApp(
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(themeData),
          child: MyApp(),
        ),
      );
    },
    (error, st) => print(error),
  );
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
