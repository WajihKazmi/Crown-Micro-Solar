class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
} 