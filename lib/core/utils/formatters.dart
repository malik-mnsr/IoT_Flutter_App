import 'dart:math';

import 'package:intl/intl.dart';

class AppFormatters {
  // Date and time formatters
  static final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat timeFormatter = DateFormat('HH:mm:ss');
  static final DateFormat dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat relativeTimeFormatter = DateFormat('dd/MM HH:mm');

  // Number formatters
  static final NumberFormat decimalFormatter = NumberFormat('#,##0.00');
  static final NumberFormat integerFormatter = NumberFormat('#,##0');
  static final NumberFormat percentFormatter = NumberFormat('#,##0.0%');

  // Currency formatter (if needed)
  static final NumberFormat currencyFormatter =
  NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  // Format date to relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return dateFormatter.format(date);
    }
  }

  // Format duration (e.g., "2h 30m")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Format file size (e.g., "1.5 MB")
  static String formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();

    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // Format sensor value with unit
  static String formatSensorValue(double value, String unit) {
    return '${decimalFormatter.format(value)} $unit';
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${decimalFormatter.format(value)} %';
  }

  // Format voltage
  static String formatVoltage(double voltage) {
    return '${decimalFormatter.format(voltage)} V';
  }

  // Format ADC value
  static String formatAdcValue(int adcValue) {
    return integerFormatter.format(adcValue);
  }

  // Format boolean to readable text
  static String formatBoolean(bool value, {String trueText = 'ON', String falseText = 'OFF'}) {
    return value ? trueText : falseText;
  }

  // Format IP address
  static String formatIpAddress(String ip) {
    // Validate and format IP address
    final parts = ip.split('.');
    if (parts.length == 4) {
      return ip;
    }
    return 'Invalid IP';
  }

  // Format device name with truncation
  static String formatDeviceName(String name, {int maxLength = 20}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }

  // Format timestamp for display
  static String formatTimestamp(DateTime timestamp, {bool showSeconds = false}) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (timestamp.year == today.year &&
        timestamp.month == today.month &&
        timestamp.day == today.day) {
      return showSeconds
          ? 'Aujourd\'hui ${timeFormatter.format(timestamp)}'
          : 'Aujourd\'hui ${DateFormat('HH:mm').format(timestamp)}';
    } else if (timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day) {
      return showSeconds
          ? 'Hier ${timeFormatter.format(timestamp)}'
          : 'Hier ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return showSeconds
          ? dateTimeFormatter.format(timestamp)
          : dateFormatter.format(timestamp);
    }
  }

  // Format list to comma-separated string
  static String formatList(List<dynamic> list, {String separator = ', '}) {
    return list.map((e) => e.toString()).join(separator);
  }

  // Format temperature (if needed)
  static String formatTemperature(double celsius) {
    return '${decimalFormatter.format(celsius)}°C';
  }

  // Format distance
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${integerFormatter.format(meters)} m';
    } else {
      return '${decimalFormatter.format(meters / 1000)} km';
    }
  }

  // Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    // French phone number format
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+33')) {
      return cleaned.replaceAllMapped(
        RegExp(r'(\+33)(\d{1})(\d{2})(\d{2})(\d{2})(\d{2})'),
            (match) => '${match[1]} ${match[2]} ${match[3]} ${match[4]} ${match[5]} ${match[6]}',
      );
    } else if (cleaned.startsWith('0')) {
      return cleaned.replaceAllMapped(
        RegExp(r'(0)(\d{1})(\d{2})(\d{2})(\d{2})(\d{2})'),
            (match) => '${match[1]} ${match[2]} ${match[3]} ${match[4]} ${match[5]} ${match[6]}',
      );
    }

    return phoneNumber;
  }

  // Format email for display (hide part of it)
  static String formatEmail(String email) {
    final parts = email.split('@');
    if (parts.length == 2) {
      final username = parts[0];
      final domain = parts[1];

      if (username.length > 3) {
        final hidden = '*' * (username.length - 3);
        final visible = username.substring(0, 3);
        return '$visible$hidden@$domain';
      }
    }
    return email;
  }

  // Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Remove diacritics (accents)
  static String removeDiacritics(String text) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    String result = text;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }
}