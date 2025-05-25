import 'package:flutter/material.dart';
import 'package:mrc/model/token_model.dart';
import 'package:mrc/respository/auth/sign_up_repository.dart';
import 'package:mrc/utils/utils.dart';
import 'package:mrc/view_model/services/token_view_model.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:provider/provider.dart';

class SignUpViewModel with ChangeNotifier {
  final signUpRepository = SignUpRepository();

  TextEditingController nameFirstController = TextEditingController();
  TextEditingController nameLastController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  TextEditingController interestsController = TextEditingController();
  Utils utils = Utils();
  final formKey = GlobalKey<FormState>();

  bool _signUpLoading = false;
  bool get signUpLoading => _signUpLoading;
  void disposeFields() {
    nameFirstController.clear();
    nameLastController.clear();
    genderController.clear();
    dobController.clear();
    numberController.clear();
    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
    interestsController.clear();
  }

  setSignUpLoading(bool value) {
    _signUpLoading = value;
    notifyListeners();
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name.';
    }
    return null;
  }

  String? numberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number.';
    }
    if (value.length < 8) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  String? genderValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a gender.';
    }
    return null;
  }

  String? dateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please Select your date of birth.';
    }

    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    if (!validateEmail(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value != passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? interestsValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your interests.';
    }
    return null;
  }

  Future<void> signUpApi(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> data = {
      'firstName': nameFirstController.text,
      'lastName': nameLastController.text,
      'dateOfBirth': dobController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'interest': interestsController.text,
      'phone': numberController.text,
      'gender': genderController.text,
    };

    setSignUpLoading(true);

    try {
      final response = await signUpRepository.signUpApi(data);

      setSignUpLoading(false);

      if (response['data'] != null && response['data']["token"] != null) {
        final tokenPreference =
            Provider.of<TokenViewModel>(context, listen: false);
        tokenPreference.saveToken(TokenModel(token: response['data']['token']));
        Navigator.pushNamed(context, RoutesName.home);
      } else if (response['error'] != null) {
        String errorMessage = response['error'].toString();

        if (errorMessage.contains('message')) {
          int startIndex = errorMessage.indexOf('"message":');
          int endIndex = errorMessage.indexOf('"}', startIndex);
          String messageContent =
              errorMessage.substring(startIndex + 11, endIndex);
          errorMessage = messageContent;
        }

        // Clear any previous errors
        // nameFirstController.clear();
        // nameLastController.clear();
        // genderController.clear();
        // dobController.clear();
        // emailController.clear();
        // passwordController.clear();
        // passwordConfirmController.clear();
        // interestsController.clear();
        print(errorMessage);
        // Display error message
        utils.errorSnackbar(errorMessage, context);
      } else {
        utils.errorSnackbar(
            'An unexpected error occurred. Please try again later.', context);
      }
    } catch (error) {
      print('Error: $error');
      utils.errorSnackbar(
          'An unexpected error occurred. Please try again later.', context);
      setSignUpLoading(false);
    }
  }
}
