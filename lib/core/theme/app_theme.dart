import 'package:flutter/material.dart';

// Base default primary color
// ignore: constant_identifier_names
const Color _BASE_PRIMARY = Color(0xFFEE3338);

// Material swatch (kept for potential uses like charts / shades)
const MaterialColor primaryRed = MaterialColor(
  0xFFEE3338,
  <int, Color>{
    50: Color(0xFFFDE5E6),
    100: Color(0xFFFBC0C2),
    200: Color(0xFFF99699),
    300: Color(0xFFF66C70),
    400: Color(0xFFF44F54),
    500: Color(0xFFEE3338),
    600: Color(0xFFE72D32),
    700: Color(0xFFDE252A),
    800: Color(0xFFD51D22),
    900: Color(0xFFC61217),
  },
);

class AppTheme {
  static const Color basePrimary = _BASE_PRIMARY;

  static ThemeData buildLightWithPrimary(Color primary) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          primaryContainer: primary.withOpacity(0.12),
          secondary: Colors.grey[300],
          onSecondary: Colors.black87,
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        fontFamily: 'Manrope',
      );

  static ThemeData get lightTheme => buildLightWithPrimary(basePrimary);

  // Dark theme kept (unused in picker now) so existing MaterialApp.darkTheme still valid.
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1D21),
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: basePrimary,
          onPrimary: Colors.white,
          secondary: const Color(0xFF262B30),
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          background: const Color(0xFF1A1D21),
          onBackground: Colors.white.withOpacity(0.95),
          surface: const Color(0xFF1F2428),
          onSurface: Colors.white.withOpacity(0.94),
          primaryContainer: const Color(0xFF45181A),
          onPrimaryContainer: Colors.white,
          secondaryContainer: const Color(0xFF2C3136),
          onSecondaryContainer: Colors.white,
          outline: Colors.white24,
          outlineVariant: Colors.white10,
          tertiary: basePrimary,
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFF30353A),
          onTertiaryContainer: Colors.white,
          surfaceVariant: const Color(0xFF252A2F),
          inverseSurface: Colors.white,
          inversePrimary: primaryRed[100]!,
          shadow: Colors.black,
          scrim: Colors.black54,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1F2428),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: basePrimary,
            foregroundColor: Colors.white,
          ),
        ),
        cardColor: const Color(0xFF1F2428),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1F2428),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        fontFamily: 'Manrope',
      );
}
