import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/api_constants.dart';

class ApiService {
  final String deviceIp;
  final int port;

  ApiService({
    required this.deviceIp,
    this.port = ApiConstants.defaultPort,
  });

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ESP32-IoT-App/${AppConstants.appVersion}',
  };

  // Helper method for making HTTP requests
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.http('$deviceIp:$port', endpoint);

      final request = http.Request(method, uri);
      request.headers.addAll(_headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send().timeout(
        ApiConstants.connectTimeout,
        onTimeout: () => throw TimeoutException(ApiConstants.errTimeout),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw ApiException(ApiConstants.errUnauthorized, code: 'unauthorized');
      } else if (response.statusCode == 404) {
        throw ApiException('Endpoint not found: $endpoint', code: 'not_found');
      } else {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          code: 'http_${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(
        '${ApiConstants.errNetwork}: $e',
        code: 'network_error',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Connection failed: $e',
        code: 'connection_failed',
      );
    } on TimeoutException {
      rethrow;
    } on FormatException catch (e) {
      throw InvalidResponseException(
        '${ApiConstants.errInvalidResponse}: $e',
        code: 'invalid_json',
      );
    } catch (e) {
      throw ApiException(
        'Unexpected error: $e',
        code: 'unexpected_error',
      );
    }
  }

  // Get device status
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _makeRequest(
        endpoint: ApiConstants.statusEndpoint,
      );

      if (response[ApiConstants.keySuccess] == true) {
        return {
          'success': true,
          'ledState': response[ApiConstants.keyLedState] ?? false,
          'lightPercentage': response[ApiConstants.keyLightPercentage] ?? 0.0,
          'adcValue': response[ApiConstants.keyAdcValue] ?? 0,
          'voltage': response[ApiConstants.keyVoltage] ?? 0.0,
          'threshold': response[ApiConstants.keyThreshold] ?? 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw ApiException(
          response[ApiConstants.keyError] ?? 'Unknown error',
          code: 'api_error',
        );
      }
    } catch (e) {
      // If device is offline, return offline status
      if (e is NetworkException || e is TimeoutException) {
        return {
          'success': false,
          'isOnline': false,
          'error': ApiConstants.errDeviceOffline,
        };
      }
      rethrow;
    }
  }

  // Control LED
  Future<Map<String, dynamic>> controlLed(String command) async {
    try {
      final response = await _makeRequest(
        endpoint: ApiConstants.controlEndpoint,
        method: 'POST',
        body: {ApiConstants.keyCommand: command},
      );

      if (response[ApiConstants.keySuccess] == true) {
        return {
          'success': true,
          'message': response[ApiConstants.keyMessage] ?? 'Command executed',
        };
      } else {
        throw ApiException(
          response[ApiConstants.keyError] ?? 'Control failed',
          code: 'control_failed',
        );
      }
    } catch (e) {
      if (e is NetworkException || e is TimeoutException) {
        return {
          'success': false,
          'isOnline': false,
          'error': ApiConstants.errDeviceOffline,
        };
      }
      rethrow;
    }
  }

  // Turn LED on
  Future<void> turnOnLed() async {
    await controlLed(ApiConstants.cmdTurnOn);
  }

  // Turn LED off
  Future<void> turnOffLed() async {
    await controlLed(ApiConstants.cmdTurnOff);
  }

  // Toggle LED
  Future<void> toggleLed() async {
    await controlLed(ApiConstants.cmdToggle);
  }

  // Update device settings
  Future<void> updateSettings(double threshold) async {
    try {
      final response = await _makeRequest(
        endpoint: ApiConstants.settingsEndpoint,
        method: 'POST',
        body: {ApiConstants.keyThreshold: threshold},
      );

      if (response[ApiConstants.keySuccess] != true) {
        throw ApiException(
          response[ApiConstants.keyError] ?? 'Settings update failed',
          code: 'settings_failed',
        );
      }
    } catch (e) {
      if (e is NetworkException || e is TimeoutException) {
        throw DeviceOfflineException(deviceIp);
      }
      rethrow;
    }
  }

  // Check if device is online
  Future<bool> isDeviceOnline() async {
    try {
      final response = await _makeRequest(
        endpoint: '/',
        method: 'GET',
      );
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Ping device (quick connectivity check)
  Future<bool> pingDevice() async {
    try {
      final socket = await Socket.connect(deviceIp, port,
          timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}