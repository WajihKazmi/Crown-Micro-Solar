import '/data/network/BaseApiServices.dart';
import '/data/network/NetworkApiService.dart';
import '/resource/app_url.dart';

class ForgetEmailRepository {
  final BaseApiServices _apiServices = NetworkApiService();

  //   ***   this is Get api data   ***

  // Future<ForgetEmailModel> fetchForgetEmailApi() async {
  //   try {
  //     dynamic response =
  //         await _apiServices.getGetApiResponse(AppUrl.forget_email);
  //     return response = ForgetEmailModel.fromJson(response);
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  //   ***   this is Post api data   ***

  Future<dynamic> forget_emailApi(dynamic data) async {
    try {
      dynamic response =
          await _apiServices.getPostApiResponse(AppUrl.forgetEmail, data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
