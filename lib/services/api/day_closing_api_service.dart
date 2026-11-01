import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/json_utils.dart';
import '../../models/day_closing.dart';

final dayClosingApiServiceProvider = Provider<DayClosingApiService>((ref) {
  return DayClosingApiService(ref.watch(dioProvider));
});

class DayClosingApiService {
  final Dio _dio;

  DayClosingApiService(this._dio);

  String _basePath(String organizationId) => '/api/day-closing/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic e) {
    if (e is DioException && e.response != null) {
      final res = e.response!;
      final body = res.data;
      String message = 'Unknown error';
      if (body is Map) {
        if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
          message = body['message'].toString();
        } else if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
          message = body['error'].toString();
        }
      } else if (body is String && body.trim().isNotEmpty) {
        message = body;
      }
      return ApiResponse<T>(
        success: false,
        statusCode: res.statusCode ?? 500,
        message: message,
        data: null,
      );
    }
    return ApiResponse<T>(
      success: false,
      statusCode: 500,
      message: e.toString(),
      data: null,
    );
  }

  // #104: GET /api/day-closing/v1/:organizationId/:outletId/summary?date=YYYY-MM-DD
  Future<ApiResponse<DayClosingSummary>> getSummary(
    String organizationId,
    String outletId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/$outletId/summary',
        queryParameters: {'date': date},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<DayClosingSummary>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: DayClosingSummary.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<DayClosingSummary>(e);
    }
  }

  // #105: POST /api/day-closing/v1/:organizationId
  Future<ApiResponse<DayClosing>> createClosing(
    String organizationId, {
    required String outletId,
    required String closingDate,
    required double actualCash,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'outletId': outletId,
        'closingDate': closingDate,
        'actualCash': actualCash,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await _dio.post(
        _basePath(organizationId),
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<DayClosing>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Day closing saved successfully',
        data: DayClosing.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<DayClosing>(e);
    }
  }

  // #106: GET /api/day-closing/v1/:organizationId/:outletId/:date
  Future<ApiResponse<DayClosing?>> getClosing(
    String organizationId,
    String outletId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/$outletId/$date',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<DayClosing?>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: DayClosing.fromJson(mapData),
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        // 404 means not closed yet for that date
        return ApiResponse<DayClosing?>(
          success: true,
          statusCode: 404,
          message: 'No closing recorded for this date',
          data: null,
        );
      }
      return _errorResponse<DayClosing?>(e);
    }
  }

  // #107: GET /api/day-closing/v1/:organizationId/:outletId?limit=
  Future<ApiResponse<List<DayClosing>>> getHistory(
    String organizationId,
    String outletId, {
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': ?limit,
      };

      final response = await _dio.get(
        '${_basePath(organizationId)}/$outletId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => DayClosing.fromJson(e))
          .toList();

      return ApiResponse<List<DayClosing>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<DayClosing>>(e);
    }
  }

  // #108: PATCH /api/day-closing/v1/:organizationId/:id/reopen
  Future<ApiResponse<DayClosing>> reopenClosing(
    String organizationId,
    String id, {
    String? reason,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

      final response = await _dio.patch(
        '${_basePath(organizationId)}/$id/reopen',
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<DayClosing>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Day closing reopened',
        data: DayClosing.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<DayClosing>(e);
    }
  }
}
