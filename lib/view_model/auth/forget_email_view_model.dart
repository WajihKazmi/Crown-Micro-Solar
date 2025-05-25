import 'package:flutter/material.dart';
import 'package:mrc/model/token_model.dart';
import 'package:mrc/respository/auth/forget_email_repository.dart';
import 'package:mrc/view_model/services/token_view_model.dart';
import '/data/response/api_response.dart';
import '/resource/app_navigator.dart';
import '/utils/routes/routes_name.dart';
import 'package:provider/provider.dart';

class ForgetEmailViewModel with ChangeNotifier {
  final forget_emailRepository = ForgetEmailRepository();

  //   ***   this is Get api data   ***

  // ApiResponse<ForgetEmailModel> forget_emailModel = ApiResponse.loading();

  // setForgetEmail(ApiResponse<ForgetEmailModel> response) {
  //   forget_emailModel = response;
  //   notifyListeners();
  // }

  // Future<void> fetchForgetEmailApi() async {
  //   setForgetEmail(ApiResponse.loading());

  //   forget_emailRepository.fetchForgetEmailApi().then((value) {
  //     setForgetEmail(ApiResponse.completed(value));
  //   }).onError((error, stackTrace) {
  //     setForgetEmail(ApiResponse.error(error.toString()));
  //   });
  // }

  // ***   this is Post api data   ***

  bool _forget_emailLoading = false;
  bool get forget_emailLoading => _forget_emailLoading;

  setForgetEmailLoading(bool value) {
    _forget_emailLoading = value;
    notifyListeners();
  }

  Future<void> forget_emailApi(dynamic data, BuildContext context) async {
    setForgetEmailLoading(true);

    forget_emailRepository.forget_emailApi(data).then((value) {
      setForgetEmailLoading(false);
      final tokenPreference =
          Provider.of<TokenViewModel>(context, listen: false);
      tokenPreference.saveToken(TokenModel(token: value['token'].toString()));
      AppNavigator.pushNamed(context, RoutesName.home);
    }).onError((error, stackTrace) {
      setForgetEmailLoading(false);
    });
  }
}
