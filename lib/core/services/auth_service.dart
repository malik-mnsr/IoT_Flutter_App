import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/app_constants.dart';
import '../constants/firebase_constants.dart';
import '../../features/auth/domain/models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();
  SharedPreferences? _prefs;

  // Initialize shared preferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Sign in with email and password
  Future<UserModel> signIn(String email, String password) async {
    try {
      await _initPrefs();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignInException('Authentication failed');
      }

      // Get user data from Firestore
      UserModel? user = await _dbService.getUser(firebaseUser.uid);

      // If user doesn't exist in Firestore, create basic record
      if (user == null) {
        user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _dbService.saveUser(user);
      } else {
        // Update last login
        final updatedUser = user.copyWith(lastLogin: DateTime.now());
        await _dbService.saveUser(updatedUser);
        user = updatedUser;
      }

      // Save login state
      await _saveLoginState(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw SignInException(
        getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw SignInException(
        'Login failed: $e',
        code: 'unknown_error',
      );
    }
  }

  // Sign up new user
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      await _initPrefs();

      // Create Firebase auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw SignUpException('Account creation failed');
      }

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Create user model
      final user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Save to Firestore
      await _dbService.saveUser(user);

      // Save login state
      await _saveLoginState(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw SignUpException(
        getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw SignUpException(
        'Registration failed: $e',
        code: 'unknown_error',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _initPrefs();
      await _auth.signOut();
      await _clearLoginState();
    } catch (e) {
      throw AuthException('Logout failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw PasswordResetException(
        getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw PasswordResetException('Password reset failed: $e');
    }
  }

  // Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      await _initPrefs();
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        // Try to restore from shared preferences
        final savedUser = await _getSavedUser();
        return savedUser;
      }

      // Get fresh data from Firestore
      final user = await _dbService.getUser(firebaseUser.uid);
      if (user != null) {
        await _saveLoginState(user);
      }

      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _initPrefs();

      // Update in Firestore
      await _dbService.saveUser(user);

      // Update Firebase Auth profile if needed
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Update display name
        if (user.name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(user.name);
        }

        // Update photo URL
        if (user.photoUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(user.photoUrl);
        }

        // Update email (requires re-authentication in production)
        if (user.email != firebaseUser.email) {
          // Note: In production, you should verify the new email
          // and re-authenticate the user before changing email
          print('Email change requested - needs verification');
        }
      }

      // Save updated state
      await _saveLoginState(user);
    } catch (e) {
      throw AuthException('Profile update failed: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      await _initPrefs();
      final user = _auth.currentUser;

      if (user != null) {
        // Delete from Firestore first
        await _dbService.deleteUser(user.uid);

        // Delete from Firebase Auth
        await user.delete();
      }

      await _clearLoginState();
    } catch (e) {
      throw AuthException('Account deletion failed: $e');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw AuthException('No user logged in');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Password change failed: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await _initPrefs();
    return _auth.currentUser != null ||
        (await _getSavedUser()) != null;
  }

  // Stream of authentication state changes
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        final user = await _dbService.getUser(firebaseUser.uid);
        if (user != null) {
          await _saveLoginState(user);
        }
        return user;
      }
      await _clearLoginState();
      return null;
    });
  }

  // Private: Save login state to shared preferences
  Future<void> _saveLoginState(UserModel user) async {
    await _prefs?.setString(AppConstants.keyUserId, user.uid);
    await _prefs?.setString(AppConstants.keyUserEmail, user.email);
    await _prefs?.setString(
      AppConstants.keyUserData,
      jsonEncode(user.toMap()),
    );
  }

  // Private: Clear login state
  Future<void> _clearLoginState() async {
    await _prefs?.remove(AppConstants.keyUserId);
    await _prefs?.remove(AppConstants.keyUserEmail);
    await _prefs?.remove(AppConstants.keyUserData);
    await _prefs?.remove(AppConstants.keyRememberMe);
  }

  // Private: Get saved user from shared preferences
  Future<UserModel?> _getSavedUser() async {
    final userData = _prefs?.getString(AppConstants.keyUserData);
    if (userData != null) {
      try {
        final map = jsonDecode(userData) as Map<String, dynamic>;
        return UserModel.fromMap(map);
      } catch (e) {
        print('Error parsing saved user: $e');
      }
    }
    return null;
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw AuthException('Email verification failed: $e');
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Re-authenticate user (for sensitive operations)
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Re-authentication failed: $e');
    }
  }
}