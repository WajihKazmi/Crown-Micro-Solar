class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String createAccount = '/createAccount';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String solarSystem = '/solar-system';
  static const String monitoring = '/monitoring';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String forgotPassword = '/forgotPassword';
  static const String verification = '/verification';
  static const String resetPassword = '/resetPassword';
  static const String changeUserId = '/changeUserId';

  // Nested routes
  static const String solarSystemDetails = '/solar-system/:id';
  static const String monitoringDetails = '/monitoring/:id';
  static const String reportDetails = '/reports/:id';

  // Settings routes
  static const String accountSettings = '/settings/account';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String helpSettings = '/settings/help';

  // Error routes
  static const String error = '/error';
  static const String notFound = '/404';
}
