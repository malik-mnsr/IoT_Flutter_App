import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? phoneNumber;
  final String? location;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool emailVerified;
  final bool isActive;
  final Map<String, dynamic> settings;

  ProfileModel({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.phoneNumber,
    this.location,
    this.bio,
    required this.createdAt,
    this.lastUpdated,
    this.emailVerified = false,
    this.isActive = true,
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'location': location,
      'bio': bio,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'settings': settings,
    };
  }

  // Create from Map
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      bio: map['bio'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
      emailVerified: map['emailVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  // Copy with
  ProfileModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? phoneNumber,
    String? location,
    String? bio,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? emailVerified,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  // Get display name
  String get displayName => name ?? email;

  // Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      return name!
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
          .join()
          .substring(0, 2)
          .toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }
}
