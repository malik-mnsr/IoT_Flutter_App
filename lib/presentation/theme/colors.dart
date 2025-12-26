import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3); // Blue
  static const Color primaryContainer = Color(0xFFBBDEFB);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color primaryContainerDark = Color(0xFF0D47A1);

  // Secondary colors
  static const Color secondary = Color(0xFFFFA726); // Orange
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color secondaryLight = Color(0xFFFFF3E0);
  static const Color secondaryContainerDark = Color(0xFFE65100);

  // Neutral colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFBDBDBD);

  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121);

  // Status colors
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Additional colors
  static const Color divider = Color(0xFFEEEEEE);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color hint = Color(0xFF9E9E9E);

  // Device status colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFBDBDBD);
  static const Color warning_status = Color(0xFFFF9800);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);

  // LED colors
  static const Color ledOn = Color(0xFFFF5722);
  static const Color ledOff = Color(0xFF9E9E9E);

  // Sensor colors
  static const Color sensorHigh = Color(0xFFFF5722);
  static const Color sensorMedium = Color(0xFFFFC107);
  static const Color sensorLow = Color(0xFF4CAF50);
  
  // Gradients - colors only
  static const List<Color> primaryGradient = [primary, primaryDark];
}
