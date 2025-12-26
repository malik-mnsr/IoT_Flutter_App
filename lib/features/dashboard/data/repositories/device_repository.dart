import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/models/device_model.dart';
import '../../domain/models/control_command.dart';

abstract class DeviceRepository {
  // Device operations
  Future<Device> addDevice(Device device);
  Future<void> updateDevice(Device device);
  Future<void> deleteDevice(String deviceId, String userId);
  Future<Device?> getDevice(String deviceId);
  Stream<List<Device>> getUserDevices(String userId);
  Future<List<Device>> searchDevices(String query, String userId);

  // Device status
  Future<void> updateDeviceStatus({
    required String deviceId,
    required bool isOnline,
    required DateTime lastSeen,
  });
  Future<void> batchUpdateDevicesStatus(List<String> deviceIds, bool isOnline);

  // Control commands
  Future<void> sendCommand(ControlCommand command);
  Stream<List<ControlCommand>> getDeviceCommands(String deviceId, {int limit = 20});
  Future<void> markCommandExecuted(String commandId, String result);
  Future<void> markCommandFailed(String commandId, String error);

  // Device statistics
  Future<Map<String, dynamic>> getDeviceStats(String deviceId);
  Future<Map<String, dynamic>> getUserStats(String userId);

  // Bulk operations
  Future<void> cleanupOldDevices(int daysInactive);
}

class FirebaseDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _firestore;

  FirebaseDeviceRepository(this._firestore);

  // Collection references
  CollectionReference<Map<String, dynamic>> get devicesCollection =>
      _firestore.collection(FirebaseConstants.collectionDevices);

  CollectionReference<Map<String, dynamic>> get commandsCollection =>
      _firestore.collection('control_commands');

  @override
  Future<Device> addDevice(Device device) async {
    try {
      // Validate device
      if (!device.isValid) {
        throw DatabaseException('Données de l\'appareil invalides');
      }

      // Check for duplicate IP for this user
      final existingDevices = await getUserDevices(device.userId).first;
      final duplicate = existingDevices.firstWhere(
            (d) => d.ipAddress == device.ipAddress,
        orElse: () => Device.createNew(
          name: '',
          ipAddress: '',
          userId: '',
        ),
      );

      if (duplicate.ipAddress.isNotEmpty) {
        throw DatabaseException('Un appareil avec cette IP existe déjà');
      }

      // Add to Firestore
      await devicesCollection.doc(device.id).set(device.toMap());

      // Add device to user's device list
      await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(device.userId)
          .update({
        FirebaseConstants.fieldDeviceIds:
        FieldValue.arrayUnion([device.id]),
      });

      return device;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur d\'ajout d\'appareil: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur d\'ajout d\'appareil: $e');
    }
  }

  @override
  Future<void> updateDevice(Device device) async {
    try {
      await devicesCollection.doc(device.id).update(device.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de mise à jour d\'appareil: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de mise à jour d\'appareil: $e');
    }
  }

  @override
  Future<void> deleteDevice(String deviceId, String userId) async {
    try {
      // Delete device
      await devicesCollection.doc(deviceId).delete();

      // Remove from user's device list
      await _firestore
          .collection(FirebaseConstants.collectionUsers)
          .doc(userId)
          .update({
        FirebaseConstants.fieldDeviceIds:
        FieldValue.arrayRemove([deviceId]),
      });

      // Delete related commands (optional)
      final commands = await commandsCollection
          .where('deviceId', isEqualTo: deviceId)
          .get();

      final batch = _firestore.batch();
      for (final doc in commands.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de suppression d\'appareil: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de suppression d\'appareil: $e');
    }
  }

  @override
  Future<Device?> getDevice(String deviceId) async {
    try {
      final doc = await devicesCollection.doc(deviceId).get();
      if (doc.exists) {
        return Device.fromMap(doc.id, doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de récupération d\'appareil: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de récupération d\'appareil: $e');
    }
  }

  @override
  Stream<List<Device>> getUserDevices(String userId) {
    try {
      return devicesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastSeen', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => Device.fromMap(doc.id, doc.data()))
          .toList());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de flux d\'appareils: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de flux d\'appareils: $e');
    }
  }

  @override
  Future<List<Device>> searchDevices(String query, String userId) async {
    try {
      final devices = await getUserDevices(userId).first;
      return devices
          .where((device) =>
      device.name.toLowerCase().contains(query.toLowerCase()) ||
          device.ipAddress.contains(query) ||
          (device.location?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (device.description?.toLowerCase().contains(query.toLowerCase()) ??
              false))
          .toList();
    } catch (e) {
      throw DatabaseException('Erreur de recherche d\'appareils: $e');
    }
  }

  @override
  Future<void> updateDeviceStatus({
    required String deviceId,
    required bool isOnline,
    required DateTime lastSeen,
  }) async {
    try {
      await devicesCollection.doc(deviceId).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de mise à jour du statut: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de mise à jour du statut: $e');
    }
  }

  @override
  Future<void> batchUpdateDevicesStatus(
      List<String> deviceIds,
      bool isOnline,
      ) async {
    try {
      final batch = _firestore.batch();
      final timestamp = Timestamp.now();

      for (final deviceId in deviceIds) {
        final ref = devicesCollection.doc(deviceId);
        batch.update(ref, {
          'isOnline': isOnline,
          'lastSeen': timestamp,
          'updatedAt': timestamp,
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de mise à jour par lot: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de mise à jour par lot: $e');
    }
  }

  @override
  Future<void> sendCommand(ControlCommand command) async {
    try {
      await commandsCollection.doc(command.id).set(command.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur d\'envoi de commande: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur d\'envoi de commande: $e');
    }
  }

  @override
  Stream<List<ControlCommand>> getDeviceCommands(
      String deviceId, {
        int limit = 20,
      }) {
    try {
      return commandsCollection
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ControlCommand.fromMap(doc.id, doc.data()))
          .toList());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de flux de commandes: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de flux de commandes: $e');
    }
  }

  @override
  Future<void> markCommandExecuted(String commandId, String result) async {
    try {
      await commandsCollection.doc(commandId).update({
        'executed': true,
        'result': result,
        'executedAt': Timestamp.now(),
        'error': FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de marquage de commande: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de marquage de commande: $e');
    }
  }

  @override
  Future<void> markCommandFailed(String commandId, String error) async {
    try {
      final doc = await commandsCollection.doc(commandId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final retryCount = (data['retryCount'] ?? 0) + 1;

        await commandsCollection.doc(commandId).update({
          'retryCount': retryCount,
          'error': error,
        });
      }
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de marquage d\'échec: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de marquage d\'échec: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDeviceStats(String deviceId) async {
    try {
      final device = await getDevice(deviceId);
      if (device == null) {
        throw DeviceNotFoundException(deviceId);
      }

      // Get recent commands
      final commands = await commandsCollection
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final successfulCommands = commands.docs
          .where((doc) => doc.data()['executed'] == true)
          .length;

      final failedCommands = commands.docs
          .where((doc) => doc.data()['error'] != null)
          .length;

      // Calculate uptime (simplified)
      final now = DateTime.now();
      final lastSeen = device.lastSeen;
      final isRecentlyOnline = now.difference(lastSeen).inMinutes < 5;

      return {
        'device': device,
        'totalCommands': commands.size,
        'successfulCommands': successfulCommands,
        'failedCommands': failedCommands,
        'successRate': commands.size > 0
            ? (successfulCommands / commands.size) * 100
            : 0,
        'isRecentlyOnline': isRecentlyOnline,
        'lastSeenFormatted': device.formattedLastSeen,
        'connectionQuality': device.connectionQuality,
        'needsAttention': device.needsAttention,
        'statsUpdatedAt': now.toIso8601String(),
      };
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de statistiques d\'appareil: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de statistiques d\'appareil: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final devices = await getUserDevices(userId).first;

      final onlineDevices = devices.where((d) => d.isOnline).length;
      final totalDevices = devices.length;
      final needsAttentionDevices = devices.where((d) => d.needsAttention).length;

      // Get total commands for user
      final commands = await commandsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalDevices': totalDevices,
        'onlineDevices': onlineDevices,
        'offlineDevices': totalDevices - onlineDevices,
        'needsAttention': needsAttentionDevices,
        'onlinePercentage': totalDevices > 0
            ? (onlineDevices / totalDevices) * 100
            : 0,
        'totalCommands': commands.size,
        'mostRecentDevice': devices.isNotEmpty ? devices.first : null,
        'statsUpdatedAt': DateTime.now().toIso8601String(),
      };
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de statistiques utilisateur: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de statistiques utilisateur: $e');
    }
  }

  @override
  Future<void> cleanupOldDevices(int daysInactive) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysInactive)),
      );

      final snapshot = await devicesCollection
          .where('lastSeen', isLessThan: cutoffDate)
          .where('isOnline', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);

        // Remove from user's device list
        final device = Device.fromMap(doc.id, doc.data());
        await _firestore
            .collection(FirebaseConstants.collectionUsers)
            .doc(device.userId)
            .update({
          FirebaseConstants.fieldDeviceIds:
          FieldValue.arrayRemove([device.id]),
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de nettoyage d\'appareils: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de nettoyage d\'appareils: $e');
    }
  }

  // Additional methods

  Future<void> updateDeviceSettings(
      String deviceId,
      Map<String, dynamic> settings,
      ) async {
    try {
      await devicesCollection.doc(deviceId).update({
        'settings': settings,
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de mise à jour des paramètres: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de mise à jour des paramètres: $e');
    }
  }

  Future<List<Device>> getDevicesByRoom(String userId, String room) async {
    try {
      final snapshot = await devicesCollection
          .where('userId', isEqualTo: userId)
          .where('room', isEqualTo: room)
          .get();

      return snapshot.docs
          .map((doc) => Device.fromMap(doc.id, doc.data()!))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de récupération par salle: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de récupération par salle: $e');
    }
  }

  Future<Map<String, List<Device>>> getDevicesGroupedByRoom(String userId) async {
    try {
      final devices = await getUserDevices(userId).first;
      final grouped = <String, List<Device>>{};

      for (final device in devices) {
        final room = device.room ?? 'Non classé';
        if (!grouped.containsKey(room)) {
          grouped[room] = [];
        }
        grouped[room]!.add(device);
      }

      return grouped;
    } catch (e) {
      throw DatabaseException('Erreur de groupement par salle: $e');
    }
  }
}