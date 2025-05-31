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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crown Micro Solar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: AppLocalizations.defaultLocale,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.createAccount: (context) => const CreateAccountScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.verification: (context) => const VerificationScreen(),
        AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
        AppRoutes.changeUserId: (context) => const ChangeUserIdScreen(),
        AppRoutes.register: (context) => const RegistrationScreen(),
        // Add other routes here as they are implemented
      },
    );
  }
}
