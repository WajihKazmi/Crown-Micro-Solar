import 'package:flutter/material.dart';
import 'package:mrc/model/token_model.dart';
import 'package:mrc/respository/auth/verify_otp_repository.dart';
import 'package:mrc/utils/utils.dart';
import 'package:mrc/view_model/services/token_view_model.dart';
import '/data/response/api_response.dart';
import '/resource/app_navigator.dart';
import '/utils/routes/routes_name.dart';
import 'package:provider/provider.dart';

class VerifyOtpViewModel with ChangeNotifier {
  final verifyOtpRepository = VerifyOtpRepository();
  final formKey = GlobalKey<FormState>();
  final Utils utils = Utils();
  final List<TextEditingController> otpControllers =
      List.generate(4, (index) => TextEditingController());

  bool _verifyOtpLoading = false;
  bool get verifyOtpLoading => _verifyOtpLoading;

  setverifyOtpLoading(bool value) {
    _verifyOtpLoading = value;
    notifyListeners();
  }

  String? otpValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP field should not be empty';
    }
    return null;
  }

  Future<void> verifyOtpApi(BuildContext context, String email) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    String otp = otpControllers.map((controller) => controller.text).join();
    dynamic data = {
      'email': email,
      'token': otp,
    };
    setverifyOtpLoading(true);

    try {
      final response = await verifyOtpRepository.verifyOtpApi(data);

      setverifyOtpLoading(false);
      if (response['data'] != null) {
        Navigator.of(context).pushNamed(RoutesName.forgotPassword);
        for (TextEditingController controller in otpControllers) {
          controller.clear();
        }
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
        utils.errorSnackbar(errorMessage, context);

        for (TextEditingController controller in otpControllers) {
          controller.dispose();
        }
      } else {
        utils.errorSnackbar(
            'An unexpected error occurred. Please try again later.', context);
        for (TextEditingController controller in otpControllers) {
          controller.dispose();
        }
      }
    } catch (error) {
      print('Error: $error');
      utils.errorSnackbar(
          'An unexpected error occurred. Please try again later.', context);
      for (TextEditingController controller in otpControllers) {
        controller.dispose();
      }
      setverifyOtpLoading(false);
    }
  }
}
