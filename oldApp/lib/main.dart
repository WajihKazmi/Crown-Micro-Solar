import 'dart:async';

import 'package:crownmonitor/pages/interfacetheme/interfacetheme.dart';
import 'package:crownmonitor/pages/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  late ThemeData themeData = RedTheme;
  String _theme;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      await Firebase.initializeApp(
          options: FirebaseOptions(
        apiKey: 'AIzaSyCAGSVcKuJAgDOhRoeZFbiyCBr7qhWVIkQ',
        appId: '1:327645956118:android:4bbd314d81bde1f5480d37',
        messagingSenderId: '327645956118',
        projectId: 'crown-monitor-3fac0',
        storageBucket: 'crown-monitor-3fac0.appspot.com',
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
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    themeNotifier.getLanguage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crown Monitor',
      theme: themeNotifier.getTheme(),
      home: SplashScreen(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      locale: themeNotifier.currentLocale,
      supportedLocales: [
        Locale('en'),
        Locale('ru'),
        Locale('ar'),
        Locale('fr'),
        Locale('es'),
      ],
      builder: EasyLoading.init(),
    );
  }
}
