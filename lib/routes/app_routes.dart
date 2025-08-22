import 'package:flutter/material.dart';
import '../view/splash/splash_screen.dart';
import '../view/onboarding/onboarding_screen.dart';
import '../view/auth/login_screen.dart';
import '../view/auth/create_account_screen.dart';
import '../view/home/home_screen.dart';
import '../view/auth/forgot_password_screen.dart';
import '../view/auth/verification_screen.dart';
import '../view/auth/reset_password_screen.dart';
import '../view/auth/change_user_id_screen.dart';
import '../view/auth/registration_screen.dart';
import '../view/about/about_screen.dart';
import '../view/profile/account_info_screen.dart';
import '../view/support/whatsapp_screen.dart';

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
  static const String about = '/about';
  static const String accountInfo = '/accountInfo';
  static const String whatsapp = '/whatsapp';
  // Internal route for directly landing on the home screen after splash auto-login
  static const String homeInternal = '/home_internal';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        homeInternal: (context) => const HomeScreen(),
        createAccount: (context) => const CreateAccountScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        verification: (context) => const VerificationScreen(),
        resetPassword: (context) => const ResetPasswordScreen(),
        changeUserId: (context) => const ChangeUserIdScreen(),
        registration: (context) => const RegistrationScreen(),
        about: (context) => const AboutScreen(),
        accountInfo: (context) => const AccountInfoScreen(),
        whatsapp: (context) => const WhatsAppSupportScreen(),
      };
}
