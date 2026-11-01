import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/json_utils.dart';
import '../../models/wastage_adjustment.dart';

final wastageAdjustmentApiServiceProvider =
    Provider<WastageAdjustmentApiService>((ref) {
  return WastageAdjustmentApiService(ref.watch(dioProvider));
});

class WastageAdjustmentApiService {
  final Dio _dio;

  WastageAdjustmentApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/wastage-adjustments/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic e) {
    if (e is DioException && e.response != null) {
      final res = e.response!;
      final body = res.data;
      String message = 'Unknown error';
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      } else if (body is String) {
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

  // #87: GET /api/wastage-adjustments/v1/:organizationId (Active)
  Future<ApiResponse<List<WastageAdjustment>>> getActive(
      String organizationId) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => WastageAdjustment.fromJson(e))
          .toList();
      return ApiResponse<List<WastageAdjustment>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<WastageAdjustment>>(e);
    }
  }

  // #88: POST /api/wastage-adjustments/v1/:organizationId
  Future<ApiResponse<WastageAdjustment>> create(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await _dio.post(_basePath(organizationId), data: data);
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final itemMap = JsonUtils.extractMap(rawData);
      return ApiResponse<WastageAdjustment>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ??
            'Wastage/adjustment created successfully',
        data: WastageAdjustment.fromJson(itemMap),
      );
    } catch (e) {
      return _errorResponse<WastageAdjustment>(e);
    }
  }

  // #89: GET /api/wastage-adjustments/v1/:organizationId/inactive
  Future<ApiResponse<List<WastageAdjustment>>> getInactive(
      String organizationId) async {
    try {
      final response =
          await _dio.get('${_basePath(organizationId)}/inactive');
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => WastageAdjustment.fromJson(e))
          .toList();
      return ApiResponse<List<WastageAdjustment>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<WastageAdjustment>>(e);
    }
  }

  // #90: GET /api/wastage-adjustments/v1/:organizationId/:wastageAdjustmentId
  Future<ApiResponse<WastageAdjustment>> getById(
    String organizationId,
    String wastageAdjustmentId,
  ) async {
    try {
      final response = await _dio
          .get('${_basePath(organizationId)}/$wastageAdjustmentId');
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final itemMap = JsonUtils.extractMap(rawData);
      return ApiResponse<WastageAdjustment>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: WastageAdjustment.fromJson(itemMap),
      );
    } catch (e) {
      return _errorResponse<WastageAdjustment>(e);
    }
  }

  // #91: PUT /api/wastage-adjustments/v1/:organizationId/:wastageAdjustmentId
  Future<ApiResponse<WastageAdjustment>> update(
    String organizationId,
    String wastageAdjustmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '${_basePath(organizationId)}/$wastageAdjustmentId',
        data: data,
      );
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final itemMap = JsonUtils.extractMap(rawData);
      return ApiResponse<WastageAdjustment>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ??
            'Wastage/adjustment updated successfully',
        data: WastageAdjustment.fromJson(itemMap),
      );
    } catch (e) {
      return _errorResponse<WastageAdjustment>(e);
    }
  }

  // #92: PATCH /api/wastage-adjustments/v1/:organizationId/:wastageAdjustmentId/restore
  Future<ApiResponse<WastageAdjustment>> restore(
    String organizationId,
    String wastageAdjustmentId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$wastageAdjustmentId/restore',
      );
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final itemMap = JsonUtils.extractMap(rawData);
      return ApiResponse<WastageAdjustment>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ??
            'Wastage/adjustment restored successfully',
        data: WastageAdjustment.fromJson(itemMap),
      );
    } catch (e) {
      return _errorResponse<WastageAdjustment>(e);
    }
  }

  // #93: DELETE /api/wastage-adjustments/v1/:organizationId/:wastageAdjustmentId (Soft Delete)
  Future<ApiResponse<WastageAdjustment>> deactivate(
    String organizationId,
    String wastageAdjustmentId,
  ) async {
    try {
      final response = await _dio
          .delete('${_basePath(organizationId)}/$wastageAdjustmentId');
      final rawData =
          response.data is Map ? response.data['data'] : response.data;
      final itemMap = JsonUtils.extractMap(rawData);
      return ApiResponse<WastageAdjustment>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ??
            'Wastage/adjustment deleted successfully',
        data: WastageAdjustment.fromJson(itemMap),
      );
    } catch (e) {
      return _errorResponse<WastageAdjustment>(e);
    }
  }

  // #94: DELETE /api/wastage-adjustments/v1/:organizationId/:wastageAdjustmentId/hard (Permanent Delete)
  Future<ApiResponse<void>> hardDelete(
    String organizationId,
    String wastageAdjustmentId,
  ) async {
    try {
      final response = await _dio
          .delete('${_basePath(organizationId)}/$wastageAdjustmentId/hard');
      return ApiResponse<void>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ??
            'Wastage/adjustment permanently deleted',
        data: null,
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }
}
