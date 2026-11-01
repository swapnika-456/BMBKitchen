import 'dart:convert';
import 'package:dio/dio.dart';

class ApiExceptions {
  static String getDetailedErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        final responseData = error.response!.data;

        if (responseData is Map<String, dynamic>) {
          String? message = responseData['message'] as String?;
          if (message != null && message.isNotEmpty) return message;

          message = responseData['error'] as String?;
          if (message != null && message.isNotEmpty) return message;

          message = responseData['msg'] as String?;
          if (message != null && message.isNotEmpty) return message;

          message = responseData['errorMessage'] as String?;
          if (message != null && message.isNotEmpty) return message;
        }

        if (responseData is String) {
          try {
            final parsed = jsonDecode(responseData);
            if (parsed is Map<String, dynamic>) {
              String? message = parsed['message'] as String?;
              if (message != null && message.isNotEmpty) return message;
            }
          } catch (_) {
            if (responseData.trim().isNotEmpty &&
                !responseData.contains('DioException') &&
                !responseData.contains('bad response')) {
              return responseData;
            }
          }
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timeout. Please check your internet connection and try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }

      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        if (statusCode == 400) {
          return 'Invalid request. Please check your input and try again.';
        }
        if (statusCode == 401) {
          return 'Authentication failed. Please login again.';
        }
        if (statusCode == 403) {
          return 'You do not have permission to perform this action.';
        }
        if (statusCode == 404) {
          return 'The requested resource was not found.';
        }
        if (statusCode == 500) {
          return 'Server error occurred (500). Please try again later.';
        }
      }
    }

    final errorString = error.toString();
    if (errorString.contains('Failed host lookup')) {
      return 'Server unreachable. Please check if the server is online.';
    } else if (errorString.contains('connection timeout') ||
        errorString.contains('TimeoutException')) {
      return 'Request timeout. Server took too long to respond.';
    } else if (errorString.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('DioException')) {
      return 'An error occurred while processing your request. Please try again.';
    }

    return errorString;
  }
}
