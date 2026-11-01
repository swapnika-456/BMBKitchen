import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/app_notification.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(dio);
});

/// Notification API Service covering endpoints #170 to #173
/// Base: /api/notification/v1/:organizationId
class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/notification/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 500;
      final serverMsg = ApiExceptions.getDetailedErrorMessage(error);
      return ApiResponse<T>(
        success: false,
        statusCode: statusCode,
        message: serverMsg,
      );
    }
    return ApiResponse<T>(
      success: false,
      statusCode: 500,
      message: error.toString(),
    );
  }

  // #170: GET /api/notification/v1/:organizationId/:outletId
  // Query: unreadOnly? (true) -> data: notifications. Includes organization-wide ones.
  Future<ApiResponse<List<AppNotification>>> getNotifications(
    String organizationId,
    String outletId, {
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (unreadOnly) {
        queryParams['unreadOnly'] = 'true';
      }

      final response = await _dio.get(
        '${_basePath(organizationId)}/$outletId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final listData = JsonUtils.extractList(response.data['data']);
      final notifications = listData
          .map((item) => AppNotification.fromJson(JsonUtils.extractMap(item)))
          .toList();

      return ApiResponse<List<AppNotification>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Notifications fetched',
        data: notifications,
      );
    } catch (e) {
      return _errorResponse<List<AppNotification>>(e);
    }
  }

  // #171: GET /api/notification/v1/:organizationId/:outletId/unread-count
  // Response body data: {"unreadCount": 0} (or plain integer)
  Future<ApiResponse<int>> getUnreadCount(
    String organizationId,
    String outletId,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/$outletId/unread-count',
      );

      final rawData = response.data['data'];
      int count = 0;
      if (rawData is Map) {
        count = int.tryParse((rawData['unreadCount'] ?? rawData['count'] ?? 0).toString()) ?? 0;
      } else if (rawData is num) {
        count = rawData.toInt();
      } else if (rawData != null) {
        count = int.tryParse(rawData.toString()) ?? 0;
      }

      return ApiResponse<int>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Unread count fetched',
        data: count,
      );
    } catch (e) {
      return _errorResponse<int>(e);
    }
  }

  // #172: GET /api/notification/v1/:organizationId/single/:id
  Future<ApiResponse<AppNotification>> getSingleNotification(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/single/$id',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<AppNotification>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Notification fetched',
        data: AppNotification.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<AppNotification>(e);
    }
  }

  // #173: PATCH /api/notification/v1/:organizationId/:id/read
  Future<ApiResponse<AppNotification>> markAsRead(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$id/read',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<AppNotification>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Marked as read',
        data: AppNotification.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<AppNotification>(e);
    }
  }
}
