import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/models/user_model.dart';


abstract class AuthRepository {
  // Authentication
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);

  // Social Sign In
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();

  // User Management
  Future<UserModel> getCurrentUser();
  Future<void> updateUserProfile(UserModel user);
  Future<void> deleteAccount();
  Future<void> changePassword(String newPassword);
  Future<void> sendEmailVerification();

  // Session Management
  Future<bool> isLoggedIn();
  Stream<UserModel?> authStateChanges();
  Future<void> saveSession(UserModel user);
  Future<void> clearSession();

  // User Preferences
  Future<void> updateUserPreferences(
      String userId,
      Map<String, dynamic> preferences,
      );
  Future<Map<String, dynamic>> getUserPreferences(String userId);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseService _databaseService;
  final GoogleSignIn _googleSignIn;
  SharedPreferences? _prefs;

  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required DatabaseService databaseService,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _databaseService = databaseService,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  // Initialize shared preferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Email/Password Authentication
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      await _initPrefs();

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignInException('Authentication failed - no user returned');
      }

      // Get or create user in Firestore
      UserModel? user = await _databaseService.getUser(firebaseUser.uid);

      if (user == null) {
        // Create new user record
        user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          emailVerified: firebaseUser.emailVerified,
        );
        await _databaseService.saveUser(user);
      } else {
        // Update last login
        final updatedUser = user.copyWith(
          lastLogin: DateTime.now(),
          emailVerified: firebaseUser.emailVerified,
        );
        await _databaseService.saveUser(updatedUser);
        user = updatedUser;
      }

      // Save session
      await saveSession(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw SignInException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw SignInException(
        'Login failed: $e',
        code: 'unknown_error',
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      await _initPrefs();

      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignUpException('Account creation failed');
      }

      // Update display name
      if (name.isNotEmpty) {
        await firebaseUser.updateDisplayName(name);
      }

      // Create user model
      final user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        emailVerified: false,
      );

      // Save to Firestore
      await _databaseService.saveUser(user);

      // Send verification email
      await firebaseUser.sendEmailVerification();

      // Save session
      await saveSession(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw SignUpException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw SignUpException(
        'Registration failed: $e',
        code: 'unknown_error',
      );
    }
  }

  // Social Sign In
  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _initPrefs();

      // Trigger Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw SignInException('Google sign in cancelled');
      }

      // Get authentication details
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw SignInException('Google authentication failed');
      }

      // Get or create user in Firestore
      UserModel? user = await _databaseService.getUser(firebaseUser.uid);

      if (user == null) {
        // Create new user from Google data
        user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? googleUser.displayName,
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          emailVerified: firebaseUser.emailVerified,
        );
        await _databaseService.saveUser(user);
      } else {
        // Update existing user
        final updatedUser = user.copyWith(
          lastLogin: DateTime.now(),
          name: firebaseUser.displayName ?? user.name,
          photoUrl: firebaseUser.photoURL ?? user.photoUrl,
        );
        await _databaseService.saveUser(updatedUser);
        user = updatedUser;
      }

      // Save session
      await saveSession(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw SignInException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw SignInException(
        'Google sign in failed: $e',
        code: 'google_signin_failed',
      );
    }
  }

  @override
  Future<UserModel> signInWithFacebook() async {
    // TODO: Implement Facebook sign in
    // You'll need to add facebook_auth package
    throw UnimplementedError('Facebook sign in not implemented');
  }

  // User Management
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      await _initPrefs();

      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        // Try to restore from session
        final sessionUser = await _getSessionUser();
        if (sessionUser != null) {
          return sessionUser;
        }
        throw AuthException('No user logged in');
      }

      // Get fresh user data from Firestore
      final user = await _databaseService.getUser(firebaseUser.uid);
      if (user == null) {
        throw AuthException('User data not found');
      }

      // Update session
      await saveSession(user);

      return user;
    } catch (e) {
      throw AuthException('Failed to get current user: $e');
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _initPrefs();

      // Update in Firestore
      await _databaseService.saveUser(user);

      // Update Firebase Auth profile
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        if (user.name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(user.name);
        }
        if (user.photoUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(user.photoUrl);
        }
      }

      // Update session
      await saveSession(user);
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _initPrefs();

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No user to delete');
      }

      // Delete from Firestore
      await _databaseService.deleteUser(user.uid);

      // Delete from Firebase Auth
      await user.delete();

      // Clear session
      await clearSession();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No user logged in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Re-authentication required. Please sign in again.',
          code: e.code,
        );
      }
      throw AuthException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Failed to change password: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw AuthException('Failed to send verification email: $e');
    }
  }

  // Session Management
  @override
  Future<bool> isLoggedIn() async {
    await _initPrefs();

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) return true;

    final sessionUser = await _getSessionUser();
    return sessionUser != null;
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        final user = await _databaseService.getUser(firebaseUser.uid);
        if (user != null) {
          await saveSession(user);
          return user;
        }
      }
      await clearSession();
      return null;
    });
  }

  @override
  Future<void> saveSession(UserModel user) async {
    await _prefs?.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
    await _prefs?.setString(AppConstants.keyUserId, user.uid);
    await _prefs?.setString(AppConstants.keyUserEmail, user.email);
  }

  @override
  Future<void> clearSession() async {
    await _prefs?.remove(AppConstants.keyUserData);
    await _prefs?.remove(AppConstants.keyUserId);
    await _prefs?.remove(AppConstants.keyUserEmail);
    await _prefs?.remove(AppConstants.keyRememberMe);
  }

  // Password Reset
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw PasswordResetException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw PasswordResetException('Failed to reset password: $e');
    }
  }

  // Sign Out
  @override
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear session
      await clearSession();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  // User Preferences
  @override
  Future<void> updateUserPreferences(
      String userId,
      Map<String, dynamic> preferences,
      ) async {
    try {
      await _databaseService.updateUserPreferences(userId, preferences);

      // Update session if it's the current user
      final currentUser = await _getSessionUser();
      if (currentUser != null && currentUser.uid == userId) {
        final updatedUser = currentUser.copyWith(preferences: preferences);
        await saveSession(updatedUser);
      }
    } catch (e) {
      throw AuthException('Failed to update preferences: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final user = await _databaseService.getUser(userId);
      return user?.preferences ?? {};
    } catch (e) {
      throw AuthException('Failed to get preferences: $e');
    }
  }

  // Helper Methods
  Future<UserModel?> _getSessionUser() async {
    await _initPrefs();

    final userData = _prefs?.getString(AppConstants.keyUserData);
    if (userData != null) {
      try {
        final map = jsonDecode(userData) as Map<String, dynamic>;
        return UserModel.fromMap(map);
      } catch (e) {
        print('Error parsing session user: $e');
      }
    }
    return null;
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case FirebaseConstants.errorUserNotFound:
        return 'Aucun compte trouvé avec cet email';
      case FirebaseConstants.errorWrongPassword:
        return 'Mot de passe incorrect';
      case FirebaseConstants.errorEmailInUse:
        return 'Cet email est déjà utilisé';
      case FirebaseConstants.errorInvalidEmail:
        return 'Format d\'email invalide';
      case FirebaseConstants.errorWeakPassword:
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case FirebaseConstants.errorNetworkFailed:
        return 'Erreur réseau. Vérifiez votre connexion';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'requires-recent-login':
        return 'Re-connexion requise pour cette opération';
      default:
        return 'Une erreur est survenue: ${e.message}';
    }
  }

  // Re-authentication for sensitive operations
  Future<void> reauthenticate(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw AuthException('No user to re-authenticate');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Re-authentication failed: $e');
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // Get authentication provider
  List<String> getAuthProviders() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    return user.providerData.map((provider) => provider.providerId).toList();
  }

  // Link additional auth providers
  Future<void> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No user to link with');
      }

      await user.linkWithCredential(credential);
    } catch (e) {
      throw AuthException('Failed to link Google account: $e');
    }
  }
}