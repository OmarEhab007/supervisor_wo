/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Generic exception for unclassified errors
class GenericException extends AppException {
  const GenericException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String toString() =>
      'GenericException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for database-related errors
class DatabaseException extends AppException {
  const DatabaseException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String toString() =>
      'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for authentication-related errors
class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for network-related errors
class NetworkException extends AppException {
  final NetworkErrorType errorType;
  final bool isRetryable;
  
  const NetworkException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
    this.errorType = NetworkErrorType.unknown,
    this.isRetryable = true,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String toString() =>
      'NetworkException: $message${code != null ? ' (Code: $code)' : ''} [Type: $errorType, Retryable: $isRetryable]';

  /// Create a timeout exception
  factory NetworkException.timeout({String? context}) {
    return NetworkException(
      context != null 
          ? 'Request timeout: $context'
          : 'Request timed out. Please check your internet connection.',
      errorType: NetworkErrorType.timeout,
      isRetryable: true,
    );
  }

  /// Create a no internet exception
  factory NetworkException.noInternet({String? context}) {
    return NetworkException(
      context != null
          ? 'No internet connection: $context'
          : 'No internet connection. Please check your network settings.',
      errorType: NetworkErrorType.noInternet,
      isRetryable: true,
    );
  }

  /// Create a server error exception
  factory NetworkException.serverError({String? context, int? statusCode}) {
    return NetworkException(
      context != null
          ? 'Server error: $context${statusCode != null ? ' (Status: $statusCode)' : ''}'
          : 'Server error. Please try again later.',
      errorType: NetworkErrorType.serverError,
      isRetryable: statusCode != 400 && statusCode != 401 && statusCode != 403,
    );
  }

  /// Create a service unavailable exception
  factory NetworkException.serviceUnavailable({String? service}) {
    return NetworkException(
      service != null
          ? '$service is temporarily unavailable'
          : 'Service temporarily unavailable. Please try again later.',
      errorType: NetworkErrorType.serviceUnavailable,
      isRetryable: true,
    );
  }
}

/// Types of network errors
enum NetworkErrorType {
  unknown,
  noInternet,
  timeout,
  serverError,
  serviceUnavailable,
  connectionRefused,
  hostUnreachable,
}

/// Exception for validation-related errors
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Utility class for error handling
class ErrorHandler {
  /// Converts generic exceptions to specific AppException types
  static AppException convertException(dynamic error,
      [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Database-related errors
    if (errorString.contains('database') ||
        errorString.contains('supabase') ||
        errorString.contains('table') ||
        errorString.contains('column') ||
        errorString.contains('does not exist')) {
      return DatabaseException(
        'Database operation failed: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Authentication-related errors
    if (errorString.contains('auth') ||
        errorString.contains('login') ||
        errorString.contains('signin') ||
        errorString.contains('signup') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return AuthException(
        'Authentication failed: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Network-related errors with better classification
    if (errorString.contains('timeout') || 
        errorString.contains('timed out')) {
      return NetworkException.timeout(
        context: error.toString(),
      );
    }

    if (errorString.contains('no internet') ||
        errorString.contains('no network') ||
        errorString.contains('connectivity') ||
        errorString.contains('not connected')) {
      return NetworkException.noInternet(
        context: error.toString(),
      );
    }

    if (errorString.contains('connection refused') ||
        errorString.contains('connection denied')) {
      return NetworkException(
        'Connection refused: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
        errorType: NetworkErrorType.connectionRefused,
        isRetryable: true,
      );
    }

    if (errorString.contains('host unreachable') ||
        errorString.contains('no route to host')) {
      return NetworkException(
        'Host unreachable: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
        errorType: NetworkErrorType.hostUnreachable,
        isRetryable: true,
      );
    }

    if (errorString.contains('service unavailable') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return NetworkException.serviceUnavailable(
        service: error.toString(),
      );
    }

    if (errorString.contains('500') ||
        errorString.contains('internal server error') ||
        errorString.contains('server error')) {
      // Extract status code if available
      int? statusCode;
      final statusMatch = RegExp(r'status\s*:?\s*(\d{3})').firstMatch(errorString);
      if (statusMatch != null) {
        statusCode = int.tryParse(statusMatch.group(1) ?? '');
      }
      
      return NetworkException.serverError(
        context: error.toString(),
        statusCode: statusCode,
      );
    }

    // Generic network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('http')) {
      return NetworkException(
        'Network error: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
        errorType: NetworkErrorType.unknown,
        isRetryable: true,
      );
    }

    // Default to generic exception
    return GenericException(
      'An unexpected error occurred: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Safely executes a function and converts any errors to AppException
  static Future<T> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final convertedError = convertException(error, stackTrace);
      if (context != null) {
        throw GenericException(
          '$context: ${convertedError.message}',
          code: convertedError.code,
          originalError: convertedError.originalError,
          stackTrace: stackTrace,
        );
      }
      throw convertedError;
    }
  }
}
