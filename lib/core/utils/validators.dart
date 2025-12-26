import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    if (!AppConstants.emailRegex.hasMatch(value.trim())) {
      return 'Veuillez entrer un email valide';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    // Optional: Add more complex password rules
    // if (!RegExp(r'[A-Z]').hasMatch(value)) {
    //   return 'Le mot de passe doit contenir au moins une majuscule';
    // }
    // if (!RegExp(r'[0-9]').hasMatch(value)) {
    //   return 'Le mot de passe doit contenir au moins un chiffre';
    // }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }

    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    if (value.trim().length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }

    // Check for invalid characters
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le nom ne doit pas contenir de chiffres';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // French phone number validation
    if (cleaned.startsWith('+33')) {
      if (cleaned.length != 12) { // +33 + 9 digits
        return 'Numéro de téléphone invalide';
      }
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length != 10) { // 0 + 9 digits
        return 'Numéro de téléphone invalide';
      }
    } else {
      return 'Format de numéro invalide';
    }

    return null;
  }

  // IP address validation
  static String? validateIpAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse IP est requise';
    }

    final ipRegex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );

    if (!ipRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse IP valide';
    }

    return null;
  }

  // Device name validation
  static String? validateDeviceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom de l\'appareil est requis';
    }

    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    if (value.trim().length > 30) {
      return 'Le nom ne peut pas dépasser 30 caractères';
    }

    return null;
  }

  // Threshold validation
  static String? validateThreshold(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le seuil est requis';
    }

    final threshold = double.tryParse(value);
    if (threshold == null) {
      return 'Veuillez entrer un nombre valide';
    }

    if (threshold < AppConstants.adcMinValue || threshold > AppConstants.adcMaxValue) {
      return 'Le seuil doit être entre ${AppConstants.adcMinValue} et ${AppConstants.adcMaxValue}';
    }

    return null;
  }

  // Location validation
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Location is optional
    }

    if (value.trim().length > 100) {
      return 'La localisation ne peut pas dépasser 100 caractères';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }

    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nombre';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Veuillez entrer un nombre valide';
    }

    if (min != null && number < min) {
      return 'La valeur doit être supérieure ou égale à $min';
    }

    if (max != null && number > max) {
      return 'La valeur doit être inférieure ou égale à $max';
    }

    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nombre entier';
    }

    final integer = int.tryParse(value);
    if (integer == null) {
      return 'Veuillez entrer un nombre entier valide';
    }

    if (min != null && integer < min) {
      return 'La valeur doit être supérieure ou égale à $min';
    }

    if (max != null && integer > max) {
      return 'La valeur doit être inférieure ou égale à $max';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    final urlRegex = RegExp(
      r'^https?://' // http:// or https://
      r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|' // domain...
      r'localhost|' // localhost...
      r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' // ...or ip
      r'(?::\d+)?' // optional port
      r'(?:/?|[/?]\S+)$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Veuillez entrer une URL valide';
    }

    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La date est requise';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Veuillez entrer une date valide';
    }
  }

  // Time validation
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'heure est requise';
    }

    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');

    if (!timeRegex.hasMatch(value)) {
      return 'Veuillez entrer une heure valide (HH:MM)';
    }

    return null;
  }

  // Multiple validators
  static String? validateMultiple(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }

  // Form validator
  static Map<String, String?> validateForm(Map<String, String> values) {
    final errors = <String, String?>{};

    for (final entry in values.entries) {
      final field = entry.key;
      final value = entry.value;

      String? error;

      switch (field) {
        case 'email':
          error = validateEmail(value);
          break;
        case 'password':
          error = validatePassword(value);
          break;
        case 'name':
          error = validateName(value);
          break;
        case 'phone':
          error = validatePhoneNumber(value);
          break;
        case 'ip':
          error = validateIpAddress(value);
          break;
        case 'deviceName':
          error = validateDeviceName(value);
          break;
        case 'threshold':
          error = validateThreshold(value);
          break;
        case 'location':
          error = validateLocation(value);
          break;
      }

      if (error != null) {
        errors[field] = error;
      }
    }

    return errors;
  }

  // Validate sensor value range
  static String? validateSensorValue(double value, double min, double max) {
    if (value < min || value > max) {
      return 'La valeur doit être entre $min et $max';
    }
    return null;
  }

  // Validate file size (in bytes)
  static String? validateFileSize(int fileSize, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    if (fileSize > maxSizeInBytes) {
      return 'Le fichier ne doit pas dépasser $maxSizeInMB MB';
    }
    return null;
  }

  // Validate image dimensions
  static String? validateImageDimensions(
      int width,
      int height, {
        int? minWidth,
        int? maxWidth,
        int? minHeight,
        int? maxHeight,
      }) {
    if (minWidth != null && width < minWidth) {
      return 'La largeur doit être d\'au moins $minWidth pixels';
    }

    if (maxWidth != null && width > maxWidth) {
      return 'La largeur ne doit pas dépasser $maxWidth pixels';
    }

    if (minHeight != null && height < minHeight) {
      return 'La hauteur doit être d\'au moins $minHeight pixels';
    }

    if (maxHeight != null && height > maxHeight) {
      return 'La hauteur ne doit pas dépasser $maxHeight pixels';
    }

    return null;
  }
}