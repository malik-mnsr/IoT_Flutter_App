class ApiConstants {
  // ESP32 API endpoints
  static const String baseEndpoint = '/api';

  static const String statusEndpoint = '/status';
  static const String controlEndpoint = '/control';
  static const String settingsEndpoint = '/settings';

  // API response keys
  static const String keySuccess = 'success';
  static const String keyError = 'error';
  static const String keyMessage = 'message';
  static const String keyLedState = 'led_state';
  static const String keyLightPercentage = 'light_percentage';
  static const String keyAdcValue = 'adc_value';
  static const String keyVoltage = 'voltage';
  static const String keyThreshold = 'threshold';
  static const String keyCommand = 'command';

  // Default timeout durations
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Default ESP32 port
  static const int defaultPort = 80;

  // API commands
  static const String cmdTurnOn = 'on';
  static const String cmdTurnOff = 'off';
  static const String cmdToggle = 'toggle';

  // Error messages
  static const String errNetwork = 'Erreur réseau';
  static const String errTimeout = 'Timeout de connexion';
  static const String errInvalidResponse = 'Réponse invalide';
  static const String errDeviceOffline = 'Appareil hors ligne';
  static const String errUnauthorized = 'Non autorisé';
}