import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/json_utils.dart';
import '../../models/recipe_cost.dart';

final recipeCostApiServiceProvider = Provider<RecipeCostApiService>((ref) {
  return RecipeCostApiService(ref.watch(dioProvider));
});

class RecipeCostApiService {
  final Dio _dio;

  RecipeCostApiService(this._dio);

  String _basePath(String organizationId) => '/api/recipe-cost/v1/$organizationId';

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

  // #79: GET /api/recipe-cost/v1/:organizationId (Active)
  Future<ApiResponse<List<RecipeCost>>> getActive(String organizationId) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final recipes = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => RecipeCost.fromJson(e))
          .toList();
      return ApiResponse<List<RecipeCost>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: recipes,
      );
    } catch (e) {
      return _errorResponse<List<RecipeCost>>(e);
    }
  }

  // #80: POST /api/recipe-cost/v1/:organizationId
  Future<ApiResponse<RecipeCost>> create(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(_basePath(organizationId), data: data);
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final mapData = JsonUtils.extractMap(rawData);
      final recipe = RecipeCost.fromJson(mapData);
      return ApiResponse<RecipeCost>(
        success: response.data['ok'] == true || response.statusCode == 201 || response.statusCode == 200,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Recipe cost created successfully',
        data: recipe,
      );
    } catch (e) {
      return _errorResponse<RecipeCost>(e);
    }
  }

  // #81: GET /api/recipe-cost/v1/:organizationId/inactive
  Future<ApiResponse<List<RecipeCost>>> getInactive(String organizationId) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/inactive');
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final recipes = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => RecipeCost.fromJson(e))
          .toList();
      return ApiResponse<List<RecipeCost>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: recipes,
      );
    } catch (e) {
      return _errorResponse<List<RecipeCost>>(e);
    }
  }

  // #82: GET /api/recipe-cost/v1/:organizationId/:recipeCostId
  Future<ApiResponse<RecipeCost>> getById(
    String organizationId,
    String recipeCostId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$recipeCostId');
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final mapData = JsonUtils.extractMap(rawData);
      final recipe = RecipeCost.fromJson(mapData);
      return ApiResponse<RecipeCost>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: recipe,
      );
    } catch (e) {
      return _errorResponse<RecipeCost>(e);
    }
  }

  // #83: PUT /api/recipe-cost/v1/:organizationId/:recipeCostId
  Future<ApiResponse<RecipeCost>> update(
    String organizationId,
    String recipeCostId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '${_basePath(organizationId)}/$recipeCostId',
        data: data,
      );
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final mapData = JsonUtils.extractMap(rawData);
      final recipe = RecipeCost.fromJson(mapData);
      return ApiResponse<RecipeCost>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Recipe cost updated successfully',
        data: recipe,
      );
    } catch (e) {
      return _errorResponse<RecipeCost>(e);
    }
  }

  // #84: PATCH /api/recipe-cost/v1/:organizationId/:recipeCostId/restore
  Future<ApiResponse<RecipeCost>> restore(
    String organizationId,
    String recipeCostId,
  ) async {
    try {
      final response = await _dio.patch('${_basePath(organizationId)}/$recipeCostId/restore');
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final mapData = JsonUtils.extractMap(rawData);
      final recipe = RecipeCost.fromJson(mapData);
      return ApiResponse<RecipeCost>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Recipe cost restored successfully',
        data: recipe,
      );
    } catch (e) {
      return _errorResponse<RecipeCost>(e);
    }
  }

  // #85: DELETE /api/recipe-cost/v1/:organizationId/:recipeCostId (Soft delete)
  Future<ApiResponse<RecipeCost>> deactivate(
    String organizationId,
    String recipeCostId,
  ) async {
    try {
      final response = await _dio.delete('${_basePath(organizationId)}/$recipeCostId');
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final mapData = JsonUtils.extractMap(rawData);
      final recipe = RecipeCost.fromJson(mapData);
      return ApiResponse<RecipeCost>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Recipe cost deleted successfully',
        data: recipe,
      );
    } catch (e) {
      return _errorResponse<RecipeCost>(e);
    }
  }

  // #86: DELETE /api/recipe-cost/v1/:organizationId/:recipeCostId/hard (Permanent delete)
  Future<ApiResponse<void>> hardDelete(
    String organizationId,
    String recipeCostId,
  ) async {
    try {
      final response = await _dio.delete('${_basePath(organizationId)}/$recipeCostId/hard');
      return ApiResponse<void>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Recipe cost permanently deleted',
        data: null,
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }
}
