import 'package:flutter/material.dart';

// Define the primary color based on the screenshot (a shade of red/pink)
const Color customPrimaryColor = Color(0xFFEE3338);

// Create a MaterialColor from the custom primary color
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
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimaryColor,
        brightness: Brightness.light,
        primary: customPrimaryColor,
        // Use this color for elevated buttons, focused states, etc.
        primaryContainer: primaryRed[100], // A lighter shade for containers
        secondary:
            Colors.grey[300], // Assuming a light grey from the screenshot
        onSecondary: Colors.black87, // Text on secondary
        background: Colors.white, // White background from screenshot
        surface: Colors.white, // White surface for cards, etc.
        onPrimary: Colors.white, // Text color on primary (buttons)
        onBackground: Colors.black87, // Text color on background
        onSurface: Colors.black87, // Text color on surface
        error: Colors.redAccent, // Default error color
        onError: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: customPrimaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: customPrimaryColor, // Button background color
          foregroundColor: Colors.white, // Button text color
        ),
      ),
      // Add other theme customizations here based on your design
      // inputDecorationTheme: ...,
      // textTheme: ...,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimaryColor,
        brightness: Brightness.dark,
        primary: customPrimaryColor, // Use the custom color in dark mode too
        primaryContainer: primaryRed[900], // A darker shade for containers
        secondary: Colors.grey[700], // Assuming a dark grey
        onSecondary: Colors.white70, // Text on secondary
        background: Colors.black, // Black background for dark mode
        surface: Colors.grey[900], // Dark surface for cards, etc.
        onPrimary: Colors.white, // Text color on primary
        onBackground: Colors.white70, // Text color on background
        onSurface: Colors.white70, // Text color on surface
        error: Colors.redAccent, // Default error color
        onError: Colors.black,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: customPrimaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: customPrimaryColor, // Button background color
          foregroundColor: Colors.white, // Button text color
        ),
      ),
      // Add other dark theme customizations here based on your design
    );
  }
}
