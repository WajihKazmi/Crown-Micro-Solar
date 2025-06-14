class AuthResponse {
  final String? token;
  final String? secret;
  final String? userId;
  final String? description;
  final List<dynamic>? agentsList;
  final bool isSuccess;

  AuthResponse({
    this.token,
    this.secret,
    this.userId,
    this.description,
    this.agentsList,
    this.isSuccess = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['Token'],
      secret: json['Secret'],
      userId: json['UserID']?.toString(),
      description: json['Description'],
      agentsList: json['Agentslist'],
      isSuccess: json['Description'] == 'Success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Token': token,
      'Secret': secret,
      'UserID': userId,
      'Description': description,
      'Agentslist': agentsList,
    };
  }
} 