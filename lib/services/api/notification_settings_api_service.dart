import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/notification_settings.dart';

final notificationSettingsApiServiceProvider =
    Provider<NotificationSettingsApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationSettingsApiService(dio);
});

/// Notification Settings API Service covering endpoints #166 to #169
/// Base: /api/notification-settings/v1/:organizationId
class NotificationSettingsApiService {
  final Dio _dio;

  NotificationSettingsApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/notification-settings/v1/$organizationId';

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

  // #166: GET /api/notification-settings/v1/:organizationId
  Future<ApiResponse<NotificationSettings>> getSettings(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<NotificationSettings>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Settings fetched',
        data: NotificationSettings.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<NotificationSettings>(e);
    }
  }

  // #167: POST /api/notification-settings/v1/:organizationId
  // Body: { channels?, events? }
  Future<ApiResponse<NotificationSettings>> setupSettings(
    String organizationId, {
    Map<String, dynamic>? channels,
    Map<String, dynamic>? events,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (channels != null) payload['channels'] = channels;
      if (events != null) payload['events'] = events;

      final response = await _dio.post(
        _basePath(organizationId),
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<NotificationSettings>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Settings initialized',
        data: NotificationSettings.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<NotificationSettings>(e);
    }
  }

  // #168: PATCH /api/notification-settings/v1/:organizationId/channels/:channel
  // Body: { isEnabled (required boolean) }
  Future<ApiResponse<NotificationSettings>> updateChannel(
    String organizationId,
    String channel,
    bool isEnabled,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/channels/$channel',
        data: {'isEnabled': isEnabled},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<NotificationSettings>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Channel updated',
        data: NotificationSettings.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<NotificationSettings>(e);
    }
  }

  // #169: PATCH /api/notification-settings/v1/:organizationId/events/:event
  // Body: { isEnabled (required boolean) }
  Future<ApiResponse<NotificationSettings>> updateEvent(
    String organizationId,
    String event,
    bool isEnabled,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/events/$event',
        data: {'isEnabled': isEnabled},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<NotificationSettings>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Event updated',
        data: NotificationSettings.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<NotificationSettings>(e);
    }
  }
}
