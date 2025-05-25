import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Themes {
  static ThemeData lightThemeData() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffDFAD39),
        primary: const Color(0xffDFAD39),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xffEFEFEF),
        onPrimaryContainer: const Color(0xff212121),
        surface: Colors.white,
        onSurface: const Color(0xff212121),
        outline: const Color(0xff212121),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400),
        labelSmall: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w400),
      ));
}
