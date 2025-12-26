import 'dart:convert';

/// Generic API response model
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create successful response
  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Operation successful',
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    String? error,
    int? statusCode,
    T? data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: false,
      data: data,
      error: error ?? 'An error occurred',
      message: message,
      statusCode: statusCode ?? 500,
      metadata: metadata,
    );
  }

  /// Create from HTTP response
  factory ApiResponse.fromHttpResponse({
    required int statusCode,
    required String body,
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      final success = statusCode >= 200 && statusCode < 300;
      final data = fromJson != null && json.containsKey('data')
          ? fromJson(json['data'])
          : null;

      return ApiResponse(
        success: success,
        data: data,
        message: json['message']?.toString(),
        error: json['error']?.toString(),
        statusCode: statusCode,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
    } catch (e) {
      return ApiResponse.error(
        error: 'Failed to parse response: $e',
        statusCode: statusCode,
      );
    }
  }

  /// Create from exception
  factory ApiResponse.fromException(
      dynamic exception, {
        int? statusCode,
      }) {
    String errorMessage;

    if (exception is String) {
      errorMessage = exception;
    } else if (exception is Map<String, dynamic>) {
      errorMessage = exception['error']?.toString() ?? exception.toString();
    } else {
      errorMessage = exception.toString();
    }

    return ApiResponse.error(
      error: errorMessage,
      statusCode: statusCode ?? 500,
    );
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response has error
  bool get hasError => error != null;

  /// Get data or throw exception if error
  T get requireData {
    if (!success || data == null) {
      throw Exception(error ?? 'No data available');
    }
    return data!;
  }

  /// Get error message with fallback
  String get errorMessage {
    if (error != null) return error!;
    if (message != null && !success) return message!;
    return 'Unknown error occurred';
  }

  /// Get success message
  String get successMessage {
    if (message != null && success) return message!;
    return 'Operation successful';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Map data to different type
  ApiResponse<R> map<R>(R Function(T) transform) {
    return ApiResponse<R>(
      success: success,
      data: data != null ? transform(data!) : null,
      message: message,
      error: error,
      statusCode: statusCode,
      metadata: metadata,
      timestamp: timestamp,
    );
  }

  /// Map with error handling
  ApiResponse<R> flatMap<R>(ApiResponse<R> Function(T) transform) {
    if (!success || data == null) {
      return ApiResponse<R>.error(
        error: error,
        statusCode: statusCode,
        message: message,
        metadata: metadata,
      );
    }

    try {
      return transform(data!);
    } catch (e) {
      return ApiResponse<R>.error(
        error: 'Mapping failed: $e',
        statusCode: 500,
        metadata: metadata,
      );
    }
  }

  /// Handle response with callbacks
  void handle({
    required void Function(T data) onSuccess,
    required void Function(String error) onError,
    void Function()? onFinally,
  }) {
    if (success && data != null) {
      onSuccess(data!);
    } else {
      onError(errorMessage);
    }

    onFinally?.call();
  }

  /// Create response for paginated data
  factory ApiResponse.paginated({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    int? pageSize,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: true,
      data: items.isNotEmpty ? items[0] : null,
      message: message,
      metadata: {
        'items': items,
        'pagination': {
          'currentPage': currentPage,
          'totalPages': totalPages,
          'totalItems': totalItems,
          'pageSize': pageSize ?? items.length,
          'hasNext': currentPage < totalPages,
          'hasPrevious': currentPage > 1,
        },
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Get pagination info
  Map<String, dynamic>? get paginationInfo {
    return metadata?['pagination'] as Map<String, dynamic>?;
  }

  /// Check if this is a paginated response
  bool get isPaginated => paginationInfo != null;

  /// Get next page number
  int? get nextPage {
    final info = paginationInfo;
    if (info != null && info['hasNext'] == true) {
      return (info['currentPage'] as int) + 1;
    }
    return null;
  }

  /// Get previous page number
  int? get previousPage {
    final info = paginationInfo;
    if (info != null && info['hasPrevious'] == true) {
      return (info['currentPage'] as int) - 1;
    }
    return null;
  }

  /// Create loading response
  factory ApiResponse.loading({String? message}) {
    return ApiResponse(
      success: true,
      message: message ?? 'Loading...',
      metadata: {'isLoading': true},
    );
  }

  /// Check if response is loading
  bool get isLoading => metadata?['isLoading'] == true;

  /// Create empty response
  factory ApiResponse.empty({String? message}) {
    return ApiResponse.success(
      data: null,
      message: message ?? 'No data found',
      metadata: {'isEmpty': true},
    );
  }

  /// Check if response is empty
  bool get isEmpty => metadata?['isEmpty'] == true;

  @override
  String toString() {
    return 'ApiResponse(success: $success, '
        'data: ${data != null ? 'Present' : 'Null'}, '
        'error: $error, statusCode: $statusCode)';
  }
}

/// Specialized API response for ESP32 device
class DeviceApiResponse extends ApiResponse<Map<String, dynamic>> {
  DeviceApiResponse({
    required bool success,
    Map<String, dynamic>? data,
    String? message,
    String? error,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) : super(
    success: success,
    data: data,
    message: message,
    error: error,
    statusCode: statusCode,
    metadata: metadata,
  );

  /// Create from ESP32 device response
  factory DeviceApiResponse.fromDeviceResponse(
      Map<String, dynamic> response,
      String deviceIp,
      ) {
    final success = response['success'] == true;

    return DeviceApiResponse(
      success: success,
      data: response,
      message: response['message']?.toString(),
      error: response['error']?.toString(),
      metadata: {
        'deviceIp': deviceIp,
        'responseTime': DateTime.now().toIso8601String(),
        ...?response['metadata'] as Map<String, dynamic>?,
      },
    );
  }

  /// Get LED state from response
  bool? get ledState {
    return data?['led_state'] ?? data?['ledState'];
  }

  /// Get light percentage from response
  double? get lightPercentage {
    final value = data?['light_percentage'] ?? data?['lightPercentage'];
    if (value != null) {
      return double.tryParse(value.toString());
    }
    return null;
  }

  /// Get ADC value from response
  int? get adcValue {
    final value = data?['adc_value'] ?? data?['adcValue'];
    if (value != null) {
      return int.tryParse(value.toString());
    }
    return null;
  }

  /// Get voltage from response
  double? get voltage {
    final value = data?['voltage'];
    if (value != null) {
      return double.tryParse(value.toString());
    }
    return null;
  }

  /// Get threshold from response
  double? get threshold {
    final value = data?['threshold'];
    if (value != null) {
      return double.tryParse(value.toString());
    }
    return null;
  }

  /// Get device IP from metadata
  String? get deviceIp {
    return metadata?['deviceIp']?.toString();
  }

  /// Check if device is online
  bool get isDeviceOnline {
    if (data?['isOnline'] != null) {
      return data!['isOnline'] == true;
    }
    return success && error == null;
  }

  /// Get response time
  DateTime? get responseTime {
    final time = metadata?['responseTime']?.toString();
    if (time != null) {
      return DateTime.tryParse(time);
    }
    return null;
  }

  /// Get formatted response time
  String? get formattedResponseTime {
    final time = responseTime;
    if (time != null) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    }
    return null;
  }
}

/// API response for sensor data
class SensorDataResponse extends ApiResponse<List<Map<String, dynamic>>> {
  SensorDataResponse({
    required bool success,
    List<Map<String, dynamic>>? data,
    String? message,
    String? error,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) : super(
    success: success,
    data: data,
    message: message,
    error: error,
    statusCode: statusCode,
    metadata: metadata,
  );

  /// Get average light percentage
  double get averageLightPercentage {
    if (data == null || data!.isEmpty) return 0.0;

    final total = data!
        .map((item) => item['light_percentage'] ?? item['lightPercentage'] ?? 0.0)
        .whereType<double>()
        .fold(0.0, (sum, value) => sum + value);

    return total / data!.length;
  }

  /// Get time range
  Map<String, DateTime?> get timeRange {
    if (data == null || data!.isEmpty) {
      return {'start': null, 'end': null};
    }

    final timestamps = data!
        .map((item) {
      final time = item['timestamp']?.toString();
      return time != null ? DateTime.tryParse(time) : null;
    })
        .whereType<DateTime>()
        .toList();

    if (timestamps.isEmpty) {
      return {'start': null, 'end': null};
    }

    timestamps.sort();
    return {
      'start': timestamps.first,
      'end': timestamps.last,
    };
  }

  /// Get data points per hour
  Map<int, int> get dataPointsPerHour {
    final result = <int, int>{};

    if (data == null) return result;

    for (final item in data!) {
      final time = item['timestamp']?.toString();
      if (time != null) {
        final dateTime = DateTime.tryParse(time);
        if (dateTime != null) {
          final hour = dateTime.hour;
          result[hour] = (result[hour] ?? 0) + 1;
        }
      }
    }

    return result;
  }
}

/// API response with caching support
class CachedApiResponse<T> extends ApiResponse<T> {
  final DateTime cachedAt;
  final Duration cacheDuration;
  final String cacheKey;

  CachedApiResponse({
    required super.success,
    required this.cacheKey,
    super.data,
    super.message,
    super.error,
    super.statusCode,
    super.metadata,
    DateTime? cachedAt,
    Duration? cacheDuration,
  })  : cachedAt = cachedAt ?? DateTime.now(),
        cacheDuration = cacheDuration ?? const Duration(minutes: 5);

  /// Check if cache is still valid
  bool get isCacheValid {
    return DateTime.now().difference(cachedAt) < cacheDuration;
  }

  /// Check if cache has expired
  bool get isCacheExpired {
    return !isCacheValid;
  }

  /// Get time until cache expires
  Duration get timeUntilExpiry {
    final expiryTime = cachedAt.add(cacheDuration);
    return expiryTime.difference(DateTime.now());
  }

  /// Create from another ApiResponse
  factory CachedApiResponse.fromApiResponse(
      ApiResponse<T> response, {
        required String cacheKey,
        Duration? cacheDuration,
      }) {
    return CachedApiResponse<T>(
      success: response.success,
      cacheKey: cacheKey,
      data: response.data,
      message: response.message,
      error: response.error,
      statusCode: response.statusCode,
      metadata: response.metadata,
      cacheDuration: cacheDuration,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
      'cacheDuration': cacheDuration.inSeconds,
      'cacheKey': cacheKey,
      'isCacheValid': isCacheValid,
      'timeUntilExpiry': timeUntilExpiry.inSeconds,
    };
  }
}