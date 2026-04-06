/// Base exception class for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppException: $message';
}

/// Generic exception for unexpected errors
class GenericException extends AppException {
  const GenericException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String timeoutCode = 'NETWORK_TIMEOUT';
  static const String connectionCode = 'NO_CONNECTION';
  static const String serverCode = 'SERVER_ERROR';
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String invalidCredentialsCode = 'INVALID_CREDENTIALS';
  static const String userNotFoundCode = 'USER_NOT_FOUND';
  static const String emailAlreadyInUseCode = 'EMAIL_ALREADY_IN_USE';
  static const String weakPasswordCode = 'WEAK_PASSWORD';
  static const String accountExistsCode = 'ACCOUNT_EXISTS';
  static const String invalidEmailCode = 'INVALID_EMAIL';
  static const String userDisabledCode = 'USER_DISABLED';
  static const String tooManyRequestsCode = 'TOO_MANY_REQUESTS';
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String invalidEmailCode = 'INVALID_EMAIL';
  static const String invalidPasswordCode = 'INVALID_PASSWORD';
  static const String invalidUsernameCode = 'INVALID_USERNAME';
  static const String invalidPhoneCode = 'INVALID_PHONE';
  static const String fieldRequiredCode = 'FIELD_REQUIRED';
  static const String tooLongCode = 'TOO_LONG';
  static const String tooShortCode = 'TOO_SHORT';
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String cameraDeniedCode = 'CAMERA_DENIED';
  static const String galleryDeniedCode = 'GALLERY_DENIED';
  static const String microphoneDeniedCode = 'MICROPHONE_DENIED';
  static const String locationDeniedCode = 'LOCATION_DENIED';
  static const String permanentlyDeniedCode = 'PERMANENTLY_DENIED';
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String uploadFailedCode = 'UPLOAD_FAILED';
  static const String downloadFailedCode = 'DOWNLOAD_FAILED';
  static const String fileNotFoundCode = 'FILE_NOT_FOUND';
  static const String fileSizeExceededCode = 'FILE_SIZE_EXCEEDED';
  static const String invalidFormatCode = 'INVALID_FORMAT';
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String documentNotFoundCode = 'DOCUMENT_NOT_FOUND';
  static const String permissionDeniedCode = 'PERMISSION_DENIED';
  static const String transactionFailedCode = 'TRANSACTION_FAILED';
  static const String queryFailedCode = 'QUERY_FAILED';
}

/// Business logic exceptions
class BusinessException extends AppException {
  const BusinessException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String userNotFoundCode = 'USER_NOT_FOUND';
  static const String postNotFoundCode = 'POST_NOT_FOUND';
  static const String alreadyFollowingCode = 'ALREADY_FOLLOWING';
  static const String notFollowingCode = 'NOT_FOLLOWING';
  static const String selfFollowCode = 'SELF_FOLLOW';
  static const String rateLimitCode = 'RATE_LIMIT';
  static const String verificationRequiredCode = 'VERIFICATION_REQUIRED';
}

/// Utility functions for converting exceptions to user-friendly messages
String getExceptionMessage(Exception exception) {
  if (exception is AppException) {
    return exception.message;
  }
  
  // Handle Firebase exceptions
  final exceptionString = exception.toString();
  
  // Network errors
  if (exceptionString.contains('network') || 
      exceptionString.contains('connection') ||
      exceptionString.contains('host') ||
      exceptionString.contains('timeout')) {
    return 'Please check your internet connection and try again.';
  }
  
  // Authentication errors
  if (exceptionString.contains('user-not-found') ||
      exceptionString.contains('invalid-email') ||
      exceptionString.contains('wrong-password')) {
    return 'Invalid email or password. Please try again.';
  }
  
  if (exceptionString.contains('email-already-in-use')) {
    return 'This email is already registered. Please use a different email.';
  }
  
  if (exceptionString.contains('weak-password')) {
    return 'Password is too weak. Please choose a stronger password.';
  }
  
  // Permission errors
  if (exceptionString.contains('permission') ||
      exceptionString.contains('denied') ||
      exceptionString.contains('permanently')) {
    return 'Permission denied. Please check your app settings.';
  }
  
  // Storage errors
  if (exceptionString.contains('storage') ||
      exceptionString.contains('upload') ||
      exceptionString.contains('file')) {
    return 'File upload failed. Please try again.';
  }
  
  // Default error
  return 'Something went wrong. Please try again.';
}

/// Utility function to create appropriate exception from error
AppException createAppException(dynamic error, [String? defaultMessage]) {
  final errorString = error.toString();
  
  // Network errors
  if (errorString.contains('network') || 
      errorString.contains('connection') ||
      errorString.contains('host')) {
    return const NetworkException('Network connection error');
  }
  
  if (errorString.contains('timeout')) {
    return const NetworkException('Request timed out', code: NetworkException.timeoutCode);
  }
  
  // Authentication errors
  if (errorString.contains('user-not-found')) {
    return const AuthException('User not found', code: AuthException.userNotFoundCode);
  }
  
  if (errorString.contains('invalid-email')) {
    return const AuthException('Invalid email address', code: AuthException.invalidEmailCode);
  }
  
  if (errorString.contains('wrong-password')) {
    return const AuthException('Invalid password', code: AuthException.invalidCredentialsCode);
  }
  
  if (errorString.contains('email-already-in-use')) {
    return const AuthException('Email already in use', code: AuthException.emailAlreadyInUseCode);
  }
  
  if (errorString.contains('weak-password')) {
    return const AuthException('Password is too weak', code: AuthException.weakPasswordCode);
  }
  
  // Permission errors
  if (errorString.contains('permission') || errorString.contains('denied')) {
    return const PermissionException('Permission denied', code: PermissionException.permanentlyDeniedCode);
  }
  
  // Storage errors
  if (errorString.contains('storage') || errorString.contains('upload')) {
    return const StorageException('Storage operation failed', code: StorageException.uploadFailedCode);
  }
  
  // Default
  return GenericException(defaultMessage ?? 'An unexpected error occurred', originalError: error);
}
