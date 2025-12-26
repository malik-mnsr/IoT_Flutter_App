import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum CommandType {
  toggle,
  turnOn,
  turnOff,
  setThreshold,
  getStatus,
  reboot,
  updateSettings,
  custom,
}

class ControlCommand {
  final String id;
  final String deviceId;
  final String userId;
  final CommandType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final bool executed;
  final String? result;
  final DateTime? executedAt;
  final String? error;
  final int retryCount;
  final int priority;

  ControlCommand({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.type,
    this.parameters = const {},
    required this.timestamp,
    this.executed = false,
    this.result,
    this.executedAt,
    this.error,
    this.retryCount = 0,
    this.priority = 1,
  });

  // Create a new command
  factory ControlCommand.create({
    required String deviceId,
    required String userId,
    required CommandType type,
    Map<String, dynamic> parameters = const {},
    int priority = 1,
  }) {
    return ControlCommand(
      id: 'cmd_${DateTime.now().millisecondsSinceEpoch}_${deviceId.hashCode}',
      deviceId: deviceId,
      userId: userId,
      type: type,
      parameters: parameters,
      timestamp: DateTime.now(),
      priority: priority,
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'type': _typeToString(type),
      'parameters': parameters,
      'timestamp': Timestamp.fromDate(timestamp),
      'executed': executed,
      'result': result,
      'executedAt': executedAt != null ? Timestamp.fromDate(executedAt!) : null,
      'error': error,
      'retryCount': retryCount,
      'priority': priority,
    };
  }

  // Create from Firestore Document
  factory ControlCommand.fromMap(String id, Map<String, dynamic> map) {
    return ControlCommand(
      id: id,
      deviceId: map['deviceId'] ?? '',
      userId: map['userId'] ?? '',
      type: _stringToType(map['type']),
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      executed: map['executed'] ?? false,
      result: map['result'],
      executedAt: map['executedAt'] != null
          ? (map['executedAt'] as Timestamp).toDate()
          : null,
      error: map['error'],
      retryCount: (map['retryCount'] ?? 0).toInt(),
      priority: (map['priority'] ?? 1).toInt(),
    );
  }

  // Copy with method for immutability
  ControlCommand copyWith({
    String? id,
    String? deviceId,
    String? userId,
    CommandType? type,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
    bool? executed,
    String? result,
    DateTime? executedAt,
    String? error,
    int? retryCount,
    int? priority,
  }) {
    return ControlCommand(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      timestamp: timestamp ?? this.timestamp,
      executed: executed ?? this.executed,
      result: result ?? this.result,
      executedAt: executedAt ?? this.executedAt,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
    );
  }

  // Mark as executed
  ControlCommand markAsExecuted(String result) {
    return copyWith(
      executed: true,
      result: result,
      executedAt: DateTime.now(),
      error: null,
    );
  }

  // Mark as failed
  ControlCommand markAsFailed(String error) {
    return copyWith(
      retryCount: retryCount + 1,
      error: error,
    );
  }

  // Check if command can be retried
  bool get canRetry {
    return !executed && retryCount < 3;
  }

  // Get command description
  String get description {
    switch (type) {
      case CommandType.toggle:
        return 'Basculer la LED';
      case CommandType.turnOn:
        return 'Allumer la LED';
      case CommandType.turnOff:
        return 'Éteindre la LED';
      case CommandType.setThreshold:
        return 'Définir le seuil à ${parameters['threshold'] ?? 'N/A'}';
      case CommandType.getStatus:
        return 'Récupérer le statut';
      case CommandType.reboot:
        return 'Redémarrer l\'appareil';
      case CommandType.updateSettings:
        return 'Mettre à jour les paramètres';
      case CommandType.custom:
        return 'Commande personnalisée';
    }
  }

  // Get command icon
  IconData get icon {
    switch (type) {
      case CommandType.toggle:
        return Icons.swap_horiz;
      case CommandType.turnOn:
        return Icons.power;
      case CommandType.turnOff:
        return Icons.power_off;
      case CommandType.setThreshold:
        return Icons.tune;
      case CommandType.getStatus:
        return Icons.info_outline;
      case CommandType.reboot:
        return Icons.restart_alt;
      case CommandType.updateSettings:
        return Icons.settings;
      case CommandType.custom:
        return Icons.code;
    }
  }

  // Get command color
  Color get color {
    if (executed) return Colors.green;
    if (error != null) return Colors.red;
    if (retryCount > 0) return Colors.orange;
    return Colors.blue;
  }

  // Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
  }

  // Check if command is urgent
  bool get isUrgent {
    return priority >= 3 ||
        type == CommandType.reboot ||
        (error != null && canRetry);
  }

  // Convert to API payload
  Map<String, dynamic> toApiPayload() {
    switch (type) {
      case CommandType.toggle:
        return {'command': 'toggle'};
      case CommandType.turnOn:
        return {'command': 'on'};
      case CommandType.turnOff:
        return {'command': 'off'};
      case CommandType.setThreshold:
        return {
          'command': 'set_threshold',
          'threshold': parameters['threshold'],
        };
      case CommandType.getStatus:
        return {'command': 'status'};
      case CommandType.reboot:
        return {'command': 'reboot'};
      case CommandType.updateSettings:
        return {
          'command': 'update_settings',
          'settings': parameters['settings'],
        };
      case CommandType.custom:
        return parameters;
    }
  }

  // Helper methods for type conversion
  static String _typeToString(CommandType type) {
    return type.toString().split('.').last;
  }

  static CommandType _stringToType(String type) {
    switch (type) {
      case 'toggle': return CommandType.toggle;
      case 'turnOn': return CommandType.turnOn;
      case 'turnOff': return CommandType.turnOff;
      case 'setThreshold': return CommandType.setThreshold;
      case 'getStatus': return CommandType.getStatus;
      case 'reboot': return CommandType.reboot;
      case 'updateSettings': return CommandType.updateSettings;
      case 'custom': return CommandType.custom;
      default: return CommandType.custom;
    }
  }

  // Create command for LED control
  static ControlCommand ledToggle(String deviceId, String userId) {
    return ControlCommand.create(
      deviceId: deviceId,
      userId: userId,
      type: CommandType.toggle,
    );
  }

  static ControlCommand ledOn(String deviceId, String userId) {
    return ControlCommand.create(
      deviceId: deviceId,
      userId: userId,
      type: CommandType.turnOn,
    );
  }

  static ControlCommand ledOff(String deviceId, String userId) {
    return ControlCommand.create(
      deviceId: deviceId,
      userId: userId,
      type: CommandType.turnOff,
    );
  }

  static ControlCommand setDeviceThreshold(
      String deviceId,
      String userId,
      double threshold,
      ) {
    return ControlCommand.create(
      deviceId: deviceId,
      userId: userId,
      type: CommandType.setThreshold,
      parameters: {'threshold': threshold},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ControlCommand &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ControlCommand(id: $id, type: $type, device: $deviceId, executed: $executed)';
  }
}