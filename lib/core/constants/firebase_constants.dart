class FirebaseConstants {
  // Collection names
  static const String collectionUsers = 'users';
  static const String collectionDevices = 'devices';
  static const String collectionSensorData = 'sensor_data';
  static const String collectionUserPreferences = 'user_preferences';
  static const String collectionNotifications = 'notifications';

  // Storage paths
  static const String storageProfileImages = 'profile_images';
  static const String storageDeviceImages = 'device_images';
  static const String storageAppData = 'app_data';

  // Document fields
  static const String fieldUserId = 'uid';
  static const String fieldEmail = 'email';
  static const String fieldName = 'name';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldLastLogin = 'lastLogin';
  static const String fieldDeviceIds = 'deviceIds';
  static const String fieldIsOnline = 'isOnline';
  static const String fieldLastSeen = 'lastSeen';
  static const String fieldThreshold = 'threshold';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldLightPercentage = 'lightPercentage';
  static const String fieldAdcValue = 'adcValue';
  static const String fieldVoltage = 'voltage';
  static const String fieldLedState = 'ledState';
  static const String fieldDeviceId = 'deviceId';

  // Default values
  static const String defaultProfileImage = 'default_profile.png';
  static const String defaultDeviceImage = 'default_device.png';

  // Error codes
  static const String errorUserNotFound = 'user-not-found';
  static const String errorWrongPassword = 'wrong-password';
  static const String errorEmailInUse = 'email-already-in-use';
  static const String errorInvalidEmail = 'invalid-email';
  static const String errorWeakPassword = 'weak-password';
  static const String errorNetworkFailed = 'network-request-failed';

  // Security rules
  static const int maxDevicesPerUser = 10;
  static const int maxSensorDataPerDay = 10000;
  static const int maxImageSizeMB = 10;

  // Indexes
  static const List<String> userIndexes = ['email', 'createdAt'];
  static const List<String> deviceIndexes = ['userId', 'isOnline', 'lastSeen'];
  static const List<String> sensorDataIndexes = ['deviceId', 'timestamp', 'userId'];
}