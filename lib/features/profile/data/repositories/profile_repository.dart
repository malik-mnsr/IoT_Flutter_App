import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/models/profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> getProfile(String uid);
  Future<void> updateProfile(ProfileModel profile);
  Future<void> updateProfilePicture(String uid, String imagePath);
  Future<void> deleteProfile(String uid);
  Future<String> uploadProfileImage(String uid, String imagePath);
}

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<ProfileModel?> getProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw DatabaseException('Profile not found');
      }

      return ProfileModel.fromMap(doc.data() ?? {});
    } catch (e) {
      throw DatabaseException(
        'Failed to fetch profile: ${e.toString()}',
        code: 'fetch_profile_error',
      );
    }
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(profile.uid)
          .update({
            ...profile.toMap(),
            'lastUpdated': DateTime.now(),
          });
    } catch (e) {
      throw DataSaveException(
        'Failed to update profile: ${e.toString()}',
        code: 'update_profile_error',
      );
    }
  }

  @override
  Future<String> uploadProfileImage(String uid, String imagePath) async {
    try {
      final fileName = 'profile_$uid.jpg';
      final ref = _storage
          .ref()
          .child(FirebaseConstants.storageProfileImages)
          .child(fileName);

      // Note: imagePath should be converted to File object
      // For now, this is a placeholder
      // In real implementation: await ref.putFile(File(imagePath));

      // Get download URL (placeholder)
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw UploadFailedException(
        'Failed to upload profile image: ${e.toString()}',
        code: 'upload_image_error',
      );
    }
  }

  @override
  Future<void> updateProfilePicture(String uid, String imageUrl) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(uid)
          .update({
            'photoUrl': imageUrl,
            'lastUpdated': DateTime.now(),
          });
    } catch (e) {
      throw DataSaveException(
        'Failed to update profile picture: ${e.toString()}',
        code: 'update_picture_error',
      );
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      // Delete profile image from storage
      try {
        await _storage
            .ref()
            .child(FirebaseConstants.storageProfileImages)
            .child('profile_$uid.jpg')
            .delete();
      } catch (_) {
        // Ignore if image doesn't exist
      }

      // Delete user document
      await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(uid)
          .delete();
    } catch (e) {
      throw DatabaseException(
        'Failed to delete profile: ${e.toString()}',
        code: 'delete_profile_error',
      );
    }
  }
}
