import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mrc/model/token_model.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/respository/auth/login_repository.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:mrc/utils/utils.dart';
import 'package:mrc/view_model/services/token_view_model.dart';
import 'package:provider/provider.dart';

class LoginViewModel with ChangeNotifier {
  final loginRepository = LoginRepository();
  final Utils utils = Utils();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _loginLoading = false;
  bool get loginLoading => _loginLoading;
  void disposeFields() {
    emailController.clear();
    passwordController.clear();
  }

  setLoginLoading(bool value) {
    _loginLoading = value;
    notifyListeners();
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 6; // Updated to 8 characters
  }

  String? emailValidator(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!validateEmail(email)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  String? passwordValidator(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password.';
    }
    if (!validatePassword(password)) {
      return 'Password must be at least 8 characters long.';
    }
    return null;
  }

  Future<void> loginApi(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    String email = emailController.text;
    String password = passwordController.text;

    setLoginLoading(true);

    try {
      final response = await loginRepository.loginApi({
        'email': email,
        'password': password,
      });

      setLoginLoading(false);
      print(response);
      if (response['data'] != null &&
          response['data']["data"]['token'] != null) {
        final tokenPreference =
            Provider.of<TokenViewModel>(context, listen: false);
        tokenPreference.saveToken(TokenModel(token: response['data']['token']));
        AppNavigator.pushNamed(context, RoutesName.home);
      } else if (response['error'] != null) {
        String errorMessage = response['error'].toString();

        if (errorMessage.contains('message')) {
          int startIndex = errorMessage.indexOf('"message":');
          int endIndex = errorMessage.indexOf('"}', startIndex);
          String messageContent =
              errorMessage.substring(startIndex + 11, endIndex);
          errorMessage = messageContent;
        }

        if (errorMessage == "User not found") {
          emailController.clear();
          passwordController.clear();
        } else if (errorMessage == "Incorrect password") {
          passwordController.clear();
        }
        // Display generic error
        utils.errorSnackbar(errorMessage, context);
      } else {
        utils.errorSnackbar(
            'An unexpected error occurred. Please try again later.', context);
      }
    } catch (error) {
      print('Error: $error');
      utils.errorSnackbar(
          'An unexpected error occurred. Please try again later.', context);
      setLoginLoading(false);
    }
  }
}
