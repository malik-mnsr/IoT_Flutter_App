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
  });

  Map<String, dynamic> toMap() {
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : null,
      deviceIds: List<String>.from(map['deviceIds'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

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
    );
  }
}