import 'dart:async';
import 'package:flutter/material.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../../features/dashboard/domain/models/sensor_data_model.dart';

class SensorService with ChangeNotifier {
  final DatabaseService _dbService;
  final Map<String, ApiService> _apiServices = {};

  // State
  final Map<String, Map<String, dynamic>> _sensorData = {};
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, StreamController<Map<String, dynamic>>> _streamControllers = {};
  bool _isMonitoring = false;

  SensorService(this._dbService);

  // Initialize API service for a device
  ApiService _getApiService(String deviceId, String ipAddress) {
    if (!_apiServices.containsKey(deviceId)) {
      _apiServices[deviceId] = ApiService(deviceIp: ipAddress);
    }
    return _apiServices[deviceId]!;
  }

  // Start monitoring a device
  void startMonitoring(String deviceId, String ipAddress) {
    if (_pollingTimers.containsKey(deviceId)) {
      return; // Already monitoring
    }

    final apiService = _getApiService(deviceId, ipAddress);

    // Create stream controller for this device
    _streamControllers[deviceId] = StreamController<Map<String, dynamic>>.broadcast();

    // Start polling
    _pollingTimers[deviceId] = Timer.periodic(
      AppConstants.sensorUpdateInterval,
          (_) => _pollDevice(deviceId, apiService),
    );

    // Initial poll
    _pollDevice(deviceId, apiService);

    _isMonitoring = true;
    notifyListeners();
  }

  // Poll device for sensor data
  Future<void> _pollDevice(String deviceId, ApiService apiService) async {
    try {
      final status = await apiService.getDeviceStatus();

      if (status['success'] == true) {
        // Update local cache
        _sensorData[deviceId] = {
          ...status,
          'deviceId': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
          'isOnline': true,
        };

        // Save to database
        await _saveSensorDataToDb(deviceId, status);

        // Notify listeners
        _streamControllers[deviceId]?.add(_sensorData[deviceId]!);
        notifyListeners();
      } else {
        // Device offline
        _sensorData[deviceId] = {
          'deviceId': deviceId,
          'isOnline': false,
          'lastOnline': DateTime.now().toIso8601String(),
          'error': status['error'],
        };
        _streamControllers[deviceId]?.add(_sensorData[deviceId]!);
      }
    } catch (e) {
      // Error polling device
      _sensorData[deviceId] = {
        'deviceId': deviceId,
        'isOnline': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      _streamControllers[deviceId]?.add(_sensorData[deviceId]!);
    }
  }

  // Save sensor data to database
  Future<void> _saveSensorDataToDb(
      String deviceId,
      Map<String, dynamic> status,
      ) async {
    try {
      final sensorData = SensorData(
        id: '',
        deviceId: deviceId,
        userId: '', // Will be set by caller
        lightPercentage: status['lightPercentage'] ?? 0.0,
        adcValue: status['adcValue'] ?? 0,
        voltage: status['voltage'] ?? 0.0,
        ledState: status['ledState'] ?? false,
        timestamp: DateTime.now(),
      );

      await _dbService.saveSensorData(sensorData);
    } catch (e) {
      print('Failed to save sensor data to DB: $e');
    }
  }

  // Control LED
  Future<void> controlLed(String deviceId, String command) async {
    try {
      final apiService = _apiServices[deviceId];
      if (apiService == null) {
        throw DeviceException('Device not initialized: $deviceId');
      }

      await apiService.controlLed(command);

      // Update local state immediately
      if (_sensorData.containsKey(deviceId)) {
        _sensorData[deviceId]!['ledState'] = command == 'on'
            ? true
            : command == 'off'
            ? false
            : !_sensorData[deviceId]!['ledState'];

        _streamControllers[deviceId]?.add(_sensorData[deviceId]!);
        notifyListeners();
      }
    } catch (e) {
      throw DeviceException('Failed to control LED: $e');
    }
  }

  // Convenience methods
  Future<void> turnOnLed(String deviceId) => controlLed(deviceId, 'on');
  Future<void> turnOffLed(String deviceId) => controlLed(deviceId, 'off');
  Future<void> toggleLed(String deviceId) => controlLed(deviceId, 'toggle');

  // Update device settings
  Future<void> updateDeviceSettings(
      String deviceId,
      double threshold,
      ) async {
    try {
      final apiService = _apiServices[deviceId];
      if (apiService == null) {
        throw DeviceException('Device not initialized: $deviceId');
      }

      await apiService.updateSettings(threshold);

      // Update local state
      if (_sensorData.containsKey(deviceId)) {
        _sensorData[deviceId]!['threshold'] = threshold;
        _streamControllers[deviceId]?.add(_sensorData[deviceId]!);
        notifyListeners();
      }
    } catch (e) {
      throw DeviceException('Failed to update settings: $e');
    }
  }

  // Get sensor data for a device
  Map<String, dynamic>? getSensorData(String deviceId) {
    return _sensorData[deviceId];
  }

  // Stream for a specific device
  Stream<Map<String, dynamic>> getDeviceStream(String deviceId) {
    if (!_streamControllers.containsKey(deviceId)) {
      _streamControllers[deviceId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _streamControllers[deviceId]!.stream;
  }

  // Combined stream for all devices
  Stream<Map<String, dynamic>> get sensorStream {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Combine all device streams
    for (final deviceId in _streamControllers.keys) {
      _streamControllers[deviceId]!.stream.listen((data) {
        controller.add(data);
      });
    }

    return controller.stream;
  }

  // Stop monitoring a device
  void stopMonitoring(String deviceId) {
    _pollingTimers[deviceId]?.cancel();
    _pollingTimers.remove(deviceId);

    _streamControllers[deviceId]?.close();
    _streamControllers.remove(deviceId);

    _sensorData.remove(deviceId);

    if (_pollingTimers.isEmpty) {
      _isMonitoring = false;
    }

    notifyListeners();
  }

  // Stop all monitoring
  void stopAllMonitoring() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }

    for (final controller in _streamControllers.values) {
      controller.close();
    }

    _pollingTimers.clear();
    _streamControllers.clear();
    _sensorData.clear();
    _apiServices.clear();

    _isMonitoring = false;
    notifyListeners();
  }

  // Check if monitoring
  bool isMonitoring(String deviceId) {
    return _pollingTimers.containsKey(deviceId);
  }

  bool get isMonitoringAny => _isMonitoring;

  // Get list of monitored devices
  List<String> get monitoredDevices => _pollingTimers.keys.toList();

  // Cleanup
  @override
  void dispose() {
    stopAllMonitoring();
    super.dispose();
  }

  // Manual refresh
  Future<void> refreshDevice(String deviceId) async {
    final apiService = _apiServices[deviceId];
    if (apiService != null) {
      await _pollDevice(deviceId, apiService);
    }
  }

  // Get device statistics
  Future<Map<String, dynamic>> getDeviceStatistics(String deviceId) async {
    try {
      return await _dbService.getDeviceStats(deviceId);
    } catch (e) {
      throw SensorException('Failed to get statistics: $e');
    }
  }

  // Get device history
  Future<List<SensorData>> getDeviceHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      return await _dbService.getDeviceHistory(
        deviceId: deviceId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw SensorException('Failed to get history: $e');
    }
  }

  // Check device connectivity
  Future<bool> checkDeviceConnectivity(String deviceId, String ipAddress) async {
    try {
      final apiService = _getApiService(deviceId, ipAddress);
      return await apiService.pingDevice();
    } catch (e) {
      return false;
    }
  }
}