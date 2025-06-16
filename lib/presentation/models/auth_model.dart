class AuthModel {
  final String userId;
  final String password;
  final bool isInstallerMode;

  AuthModel({
    required this.userId,
    required this.password,
    this.isInstallerMode = false,
  });
}

class LoginResponse {
  final bool success;
  final String? message;
  final LoginData? data;

  LoginResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String token;
  final String userId;
  final String name;
  final String role;

  LoginData({
    required this.token,
    required this.userId,
    required this.name,
    required this.role,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }
} 