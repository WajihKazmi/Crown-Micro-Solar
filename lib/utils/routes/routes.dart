import 'package:mrc/view/auth/forgot_password_view.dart';
import 'package:mrc/view/auth/verify_otp_view.dart';

import '/view/privacy_policy_view.dart';
import '/view/faqs_view.dart';
import 'package:flutter/material.dart';
import 'package:mrc/view/auth/send_otp_view.dart';
import 'package:mrc/view/auth/login_and_signup_button_view.dart';
import 'package:mrc/view/auth/login_view.dart';
import 'package:mrc/view/auth/sign_up_view.dart';
import 'package:mrc/view/bottom_nav_views.dart';
import 'package:mrc/view/change_password_view.dart';
import 'package:mrc/view/detail_important_resources_view.dart';
import 'package:mrc/view/home_view.dart';
import 'package:mrc/view/important_resources_view.dart';
import 'package:mrc/view/message_view.dart';
import 'package:mrc/view/notification_view.dart';
import 'package:mrc/view/profile_view.dart';
import '/utils/routes/routes_name.dart';
import '/view/splash_view.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    PageRoute pageRoute = PageRoute();
    switch (settings.name) {
      case RoutesName.splash:
        return pageRoute.getPageRoute(const SplashView());
      case RoutesName.loginAndSignupButtonView:
        return pageRoute.getPageRoute(const LoginAndSignupButtonView());
      case RoutesName.login:
        return pageRoute.getPageRoute(const LoginView());
      case RoutesName.signUp:
        return pageRoute.getPageRoute(const SignUpView());
      case RoutesName.verifyOtp:
        return pageRoute.getPageRoute(VerifyOtpView(
          email: settings.arguments as String,
        ));
      case RoutesName.sendOtp:
        return pageRoute.getPageRoute(const SendOtpView());
      case RoutesName.forgotPassword:
        return pageRoute.getPageRoute(const ForgotPasswordView());
      case RoutesName.bottomNav:
        return pageRoute.getPageRoute(const BottomNavView());
      case RoutesName.home:
        return pageRoute.getPageRoute(const HomeView());
      case RoutesName.importantResourcesView:
        return pageRoute.getPageRoute(ImportantResourcesView(
          name: settings.arguments as Map,
        ));
      case RoutesName.detailImportantResources:
        return pageRoute.getPageRoute(DetailImportantResourcesView(
          name: settings.arguments as Map,
        ));
      case RoutesName.notification:
        return pageRoute.getPageRoute(const NotificationView());
      case RoutesName.profileView:
        return pageRoute.getPageRoute(const ProfileView());
      case RoutesName.changePassword:
        return pageRoute.getPageRoute(const ChangePasswordView());
      case RoutesName.message:
        return pageRoute.getPageRoute(const MessageView());

      case RoutesName.faqs:
        return pageRoute.getPageRoute(const FaqsView());

      case RoutesName.privacy_policy:
        return pageRoute.getPageRoute(const PrivacyPolicyView());
      default:
        return pageRoute.getDefaultRoute();
    }
  }
}

class PageRoute extends DefaultPageRoute {
  Route getPageRoute(page) => MaterialPageRoute(
        builder: (BuildContext context) => page,
      );
}

class DefaultPageRoute {
  Route getDefaultRoute() => MaterialPageRoute(builder: (_) {
        return const Scaffold(
          body: Center(
            child: Text('No route defined'),
          ),
        );
      });
}
