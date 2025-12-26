import 'package:flutter/material.dart';

class AppConstants {
  // App information
  static const String appName = 'ESP32 IoT Controller';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserData = 'user_data';
  static const String keyRememberMe = 'remember_me';
  static const String keySelectedDevice = 'selected_device';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLanguage = 'language';
  static const String keyLastLogin = 'last_login';
  static const String keyDeviceList = 'device_list';

  // Default values
  static const double defaultThreshold = 1000.0;
  static const int defaultSampleCount = 10;
  static const int defaultHistoryLimit = 100;
  static const int defaultChartPoints = 50;

  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 50.0;

  // Sensor ranges
  static const int adcMinValue = 0;
  static const int adcMaxValue = 4095;
  static const double voltageMin = 0.0;
  static const double voltageMax = 3.3;

  // Chart colors
  static const List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];

  // Error messages
  static const String errGeneric = 'Une erreur est survenue';
  static const String errNetwork = 'Erreur réseau';
  static const String errTimeout = 'Délai d\'attente dépassé';
  static const String errInvalidInput = 'Entrée invalide';
  static const String errUnauthenticated = 'Authentification requise';


  // Notification intervals
  static const Duration sensorUpdateInterval = Duration(seconds: 2);
  static const Duration deviceStatusCheckInterval = Duration(seconds: 30);

  // Image constants
  static const double profileImageSize = 120.0;
  static const double profileImageBorderWidth = 3.0;
  static const int imageQuality = 85;
  static const int imageMaxSizeMB = 5;

  // Validation patterns
  static final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$'
  );

  static final RegExp phoneRegex = RegExp(
      r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$'
  );

  // Localization
  static const String defaultLocale = 'fr';
  static const List<String> supportedLocales = ['fr', 'en'];
}