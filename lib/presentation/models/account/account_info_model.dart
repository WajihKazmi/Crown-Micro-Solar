class AccountInfo {
  final String userId;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String status;
  final DateTime lastLogin;
  final Map<String, dynamic> preferences;

  AccountInfo({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.lastLogin,
    required this.preferences,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      lastLogin: DateTime.parse(json['lastLogin'] ?? DateTime.now().toIso8601String()),
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'lastLogin': lastLogin.toIso8601String(),
      'preferences': preferences,
    };
  }
} 