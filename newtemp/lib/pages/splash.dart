import 'dart:convert';

import 'package:crownmonitor/pages/language_selection.dart';
import 'package:crownmonitor/pages/list.dart';
import 'package:crownmonitor/pages/login.dart';
import 'package:crownmonitor/pages/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen.withScreenFunction(
      duration: 2000,
      backgroundColor: Colors.white,
      splash: 'assets/logo.png',
      splashIconSize: 80,
      centered: true,
      screenFunction: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        bool languageSelected = prefs.getBool('languageSelected') ?? false;

        if (!languageSelected) {
          return LanguageSelectionPage();
        } else {
          return prefs.getBool('loggedin') == false || prefs.getBool('loggedin') == null
              ? LoginPage()
              : MainScreen();
        }
      },
      splashTransition: SplashTransition.scaleTransition,
      // pageTransitionType: PageTransitionType.scale,
    );
  }
}
