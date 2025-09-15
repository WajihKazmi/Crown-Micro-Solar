import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;

class L10nConfig {
  static const localizationsDelegates = [
    gen.AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static List<Locale> get supportedLocales =>
      gen.AppLocalizations.supportedLocales;
}
