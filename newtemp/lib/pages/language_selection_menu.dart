import 'package:crownmonitor/pages/interfacetheme/interfacetheme.dart';
import 'package:crownmonitor/pages/login.dart';
import 'package:crownmonitor/pages/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelectionMenuPage extends StatefulWidget {
  @override
  _LanguageSelectionMenuPageState createState() => _LanguageSelectionMenuPageState();
}

class _LanguageSelectionMenuPageState extends State<LanguageSelectionMenuPage> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
     
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.select_language,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            languageButton(AppLocalizations.of(context)!.english, FlagsCode.US, 'en', context),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.russian, FlagsCode.RU, 'ru', context),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.arabic, FlagsCode.SA, 'ar', context),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.french, FlagsCode.FR, 'fr', context),
             SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.spanish, FlagsCode.ES, 'es', context),
          ],
        ),
      ),
    );
  }

  Widget languageButton(String language, FlagsCode countryCode, String locale, ctx) {

    final themeNotifier = Provider.of<ThemeNotifier>(ctx);

    return ElevatedButton(
      onPressed: () async {
        setState(() {
          selectedLanguage = language;
        });
        // You can add code here to handle language selection, e.g., update locale.

        themeNotifier.updateLocale(Locale(locale));

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('languageSelected', true);
        await prefs.setString('locale', locale);

        // Navigate to the login page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedLanguage == language ? Colors.green : Colors.grey,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flag.fromCode(countryCode, height: 20, width: 30),
          SizedBox(width: 10),
          Text(
            language,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
