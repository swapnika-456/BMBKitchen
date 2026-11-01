import 'package:flutter/foundation.dart';

class ApiLogger {
  static dynamic _sanitize(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final keyStr = entry.key.toString().toLowerCase();
        if (keyStr.contains('password') ||
            keyStr.contains('token') ||
            keyStr.contains('secret') ||
            keyStr.contains('authorization') ||
            keyStr.contains('cookie')) {
          sanitized[entry.key.toString()] = '[REDACTED]';
        } else if (entry.value is Map || entry.value is List) {
          sanitized[entry.key.toString()] = _sanitize(entry.value);
        } else {
          sanitized[entry.key.toString()] = entry.value;
        }
      }
      return sanitized;
    }
    if (data is List) {
      return data.map(_sanitize).toList();
    }
    if (data is String) {
      var str = data;
      str = str.replaceAll(
        RegExp(r'("password"\s*:\s*")[^"]+(")', caseSensitive: false),
        r'$1[REDACTED]$2',
      );
      str = str.replaceAll(
        RegExp(r'("token"\s*:\s*")[^"]+(")', caseSensitive: false),
        r'$1[REDACTED]$2',
      );
      str = str.replaceAll(
        RegExp(r'("authToken"\s*:\s*")[^"]+(")', caseSensitive: false),
        r'$1[REDACTED]$2',
      );
      str = str.replaceAll(
        RegExp(r'("auth_token"\s*:\s*")[^"]+(")', caseSensitive: false),
        r'$1[REDACTED]$2',
      );
      str = str.replaceAll(
        RegExp(r'(Bearer\s+)[A-Za-z0-9\-_.]+', caseSensitive: false),
        r'$1[REDACTED]',
      );
      str = str.replaceAll(
        RegExp(r'(token=)[^;\s]+', caseSensitive: false),
        r'$1[REDACTED]',
      );
      return str;
    }
    return data;
  }

  static void logRequest(String method, String url, dynamic body) {
    if (!kDebugMode) return;
    final sanitizedBody = _sanitize(body);
    // ignore: avoid_print
    print('==================== API REQUEST ====================');
    // ignore: avoid_print
    print('[$method] $url');
    if (sanitizedBody != null) {
      // ignore: avoid_print
      print('Body: $sanitizedBody');
    }
    // ignore: avoid_print
    print('=====================================================');
  }

  static void logError(String endpoint, String error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    final sanitizedError = _sanitize(error).toString();
    // ignore: avoid_print
    print('==================== API ERROR ====================');
    // ignore: avoid_print
    print('Endpoint: $endpoint');
    // ignore: avoid_print
    print('Error: $sanitizedError');
    // ignore: avoid_print
    print('StackTrace: $stackTrace');
    // ignore: avoid_print
    print('===================================================');
  }
}
