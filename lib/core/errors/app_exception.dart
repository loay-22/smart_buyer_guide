abstract class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code})
      : super(message: message, code: code);
}

class ApiException extends AppException {
  const ApiException(String message, {String? code})
      : super(message: message, code: code);
}

class InvalidJsonException extends AppException {
  const InvalidJsonException(String message, {String? code})
      : super(message: message, code: code);
}
