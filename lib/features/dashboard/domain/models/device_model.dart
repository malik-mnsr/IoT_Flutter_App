import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Device {
  final String id;
  final String name;
  final String ipAddress;
  final String userId;
  final String? location;
  final bool isOnline;
  final DateTime lastSeen;
  final double threshold;
  final String? description;
  final String? room;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Device({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.userId,
    this.location,
    required this.isOnline,
    required this.lastSeen,
    this.threshold = 1000.0,
    this.description,
    this.room,
    this.settings = const {},
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'userId': userId,
      'location': location,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'threshold': threshold,
      'description': description,
      'room': room,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore Document
  factory Device.fromMap(String id, Map<String, dynamic> map) {
    return Device(
      id: id,
      name: map['name'] ?? 'Appareil sans nom',
      ipAddress: map['ipAddress'] ?? '',
      userId: map['userId'] ?? '',
      location: map['location'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      threshold: (map['threshold'] ?? 1000.0).toDouble(),
      description: map['description'],
      room: map['room'],
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create from JSON (API response)
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Appareil sans nom',
      ipAddress: json['ipAddress'] ?? '',
      userId: json['userId'] ?? '',
      location: json['location'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
      threshold: (json['threshold'] ?? 1000.0).toDouble(),
      description: json['description'],
      room: json['room'],
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Copy with method for immutability
  Device copyWith({
    String? id,
    String? name,
    String? ipAddress,
    String? userId,
    String? location,
    bool? isOnline,
    DateTime? lastSeen,
    double? threshold,
    String? description,
    String? room,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      threshold: threshold ?? this.threshold,
      description: description ?? this.description,
      room: room ?? this.room,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get device status color
  Color get statusColor {
    if (!isOnline) return Colors.red;
    final minutesSinceLastSeen = DateTime.now().difference(lastSeen).inMinutes;
    if (minutesSinceLastSeen > 5) return Colors.orange;
    return Colors.green;
  }

  // Get status text
  String get statusText {
    if (!isOnline) return 'Hors ligne';
    final minutesSinceLastSeen = DateTime.now().difference(lastSeen).inMinutes;
    if (minutesSinceLastSeen > 5) return 'Inactif';
    return 'En ligne';
  }

  // Get formatted last seen time
  String get formattedLastSeen {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';

    return 'Le ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  // Get device type based on settings or description
  String get deviceType {
    return settings['type'] ?? 'ESP32';
  }

  // Get icon based on device type or room
  IconData get icon {
    final type = deviceType.toLowerCase();
    if (type.contains('light') || type.contains('lamp')) {
      return Icons.lightbulb_outline;
    } else if (type.contains('sensor')) {
      return Icons.sensors_outlined;
    } else if (type.contains('switch')) {
      return Icons.power_settings_new;
    } else if (room?.toLowerCase().contains('bedroom') == true) {
      return Icons.bed_outlined;
    } else if (room?.toLowerCase().contains('living') == true) {
      return Icons.living_outlined;
    } else if (room?.toLowerCase().contains('kitchen') == true) {
      return Icons.kitchen_outlined;
    } else if (room?.toLowerCase().contains('bath') == true) {
      return Icons.bathtub_outlined;
    }
    return Icons.devices_outlined;
  }

  // Check if device needs attention
  bool get needsAttention {
    if (!isOnline) return true;
    final minutesSinceLastSeen = DateTime.now().difference(lastSeen).inMinutes;
    return minutesSinceLastSeen > 30;
  }

  // Get connection quality (based on last seen time)
  double get connectionQuality {
    if (!isOnline) return 0.0;
    final minutesSinceLastSeen = DateTime.now().difference(lastSeen).inMinutes;

    if (minutesSinceLastSeen <= 1) return 1.0;
    if (minutesSinceLastSeen <= 5) return 0.7;
    if (minutesSinceLastSeen <= 15) return 0.4;
    return 0.1;
  }

  // Validate device data
  bool get isValid {
    return name.isNotEmpty &&
        ipAddress.isNotEmpty &&
        userId.isNotEmpty &&
        ipAddress.contains('.') &&
        threshold >= 0 &&
        threshold <= 4095;
  }

  // Get settings with defaults
  Map<String, dynamic> get settingsWithDefaults {
    return {
      'autoControl': true,
      'notifications': true,
      'dataInterval': 5,
      'retryCount': 3,
      'timeout': 10,
      ...settings,
    };
  }

  // Update a setting
  Device updateSetting(String key, dynamic value) {
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings[key] = value;
    return copyWith(settings: updatedSettings);
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'userId': userId,
      'location': location,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'threshold': threshold,
      'description': description,
      'room': room,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a new device with default values
  static Device createNew({
    required String name,
    required String ipAddress,
    required String userId,
    String? location,
    String? description,
    String? room,
  }) {
    final now = DateTime.now();
    return Device(
      id: 'device_${now.millisecondsSinceEpoch}_${userId.hashCode}',
      name: name,
      ipAddress: ipAddress,
      userId: userId,
      location: location,
      isOnline: false,
      lastSeen: now,
      threshold: 1000.0,
      description: description,
      room: room,
      settings: {},
      createdAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Device &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Device(id: $id, name: $name, ip: $ipAddress, online: $isOnline)';
  }
}