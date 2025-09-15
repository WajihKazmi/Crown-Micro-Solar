import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Legacy placeholder; kept to avoid breaking imports elsewhere. Do not use.
class OldAppLocalizations {
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('zh'), // Chinese
    Locale('ja'), // Japanese
    Locale('ar'), // Arabic
  ];

  static const Locale defaultLocale = Locale('en');
}
