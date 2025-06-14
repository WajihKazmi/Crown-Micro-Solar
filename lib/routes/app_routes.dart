import 'package:flutter/material.dart';
import '../view/splash/splash_screen.dart';
import '../view/onboarding/onboarding_screen.dart';
import '../view/auth/login_screen.dart';
import '../view/auth/create_account_screen.dart';
import '../view/auth/forgot_password_screen.dart';
import '../view/auth/verification_screen.dart';
import '../view/auth/reset_password_screen.dart';
import '../view/auth/change_user_id_screen.dart';
import '../view/auth/registration_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String resetPassword = '/reset-password';
  static const String changeUserId = '/change-user-id';
  static const String registration = '/registration';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    createAccount: (context) => const CreateAccountScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    verification: (context) => const VerificationScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    changeUserId: (context) => const ChangeUserIdScreen(),
    registration: (context) => const RegistrationScreen(),
  };
}
