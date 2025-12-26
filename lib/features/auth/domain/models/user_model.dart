import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? phoneNumber;
  final String? location;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String> deviceIds;
  final Map<String, dynamic> preferences;
  final bool emailVerified;
  final bool isActive;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.phoneNumber,
    this.location,
    required this.createdAt,
    this.lastLogin,
    this.deviceIds = const [],
    this.preferences = const {},
    this.emailVerified = false,
    this.isActive = true,
    this.fcmToken,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'deviceIds': deviceIds,
      'preferences': preferences,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'fcmToken': fcmToken,
      'updatedAt': Timestamp.now(),
    };
  }

  // Create from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
      deviceIds: List<String>.from(map['deviceIds'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      emailVerified: map['emailVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      fcmToken: map['fcmToken'],
    );
  }

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? phoneNumber,
    String? location,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? deviceIds,
    Map<String, dynamic>? preferences,
    bool? emailVerified,
    bool? isActive,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      deviceIds: deviceIds ?? this.deviceIds,
      preferences: preferences ?? this.preferences,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Get user initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // Get display name
  String get displayName {
    return name ?? email.split('@')[0];
  }

  // Check if user is new (created within last 7 days)
  bool get isNewUser {
    return createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
  }

  // Get formatted creation date
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get user preferences with defaults
  Map<String, dynamic> get preferencesWithDefaults {
    return {
      'theme': preferences['theme'] ?? 'light',
      'language': preferences['language'] ?? 'fr',
      'notifications': preferences['notifications'] ?? true,
      'autoSync': preferences['autoSync'] ?? true,
      'dataSaving': preferences['dataSaving'] ?? false,
      ...preferences,
    };
  }

  // Add device to user
  UserModel addDevice(String deviceId) {
    if (deviceIds.contains(deviceId)) return this;
    return copyWith(
      deviceIds: [...deviceIds, deviceId],
    );
  }

  // Remove device from user
  UserModel removeDevice(String deviceId) {
    if (!deviceIds.contains(deviceId)) return this;
    return copyWith(
      deviceIds: deviceIds.where((id) => id != deviceId).toList(),
    );
  }

  // Update preference
  UserModel updatePreference(String key, dynamic value) {
    final updatedPreferences = Map<String, dynamic>.from(preferences);
    updatedPreferences[key] = value;
    return copyWith(preferences: updatedPreferences);
  }

  // Check if user has any devices
  bool get hasDevices => deviceIds.isNotEmpty;

  // Get number of devices
  int get deviceCount => deviceIds.length;

  // Equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel &&
              runtimeType == other.runtimeType &&
              uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  // String representation for debugging
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, deviceCount: $deviceCount)';
  }

  // Check if user profile is complete
  bool get isProfileComplete {
    return name != null &&
        name!.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty;
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    int totalFields = 4; // email, name, phone, location
    int completedFields = 1; // email is always present

    if (name != null && name!.isNotEmpty) completedFields++;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) completedFields++;
    if (location != null && location!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'deviceIds': deviceIds,
      'preferences': preferences,
      'emailVerified': emailVerified,
      'isActive': isActive,
    };
  }
}