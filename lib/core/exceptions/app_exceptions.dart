// Base exception class
import '../constants/firebase_constants.dart';

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() => '${runtimeType}: $message${code != null ? ' (Code: $code)' : ''}';
}

// Auth exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class SignInException extends AuthException {
  const SignInException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class SignUpException extends AuthException {
  const SignUpException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class PasswordResetException extends AuthException {
  const PasswordResetException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// API exceptions
class ApiException extends AppException {
  const ApiException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class NetworkException extends ApiException {
  const NetworkException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class TimeoutException extends ApiException {
  const TimeoutException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class ServerException extends ApiException {
  const ServerException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}



// Cache exceptions
class CacheException extends AppException {
  const CacheException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class InvalidResponseException extends ApiException {
  const InvalidResponseException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class DeviceNotFoundException extends DatabaseException {
  const DeviceNotFoundException(String deviceId, {StackTrace? stackTrace})
      : super('Device $deviceId not found', code: 'device_not_found', stackTrace: stackTrace);
}

class DataSaveException extends DatabaseException {
  const DataSaveException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Storage exceptions
class StorageException extends AppException {
  const StorageException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class FileTooLargeException extends StorageException {
  const FileTooLargeException(int maxSize, {StackTrace? stackTrace})
      : super('File exceeds maximum size of ${maxSize}MB',
      code: 'file_too_large', stackTrace: stackTrace);
}

class UploadFailedException extends StorageException {
  const UploadFailedException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Image exceptions
class ImagePickerException extends AppException {
  const ImagePickerException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class ImageCropperException extends AppException {
  const ImageCropperException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Device exceptions
class DeviceException extends AppException {
  const DeviceException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class DeviceOfflineException extends DeviceException {
  const DeviceOfflineException(String deviceId, {StackTrace? stackTrace})
      : super('Device $deviceId is offline',
      code: 'device_offline', stackTrace: stackTrace);
}

class DeviceConnectionException extends DeviceException {
  const DeviceConnectionException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Sensor exceptions
class SensorException extends AppException {
  const SensorException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

class SensorReadException extends SensorException {
  const SensorReadException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code, stackTrace: stackTrace);
}

// Helper function to handle Firebase auth errors
String getAuthErrorMessage(String errorCode) {
  switch (errorCode) {
    case FirebaseConstants.errorUserNotFound:
      return 'Aucun compte trouvé avec cet email';
    case FirebaseConstants.errorWrongPassword:
      return 'Mot de passe incorrect';
    case FirebaseConstants.errorEmailInUse:
      return 'Cet email est déjà utilisé';
    case FirebaseConstants.errorInvalidEmail:
      return 'Format d\'email invalide';
    case FirebaseConstants.errorWeakPassword:
      return 'Le mot de passe doit contenir au moins 6 caractères';
    case FirebaseConstants.errorNetworkFailed:
      return 'Erreur réseau. Vérifiez votre connexion internet';
    default:
      return 'Une erreur est survenue. Veuillez réessayer';
  }
}