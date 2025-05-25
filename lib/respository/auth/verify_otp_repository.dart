import '/data/network/BaseApiServices.dart';
import '/data/network/NetworkApiService.dart';
import '/resource/app_url.dart';

class VerifyOtpRepository {
  final BaseApiServices _apiServices = NetworkApiService();

  Future<dynamic> verifyOtpApi(dynamic data) async {
    try {
      dynamic response =
          await _apiServices.getPostApiResponse(AppUrl.verifyOtp, data);
      return {'data': response, 'error': null};
    } catch (e) {
      return {'data': null, 'error': e};
    }
  }
}
