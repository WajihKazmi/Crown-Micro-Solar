import 'package:dio/dio.dart';
import '../../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return handler.reject(
          NetworkException(
            message: 'Connection timeout',
            originalError: err,
          ) as DioException,
        );
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message =
            err.response?.data['message'] ?? 'Unknown error occurred';

        if (statusCode == 401) {
          return handler.reject(
            AuthException(
              message: 'Unauthorized',
              code: statusCode.toString(),
              originalError: err,
            ) as DioException,
          );
        }

        return handler.reject(
          NetworkException(
            message: message,
            code: statusCode.toString(),
            originalError: err,
          ) as DioException,
        );
      case DioExceptionType.cancel:
        return handler.reject(
          NetworkException(
            message: 'Request cancelled',
            originalError: err,
          ) as DioException,
        );
      default:
        return handler.reject(
          NetworkException(
            message: 'Network error occurred',
            originalError: err,
          ) as DioException,
        );
    }
  }
}
