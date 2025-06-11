class AuthResponse {
  final bool success;
  final String? token;
  final String? secret;
  final String? message;
  final String? userId;
  final String? email;

  AuthResponse({
    required this.success,
    this.token,
    this.secret,
    this.message,
    this.userId,
    this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      secret: json['secret'],
      message: json['message'],
      userId: json['userId'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'secret': secret,
      'message': message,
      'userId': userId,
      'email': email,
    };
  }
} 