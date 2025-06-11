import 'package:dio/dio.dart';
import '../../models/account/account_info_model.dart';
import '../../../core/network/api_client.dart';

class AccountRepository {
  final ApiClient _apiClient;

  AccountRepository(this._apiClient);

  Future<AccountInfo> getAccountInfo() async {
    try {
      final response = await _apiClient.get('/account/info');
      return AccountInfo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get account info: ${e.message}');
    }
  }

  Future<void> updateAccountInfo(AccountInfo accountInfo) async {
    try {
      await _apiClient.put('/account/info', data: accountInfo.toJson());
    } on DioException catch (e) {
      throw Exception('Failed to update account info: ${e.message}');
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _apiClient.put('/account/preferences', data: preferences);
    } on DioException catch (e) {
      throw Exception('Failed to update preferences: ${e.message}');
    }
  }
} 