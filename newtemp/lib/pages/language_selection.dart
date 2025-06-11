import 'package:crownmonitor/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelectionPage extends StatefulWidget {
  @override
  _LanguageSelectionPageState createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
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
            languageButton(AppLocalizations.of(context)!.english, FlagsCode.US, 'en'),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.russian, FlagsCode.RU, 'ru'),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.arabic, FlagsCode.SR, 'ar'),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.french, FlagsCode.FR, 'fr'),
            SizedBox(height: 10),
            languageButton(AppLocalizations.of(context)!.spanish, FlagsCode.ES, 'es'),
          ],
        ),
      ),
    );
  }

  Widget languageButton(String language, FlagsCode countryCode, String locale) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          selectedLanguage = language;
        });
        // You can add code here to handle language selection, e.g., update locale.

        Locale(locale);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('languageSelected', true);
        await prefs.setString('locale', locale);

        // Navigate to the login page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
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
