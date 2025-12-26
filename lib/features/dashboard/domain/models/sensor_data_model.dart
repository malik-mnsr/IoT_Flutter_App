import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SensorData {
  final String id;
  final String deviceId;
  final String userId;
  final double lightPercentage;
  final int adcValue;
  final double voltage;
  final bool ledState;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SensorData({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.lightPercentage,
    required this.adcValue,
    required this.voltage,
    required this.ledState,
    required this.timestamp,
    this.metadata,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'lightPercentage': lightPercentage,
      'adcValue': adcValue,
      'voltage': voltage,
      'ledState': ledState,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
    };
  }

  // Create from Firestore Document
  factory SensorData.fromMap(String id, Map<String, dynamic> map) {
    return SensorData(
      id: id,
      deviceId: map['deviceId'] ?? '',
      userId: map['userId'] ?? '',
      lightPercentage: (map['lightPercentage'] ?? 0.0).toDouble(),
      adcValue: (map['adcValue'] ?? 0).toInt(),
      voltage: (map['voltage'] ?? 0.0).toDouble(),
      ledState: map['ledState'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Create from API response
  factory SensorData.fromApiResponse({
    required String deviceId,
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return SensorData(
      id: '',
      deviceId: deviceId,
      userId: userId,
      lightPercentage: (data['light_percentage'] ?? 0.0).toDouble(),
      adcValue: (data['adc_value'] ?? 0).toInt(),
      voltage: (data['voltage'] ?? 0.0).toDouble(),
      ledState: data['led_state'] ?? false,
      timestamp: DateTime.now(),
      metadata: {
        'source': 'api',
        'responseTime': DateTime.now().toIso8601String(),
      },
    );
  }

  // Create from ESP32 data
  factory SensorData.fromEsp32({
    required String deviceId,
    required String userId,
    required int adcValue,
    required bool ledState,
  }) {
    final voltage = adcValue * 3.3 / 4095.0;
    final lightPercentage = (adcValue / 4095.0) * 100.0;

    return SensorData(
      id: '',
      deviceId: deviceId,
      userId: userId,
      lightPercentage: lightPercentage,
      adcValue: adcValue,
      voltage: voltage,
      ledState: ledState,
      timestamp: DateTime.now(),
      metadata: {
        'source': 'esp32',
        'adcRaw': adcValue,
        'calculated': true,
      },
    );
  }

  // Copy with method for immutability
  SensorData copyWith({
    String? id,
    String? deviceId,
    String? userId,
    double? lightPercentage,
    int? adcValue,
    double? voltage,
    bool? ledState,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return SensorData(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      lightPercentage: lightPercentage ?? this.lightPercentage,
      adcValue: adcValue ?? this.adcValue,
      voltage: voltage ?? this.voltage,
      ledState: ledState ?? this.ledState,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get light level category
  String get lightLevel {
    if (lightPercentage < 10) return 'Très sombre';
    if (lightPercentage < 25) return 'Sombre';
    if (lightPercentage < 50) return 'Faible';
    if (lightPercentage < 75) return 'Modéré';
    return 'Lumineux';
  }

  // Get light level color
  Color get lightColor {
    if (lightPercentage < 10) return Colors.red[900]!;
    if (lightPercentage < 25) return Colors.red;
    if (lightPercentage < 50) return Colors.orange;
    if (lightPercentage < 75) return Colors.yellow[700]!;
    return Colors.green;
  }

  // Get voltage status
  String get voltageStatus {
    if (voltage < 1.0) return 'Très basse';
    if (voltage < 2.0) return 'Basse';
    if (voltage < 2.5) return 'Normale';
    if (voltage < 3.0) return 'Élevée';
    return 'Très élevée';
  }

  // Get voltage color
  Color get voltageColor {
    if (voltage < 1.0) return Colors.red[900]!;
    if (voltage < 2.0) return Colors.red;
    if (voltage < 2.5) return Colors.green;
    if (voltage < 3.0) return Colors.orange;
    return Colors.red;
  }

  // Get LED status with emoji
  String get ledStatusEmoji {
    return ledState ? '💡 Allumée' : '⚫ Éteinte';
  }

  // Check if data is recent (less than 5 minutes old)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  // Check if data is stale (more than 1 hour old)
  bool get isStale {
    return DateTime.now().difference(timestamp).inHours > 1;
  }

  // Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dataDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (dataDay == today) {
      return 'Aujourd\'hui ${_formatTime(timestamp)}';
    } else if (dataDay == today.subtract(const Duration(days: 1))) {
      return 'Hier ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${_formatTime(timestamp)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Get data quality indicator
  double get dataQuality {
    double quality = 1.0;

    // Penalize stale data
    if (isStale) quality *= 0.5;

    // Penalize invalid values
    if (lightPercentage < 0 || lightPercentage > 100) quality *= 0.7;
    if (adcValue < 0 || adcValue > 4095) quality *= 0.7;
    if (voltage < 0 || voltage > 3.3) quality *= 0.7;

    return quality;
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'userId': userId,
      'lightPercentage': lightPercentage,
      'adcValue': adcValue,
      'voltage': voltage,
      'ledState': ledState,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'lightLevel': lightLevel,
      'voltageStatus': voltageStatus,
      'formattedTime': formattedTime,
    };
  }

  // Create a batch of test data
  static List<SensorData> createTestData({
    required String deviceId,
    required String userId,
    int count = 50,
  }) {
    final List<SensorData> data = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final timestamp = now.subtract(Duration(minutes: i * 30));
      final adcValue = (2000 + (500 * (i % 3))).toInt();
      final voltage = adcValue * 3.3 / 4095.0;
      final lightPercentage = (adcValue / 4095.0) * 100.0;
      final ledState = adcValue < 1500;

      data.add(SensorData(
        id: 'test_${timestamp.millisecondsSinceEpoch}',
        deviceId: deviceId,
        userId: userId,
        lightPercentage: lightPercentage,
        adcValue: adcValue,
        voltage: voltage,
        ledState: ledState,
        timestamp: timestamp,
        metadata: {
          'test': true,
          'index': i,
        },
      ));
    }

    return data;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SensorData &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'SensorData(device: $deviceId, light: ${lightPercentage.toStringAsFixed(1)}%, led: $ledState, time: $formattedTime)';
  }
}