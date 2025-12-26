
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/models/user_model.dart';

/// Extension methods for Firebase User
extension FirebaseUserExtension on User {
  /// Convert Firebase User to UserModel
  UserModel toUserModel() {
    return UserModel(
      uid: uid,
      email: email ?? '',
      name: displayName,
      photoUrl: photoURL,
      phoneNumber: phoneNumber,
      createdAt: metadata.creationTime ?? DateTime.now(),
      lastLogin: metadata.lastSignInTime,
      emailVerified: emailVerified,
      isActive: true,
    );
  }

  /// Get user initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    return displayName != null &&
        displayName!.isNotEmpty &&
        emailVerified &&
        photoURL != null;
  }

  /// Get user's provider info
  List<String> get authProviders {
    return providerData.map((provider) => provider.providerId).toList();
  }

  /// Check if user signed in with email/password
  bool get isEmailPasswordUser {
    return providerData.any((provider) => provider.providerId == 'password');
  }

  /// Check if user signed in with Google
  bool get isGoogleUser {
    return providerData.any((provider) => provider.providerId == 'google.com');
  }

  /// Get first sign-in method
  String? get primarySignInMethod {
    if (providerData.isNotEmpty) {
      return providerData.first.providerId;
    }
    return null;
  }

  /// Get formatted creation date
  String get formattedCreationDate {
    final date = metadata.creationTime;
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Date inconnue';
  }

  /// Get formatted last sign-in date
  String? get formattedLastSignIn {
    final date = metadata.lastSignInTime;
    if (date != null) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Get account age in days
  int? get accountAgeInDays {
    final creationTime = metadata.creationTime;
    if (creationTime != null) {
      return DateTime.now().difference(creationTime).inDays;
    }
    return null;
  }

  /// Check if account is new (less than 7 days)
  bool get isNewAccount {
    final age = accountAgeInDays;
    return age != null && age < 7;
  }
}

/// Firebase User wrapper class
class FirebaseUserWrapper {
  final User _user;

  FirebaseUserWrapper(this._user);

  /// Get the underlying Firebase User
  User get firebaseUser => _user;

  /// Convert to UserModel
  UserModel toUserModel() => _user.toUserModel();

  /// Check if email is verified
  bool get isEmailVerified => _user.emailVerified;

  /// Check if user needs to verify email
  bool get needsEmailVerification => !_user.emailVerified;

  /// Get user display name or email prefix
  String get displayNameOrEmail {
    if (_user.displayName != null && _user.displayName!.isNotEmpty) {
      return _user.displayName!;
    }
    if (_user.email != null) {
      return _user.email!.split('@').first;
    }
    return 'Utilisateur';
  }

  /// Get user photo URL with fallback
  String? get photoUrlWithFallback {
    return _user.photoURL ?? _getGravatarUrl();
  }

  /// Generate Gravatar URL based on email
  String? _getGravatarUrl() {
    if (_user.email == null) return null;
    final emailHash = _hashEmail(_user.email!.trim().toLowerCase());
    return 'https://www.gravatar.com/avatar/$emailHash?d=identicon&s=200';
  }

  /// Hash email for Gravatar
  String _hashEmail(String email) {
    final bytes = utf8.encode(email.trim().toLowerCase());
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get user role from custom claims
  Future<String?> getUserRole() async {
    final idTokenResult = await _user.getIdTokenResult();
    return idTokenResult.claims?['role'] as String?;
  }

  /// Check if user has admin role
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  /// Check if user has premium access
  Future<bool> hasPremiumAccess() async {
    final idTokenResult = await _user.getIdTokenResult();
    final claims = idTokenResult.claims;
    return claims?['premium'] == true || claims?['role'] == 'premium';
  }

  /// Get user subscription status
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final idTokenResult = await _user.getIdTokenResult();
    final claims = idTokenResult.claims;

    return {
      'isPremium': claims?['premium'] == true,
      'role': claims?['role'],
      'subscriptionTier': claims?['tier'],
      'expiresAt': claims?['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(claims!['exp'] * 1000)
          : null,
    };
  }

  /// Update user profile in Firebase Auth
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    await _user.updateDisplayName(displayName);
    if (photoUrl != null) {
      await _user.updatePhotoURL(photoUrl);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await _user.sendEmailVerification();
  }

  /// Reload user data from Firebase
  Future<void> reload() async {
    await _user.reload();
  }

  /// Get user metadata
  Map<String, dynamic> get metadata {
    return {
      'creationTime': _user.metadata.creationTime,
      'lastSignInTime': _user.metadata.lastSignInTime,
      'providerData': _user.providerData.map((p) => {
        'providerId': p.providerId,
        'uid': p.uid,
        'displayName': p.displayName,
        'email': p.email,
        'photoUrl': p.photoURL,
        'phoneNumber': p.phoneNumber,
      }).toList(),
    };
  }

  /// Get user as JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': _user.uid,
      'email': _user.email,
      'displayName': _user.displayName,
      'photoUrl': _user.photoURL,
      'phoneNumber': _user.phoneNumber,
      'emailVerified': _user.emailVerified,
      'isAnonymous': _user.isAnonymous,
      'metadata': metadata,
      'providers': _user.authProviders,
    };
  }

  @override
  String toString() {
    return 'FirebaseUserWrapper(uid: ${_user.uid}, email: ${_user.email}, name: ${_user.displayName})';
  }
}

/// Helper class for Firebase Auth operations
class FirebaseAuthHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user wrapper
  FirebaseUserWrapper? get currentUser {
    final user = _auth.currentUser;
    return user != null ? FirebaseUserWrapper(user) : null;
  }

  /// Stream of current user
  Stream<FirebaseUserWrapper?> get userStream {
    return _auth.authStateChanges().map((user) {
      return user != null ? FirebaseUserWrapper(user) : null;
    });
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.updateEmail(newEmail);
  }

  /// Re-authenticate user
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Get user by ID from Firestore
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      return null;
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }
}