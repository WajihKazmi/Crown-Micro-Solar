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
    final data = json['dat'] ?? json;
    return AuthResponse(
      token: data['Token'],
      secret: data['Secret'],
      userId: data['UserID']?.toString(),
      description: data['Description'],
      agentsList: data['Agentslist'],
      isSuccess: data['Description'] == 'Success' || data['Description'] == 'success',
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