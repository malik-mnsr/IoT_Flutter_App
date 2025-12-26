import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/firebase_constants.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/dashboard/domain/models/device_model.dart';
import '../../features/dashboard/domain/models/sensor_data_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection(FirebaseConstants.collectionUsers);

  CollectionReference<Map<String, dynamic>> get devicesCollection =>
      _firestore.collection(FirebaseConstants.collectionDevices);

  CollectionReference<Map<String, dynamic>> get sensorDataCollection =>
      _firestore.collection(FirebaseConstants.collectionSensorData);

  // User operations
  Future<void> saveUser(UserModel user) async {
    try {
      await usersCollection.doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw DataSaveException(
        'Failed to save user: $e',
        code: 'user_save_failed',
      );
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw DatabaseException(
        'Failed to get user: $e',
        code: 'user_get_failed',
      );
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
    } catch (e) {
      throw DatabaseException(
        'Failed to delete user: $e',
        code: 'user_delete_failed',
      );
    }
  }

  Future<void> updateUserPreferences(
      String uid,
      Map<String, dynamic> preferences,
      ) async {
    try {
      await usersCollection.doc(uid).update({
        'preferences': preferences,
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to update preferences: $e',
        code: 'preferences_update_failed',
      );
    }
  }

  // Device operations
  Future<void> addDevice(Device device) async {
    try {
      // Check device limit
      final userDevices = await getUserDevices(device.userId);
      if (userDevices.length >= FirebaseConstants.maxDevicesPerUser) {
        throw DatabaseException(
          'Device limit reached (${FirebaseConstants.maxDevicesPerUser})',
          code: 'device_limit_reached',
        );
      }

      // Save device
      await devicesCollection.doc(device.id).set(device.toMap());

      // Add to user's device list
      await usersCollection.doc(device.userId).update({
        FirebaseConstants.fieldDeviceIds:
        FieldValue.arrayUnion([device.id]),
      });
    } catch (e) {
      throw DataSaveException(
        'Failed to add device: $e',
        code: 'device_add_failed',
      );
    }
  }

  Future<void> updateDevice(Device device) async {
    try {
      await devicesCollection.doc(device.id).update(device.toMap());
    } catch (e) {
      throw DatabaseException(
        'Failed to update device: $e',
        code: 'device_update_failed',
      );
    }
  }

  Future<void> deleteDevice(String deviceId, String userId) async {
    try {
      // Delete device
      await devicesCollection.doc(deviceId).delete();

      // Remove from user's device list
      await usersCollection.doc(userId).update({
        FirebaseConstants.fieldDeviceIds:
        FieldValue.arrayRemove([deviceId]),
      });

      // Delete related sensor data (optional - can keep for history)
      // await _deleteDeviceSensorData(deviceId);
    } catch (e) {
      throw DatabaseException(
        'Failed to delete device: $e',
        code: 'device_delete_failed',
      );
    }
  }

  Future<Device?> getDevice(String deviceId) async {
    try {
      final doc = await devicesCollection.doc(deviceId).get();
      if (doc.exists) {
        return Device.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw DatabaseException(
        'Failed to get device: $e',
        code: 'device_get_failed',
      );
    }
  }

  Stream<List<Device>> getUserDevicesStream(String userId) {
    try {
      return devicesCollection
          .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
          .orderBy(FirebaseConstants.fieldLastSeen, descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => Device.fromMap(doc.id, doc.data()))
          .toList());
    } catch (e) {
      throw DatabaseException(
        'Failed to stream devices: $e',
        code: 'devices_stream_failed',
      );
    }
  }

  Future<List<Device>> getUserDevices(String userId) async {
    try {
      final snapshot = await devicesCollection
          .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => Device.fromMap(doc.id, doc.data()!))
          .toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get devices: $e',
        code: 'devices_get_failed',
      );
    }
  }

  Future<void> updateDeviceStatus({
    required String deviceId,
    required bool isOnline,
    required DateTime lastSeen,
  }) async {
    try {
      await devicesCollection.doc(deviceId).update({
        FirebaseConstants.fieldIsOnline: isOnline,
        FirebaseConstants.fieldLastSeen: lastSeen.toIso8601String(),
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to update device status: $e',
        code: 'device_status_update_failed',
      );
    }
  }

  // Sensor data operations
  Future<void> saveSensorData(SensorData data) async {
    try {
      await sensorDataCollection.add(data.toMap());
    } catch (e) {
      throw DataSaveException(
        'Failed to save sensor data: $e',
        code: 'sensor_data_save_failed',
      );
    }
  }

  Future<List<SensorData>> getDeviceHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final snapshot = await sensorDataCollection
          .where(FirebaseConstants.fieldDeviceId, isEqualTo: deviceId)
          .where(FirebaseConstants.fieldTimestamp,
          isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where(FirebaseConstants.fieldTimestamp,
          isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy(FirebaseConstants.fieldTimestamp, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get device history: $e',
        code: 'history_get_failed',
      );
    }
  }

  Stream<List<SensorData>> getRealtimeSensorData(String deviceId) {
    try {
      return sensorDataCollection
          .where(FirebaseConstants.fieldDeviceId, isEqualTo: deviceId)
          .orderBy(FirebaseConstants.fieldTimestamp, descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList());
    } catch (e) {
      throw DatabaseException(
        'Failed to stream sensor data: $e',
        code: 'sensor_data_stream_failed',
      );
    }
  }

  Future<Map<String, dynamic>> getDeviceStats(String deviceId) async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get today's data
      final todaySnapshot = await sensorDataCollection
          .where(FirebaseConstants.fieldDeviceId, isEqualTo: deviceId)
          .where(FirebaseConstants.fieldTimestamp,
          isGreaterThanOrEqualTo: yesterday.toIso8601String())
          .get();

      // Get week's data
      final weekSnapshot = await sensorDataCollection
          .where(FirebaseConstants.fieldDeviceId, isEqualTo: deviceId)
          .where(FirebaseConstants.fieldTimestamp,
          isGreaterThanOrEqualTo: weekAgo.toIso8601String())
          .get();

      final todayData = todaySnapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();
      final weekData = weekSnapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();

      // Calculate statistics
      double todayAvgLight = todayData.isEmpty
          ? 0
          : todayData
          .map((d) => d.lightPercentage)
          .reduce((a, b) => a + b) /
          todayData.length;

      double weekAvgLight = weekData.isEmpty
          ? 0
          : weekData
          .map((d) => d.lightPercentage)
          .reduce((a, b) => a + b) /
          weekData.length;

      int totalOnTime = todayData
          .where((d) => d.ledState)
          .length; // Approximate based on samples

      return {
        'todaySamples': todayData.length,
        'weekSamples': weekData.length,
        'todayAvgLight': todayAvgLight,
        'weekAvgLight': weekAvgLight,
        'estimatedOnTime': totalOnTime * 2, // 2 seconds per sample
        'lastUpdate': now,
      };
    } catch (e) {
      throw DatabaseException(
        'Failed to get device stats: $e',
        code: 'stats_get_failed',
      );
    }
  }

  // Cleanup old data
  Future<void> cleanupOldData(int daysToKeep) async {
    try {
      final cutoffDate =
      DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await sensorDataCollection
          .where(FirebaseConstants.fieldTimestamp,
          isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException(
        'Failed to cleanup old data: $e',
        code: 'cleanup_failed',
      );
    }
  }

  // Search devices by name or IP
  Future<List<Device>> searchDevices(String query, String userId) async {
    try {
      // Note: Firestore doesn't support OR queries or full-text search easily
      // This is a basic implementation
      final devices = await getUserDevices(userId);
      return devices
          .where((device) =>
      device.name.toLowerCase().contains(query.toLowerCase()) ||
          device.ipAddress.contains(query))
          .toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to search devices: $e',
        code: 'search_failed',
      );
    }
  }

  // Batch operations
  Future<void> batchUpdateDevicesStatus(
      List<String> deviceIds,
      bool isOnline,
      ) async {
    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now().toIso8601String();

      for (final deviceId in deviceIds) {
        final ref = devicesCollection.doc(deviceId);
        batch.update(ref, {
          FirebaseConstants.fieldIsOnline: isOnline,
          FirebaseConstants.fieldLastSeen: timestamp,
        });
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException(
        'Failed to batch update devices: $e',
        code: 'batch_update_failed',
      );
    }
  }
}