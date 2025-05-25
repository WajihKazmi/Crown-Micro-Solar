import 'package:flutter/material.dart';
import 'package:mrc/model/token_model.dart';
import 'package:mrc/respository/auth/send_otp_repository.dart';
import 'package:mrc/utils/utils.dart';
import 'package:mrc/view_model/services/token_view_model.dart';
import '/data/response/api_response.dart';
import '/resource/app_navigator.dart';
import '/utils/routes/routes_name.dart';
import 'package:provider/provider.dart';

class SendOtpViewModel with ChangeNotifier {
  final sendOtpRepository = SendOtpRepository();
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final Utils utils = Utils();
  bool _sendOtpLoading = false;
  bool get sendOtpLoading => _sendOtpLoading;

  setSendOtpLoading(bool value) {
    _sendOtpLoading = value;
    notifyListeners();
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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

  Future<void> sendOtpApi(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setSendOtpLoading(true);
    dynamic data = {
      'email': emailController.text,
    };
    try {
      final response = await sendOtpRepository.sendOtpApi(data);

      setSendOtpLoading(false);
      if (response['data'] != null) {
        AppNavigator.pushNamed(context, RoutesName.verifyOtp,
            arguments: emailController.text);
      } else if (response['error'] != null) {
        String errorMessage = response['error'].toString();

        if (errorMessage.contains('message')) {
          int startIndex = errorMessage.indexOf('"message":');
          int endIndex = errorMessage.indexOf('"}', startIndex);
          String messageContent =
              errorMessage.substring(startIndex + 11, endIndex);
          errorMessage = messageContent;
        }
        print(errorMessage);
        emailController.clear();
        utils.errorSnackbar(errorMessage, context);
      } else {
        emailController.clear();
        utils.errorSnackbar(
            'An unexpected error occurred. Please try again later.', context);
      }
    } catch (error) {
      emailController.clear();
      print('Error: $error');
      utils.errorSnackbar(
          'An unexpected error occurred. Please try again later.', context);
      setSendOtpLoading(false);
    }
  }
}
