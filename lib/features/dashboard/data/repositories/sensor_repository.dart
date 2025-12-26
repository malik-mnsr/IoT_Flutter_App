import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/models/sensor_data_model.dart';
import '../../domain/models/device_model.dart';

abstract class SensorRepository {
  // Sensor data operations
  Future<void> saveSensorData(SensorData data);
  Future<List<SensorData>> getDeviceHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  });
  Stream<List<SensorData>> getRealtimeSensorData(String deviceId);

  // Data analysis
  Future<Map<String, dynamic>> analyzeSensorData({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Map<String, dynamic>> getDailyStats(String deviceId, DateTime date);
  Future<Map<String, dynamic>> getWeeklyStats(String deviceId, DateTime startDate);

  // Data export
  Future<String> exportSensorData({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    required String format, // csv, json
  });

  // Data cleanup
  Future<void> cleanupOldData(int daysToKeep);
  Future<void> deleteDeviceData(String deviceId);

  // Aggregated data
  Future<List<Map<String, dynamic>>> getHourlyAverages({
    required String deviceId,
    required DateTime date,
  });
  Future<List<Map<String, dynamic>>> getDailyAverages({
    required String deviceId,
    required DateTime startDate,
    required int days,
  });
}

class FirebaseSensorRepository implements SensorRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseSensorRepository(this._firestore, this._storage);

  // Collection references
  CollectionReference<Map<String, dynamic>> get sensorDataCollection =>
      _firestore.collection(FirebaseConstants.collectionSensorData);

  @override
  Future<void> saveSensorData(SensorData data) async {
    try {
      await sensorDataCollection.add(data.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de sauvegarde des données: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de sauvegarde des données: $e');
    }
  }

  @override
  Future<List<SensorData>> getDeviceHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final snapshot = await sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de récupération de l\'historique: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de récupération de l\'historique: $e');
    }
  }

  @override
  Stream<List<SensorData>> getRealtimeSensorData(String deviceId) {
    try {
      return sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de flux de données en temps réel: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de flux de données en temps réel: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeSensorData({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalSamples': 0,
          'avgLight': 0,
          'minLight': 0,
          'maxLight': 0,
          'ledOnPercentage': 0,
          'dataPoints': [],
        };
      }

      final data = snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();

      double totalLight = 0;
      double minLight = double.infinity;
      double maxLight = -double.infinity;
      int ledOnCount = 0;

      final List<Map<String, dynamic>> hourlyData = [];

      for (final sensorData in data) {
        totalLight += sensorData.lightPercentage;

        if (sensorData.lightPercentage < minLight) {
          minLight = sensorData.lightPercentage;
        }

        if (sensorData.lightPercentage > maxLight) {
          maxLight = sensorData.lightPercentage;
        }

        if (sensorData.ledState) {
          ledOnCount++;
        }

        // Group by hour for chart data
        final hour = DateTime(
          sensorData.timestamp.year,
          sensorData.timestamp.month,
          sensorData.timestamp.day,
          sensorData.timestamp.hour,
        );

        final existing = hourlyData.firstWhere(
              (item) => item['hour'] == hour,
          orElse: () => {'hour': hour, 'samples': 0, 'totalLight': 0.0},
        );

        if (existing['samples'] == 0) {
          hourlyData.add({
            'hour': hour,
            'samples': 1,
            'totalLight': sensorData.lightPercentage,
            'avgLight': sensorData.lightPercentage,
          });
        } else {
          existing['samples']++;
          existing['totalLight'] += sensorData.lightPercentage;
          existing['avgLight'] = existing['totalLight'] / existing['samples'];
        }
      }

      final avgLight = totalLight / data.length;
      final ledOnPercentage = (ledOnCount / data.length) * 100;

      // Calculate trends
      final sortedData = List<SensorData>.from(data)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      double trend = 0;
      if (sortedData.length > 1) {
        final firstLight = sortedData.first.lightPercentage;
        final lastLight = sortedData.last.lightPercentage;
        trend = lastLight - firstLight;
      }

      return {
        'totalSamples': data.length,
        'avgLight': avgLight,
        'minLight': minLight,
        'maxLight': maxLight,
        'ledOnPercentage': ledOnPercentage,
        'ledOnCount': ledOnCount,
        'ledOffCount': data.length - ledOnCount,
        'trend': trend,
        'isTrendingUp': trend > 0,
        'hourlyData': hourlyData,
        'startDate': startDate,
        'endDate': endDate,
        'analysisDate': DateTime.now().toIso8601String(),
      };
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur d\'analyse des données: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur d\'analyse des données: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailyStats(String deviceId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final analysis = await analyzeSensorData(
        deviceId: deviceId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      return {
        ...analysis,
        'date': date.toIso8601String().split('T')[0],
        'formattedDate': '${date.day}/${date.month}/${date.year}',
      };
    } catch (e) {
      throw DatabaseException('Erreur de statistiques quotidiennes: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getWeeklyStats(String deviceId, DateTime startDate) async {
    try {
      final endDate = startDate.add(const Duration(days: 7));

      final analysis = await analyzeSensorData(
        deviceId: deviceId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get daily averages for the week
      final dailyAverages = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));
        final daily = await getDailyStats(deviceId, day);
        dailyAverages.add({
          'day': day.weekday,
          'date': day.toIso8601String().split('T')[0],
          'avgLight': daily['avgLight'],
          'ledOnPercentage': daily['ledOnPercentage'],
        });
      }

      return {
        ...analysis,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dailyAverages': dailyAverages,
        'weekNumber': _getWeekNumber(startDate),
      };
    } catch (e) {
      throw DatabaseException('Erreur de statistiques hebdomadaires: $e');
    }
  }

  @override
  Future<String> exportSensorData({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
  }) async {
    try {
      final snapshot = await sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      final data = snapshot.docs
          .map((doc) => SensorData.fromMap(doc.id, doc.data()!))
          .toList();

      String exportContent;
      String fileName;

      if (format.toLowerCase() == 'csv') {
        exportContent = _convertToCsv(data);
        fileName = 'sensor_data_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        exportContent = _convertToJson(data);
        fileName = 'sensor_data_${deviceId}_${DateTime.now().millisecondsSinceEpoch}.json';
      }

      // Upload to Firebase Storage
      final ref = _storage.ref().child('exports/$fileName');
      final metadata = SettableMetadata(contentType: 'text/plain');
      await ref.putString(exportContent, metadata: metadata);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur d\'exportation des données: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur d\'exportation des données: $e');
    }
  }

  @override
  Future<void> cleanupOldData(int daysToKeep) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysToKeep)),
      );

      final snapshot = await sensorDataCollection
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de nettoyage des données: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de nettoyage des données: $e');
    }
  }

  @override
  Future<void> deleteDeviceData(String deviceId) async {
    try {
      final snapshot = await sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de suppression des données: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de suppression des données: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHourlyAverages({
    required String deviceId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await sensorDataCollection
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp')
          .get();

      final hourlyData = <Map<String, dynamic>>[];
      final hourMap = <int, List<double>>{};

      for (int i = 0; i < 24; i++) {
        hourMap[i] = [];
      }

      for (final doc in snapshot.docs) {
        final data = SensorData.fromMap(doc.id, doc.data()!);
        final hour = data.timestamp.hour;
        hourMap[hour]!.add(data.lightPercentage);
      }

      for (int hour = 0; hour < 24; hour++) {
        final readings = hourMap[hour]!;
        final avg = readings.isNotEmpty
            ? readings.reduce((a, b) => a + b) / readings.length
            : 0;

        hourlyData.add({
          'hour': hour,
          'avgLight': avg,
          'readingsCount': readings.length,
          'timeLabel': '$hour:00',
        });
      }

      return hourlyData;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Erreur de moyennes horaires: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException('Erreur de moyennes horaires: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyAverages({
    required String deviceId,
    required DateTime startDate,
    required int days,
  }) async {
    try {
      final dailyAverages = <Map<String, dynamic>>[];

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final stats = await getDailyStats(deviceId, date);

        dailyAverages.add({
          'date': date,
          'formattedDate': '${date.day}/${date.month}',
          'dayName': _getDayName(date.weekday),
          'avgLight': stats['avgLight'],
          'ledOnPercentage': stats['ledOnPercentage'],
          'samples': stats['totalSamples'],
        });
      }

      return dailyAverages;
    } catch (e) {
      throw DatabaseException('Erreur de moyennes quotidiennes: $e');
    }
  }

  // Helper methods

  String _convertToCsv(List<SensorData> data) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Timestamp,Light Percentage,ADC Value,Voltage,LED State,Light Level');

    // Data
    for (final item in data) {
      buffer.writeln(
          '${item.timestamp.toIso8601String()},'
              '${item.lightPercentage.toStringAsFixed(2)},'
              '${item.adcValue},'
              '${item.voltage.toStringAsFixed(2)},'
              '${item.ledState ? "ON" : "OFF"},'
              '${item.lightLevel}'
      );
    }

    return buffer.toString();
  }

  String _convertToJson(List<SensorData> data) {
    final jsonData = data.map((item) => item.toJson()).toList();
    return jsonEncode({
      'deviceId': data.isNotEmpty ? data.first.deviceId : '',
      'startDate': data.isNotEmpty ? data.last.timestamp.toIso8601String() : '',
      'endDate': data.isNotEmpty ? data.first.timestamp.toIso8601String() : '',
      'totalSamples': data.length,
      'data': jsonData,
    });
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday + 6) / 7).floor();
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  // Additional methods

  Future<Map<String, dynamic>> getPeakUsageTimes(String deviceId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final hourlyAverages = await getHourlyAverages(
        deviceId: deviceId,
        date: startDate,
      );

      // Find peak hours
      double maxAvg = 0;
      int peakHour = 0;

      for (final hourData in hourlyAverages) {
        if (hourData['avgLight'] > maxAvg) {
          maxAvg = hourData['avgLight'];
          peakHour = hourData['hour'];
        }
      }

      return {
        'peakHour': peakHour,
        'peakHourAvg': maxAvg,
        'peakTimeLabel': '$peakHour:00',
        'analysisPeriod': '$days jours',
        'hourlyData': hourlyAverages,
      };
    } catch (e) {
      throw DatabaseException('Erreur d\'analyse des pics: $e');
    }
  }

  Future<Map<String, dynamic>> compareWithPreviousPeriod({
    required String deviceId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) async {
    try {
      final currentAnalysis = await analyzeSensorData(
        deviceId: deviceId,
        startDate: currentStart,
        endDate: currentEnd,
      );

      final previousAnalysis = await analyzeSensorData(
        deviceId: deviceId,
        startDate: previousStart,
        endDate: previousEnd,
      );

      final currentAvg = currentAnalysis['avgLight'] ?? 0;
      final previousAvg = previousAnalysis['avgLight'] ?? 0;
      final difference = currentAvg - previousAvg;
      final percentageChange = previousAvg > 0
          ? (difference / previousAvg) * 100
          : 0;

      return {
        'currentPeriod': {
          'start': currentStart,
          'end': currentEnd,
          'analysis': currentAnalysis,
        },
        'previousPeriod': {
          'start': previousStart,
          'end': previousEnd,
          'analysis': previousAnalysis,
        },
        'comparison': {
          'avgLightDifference': difference,
          'percentageChange': percentageChange,
          'isIncrease': difference > 0,
          'ledUsageChange': (currentAnalysis['ledOnPercentage'] ?? 0) -
              (previousAnalysis['ledOnPercentage'] ?? 0),
        },
      };
    } catch (e) {
      throw DatabaseException('Erreur de comparaison: $e');
    }
  }
}