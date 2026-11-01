import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/central_kitchen_transfer.dart';

final centralKitchenApiServiceProvider = Provider<CentralKitchenApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CentralKitchenApiService(dio);
});

/// Central Kitchen API Service covering endpoints #119 to #126
/// from BMB_KITCHEN_BACKEND_API_8:
/// Base: /api/central-kitchen/v1/:organizationId
class CentralKitchenApiService {
  final Dio _dio;

  CentralKitchenApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/central-kitchen/v1/$organizationId';

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

  // #120: GET /api/central-kitchen/v1/:organizationId (Active transfers)
  Future<ApiResponse<List<CentralKitchenTransfer>>> getActiveTransfers(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      final listData = JsonUtils.extractList(response.data['data']);
      final transfers = listData
          .map((item) => CentralKitchenTransfer.fromJson(item))
          .toList();

      return ApiResponse<List<CentralKitchenTransfer>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Transfers loaded',
        data: transfers,
      );
    } catch (e) {
      return _errorResponse<List<CentralKitchenTransfer>>(e);
    }
  }

  // #119: GET /api/central-kitchen/v1/:organizationId/inactive (Inactive transfers)
  Future<ApiResponse<List<CentralKitchenTransfer>>> getInactiveTransfers(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/inactive');
      final listData = JsonUtils.extractList(response.data['data']);
      final transfers = listData
          .map((item) => CentralKitchenTransfer.fromJson(item))
          .toList();

      return ApiResponse<List<CentralKitchenTransfer>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Inactive transfers loaded',
        data: transfers,
      );
    } catch (e) {
      return _errorResponse<List<CentralKitchenTransfer>>(e);
    }
  }

  // #122: GET /api/central-kitchen/v1/:organizationId/:id
  Future<ApiResponse<CentralKitchenTransfer>> getTransferById(
    String organizationId,
    String transferId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$transferId');
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<CentralKitchenTransfer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Transfer loaded',
        data: CentralKitchenTransfer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<CentralKitchenTransfer>(e);
    }
  }

  // #121: POST /api/central-kitchen/v1/:organizationId
  // Body: { fromOutletId, toOutletId, lines: [{ inventoryId, quantity }] }
  Future<ApiResponse<CentralKitchenTransfer>> createTransfer(
    String organizationId, {
    required String fromOutletId,
    required String toOutletId,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final body = <String, dynamic>{
        'fromOutletId': fromOutletId,
        'toOutletId': toOutletId,
        'lines': lines,
      };

      final response = await _dio.post(_basePath(organizationId), data: body);
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<CentralKitchenTransfer>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Transfer created',
        data: CentralKitchenTransfer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<CentralKitchenTransfer>(e);
    }
  }

  // #123: PATCH /api/central-kitchen/v1/:organizationId/:id/stage
  // Body: { status }
  Future<ApiResponse<CentralKitchenTransfer>> updateStage(
    String organizationId,
    String transferId,
    String status,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$transferId/stage',
        data: {'status': status},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<CentralKitchenTransfer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Stage updated',
        data: CentralKitchenTransfer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<CentralKitchenTransfer>(e);
    }
  }

  // #124: PATCH /api/central-kitchen/v1/:organizationId/:id/deactivate
  Future<ApiResponse<CentralKitchenTransfer>> deactivateTransfer(
    String organizationId,
    String transferId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$transferId/deactivate',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<CentralKitchenTransfer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Transfer deactivated',
        data: CentralKitchenTransfer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<CentralKitchenTransfer>(e);
    }
  }

  // #125: PATCH /api/central-kitchen/v1/:organizationId/:id/restore
  Future<ApiResponse<CentralKitchenTransfer>> restoreTransfer(
    String organizationId,
    String transferId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$transferId/restore',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<CentralKitchenTransfer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Transfer restored',
        data: CentralKitchenTransfer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<CentralKitchenTransfer>(e);
    }
  }

  // #126: DELETE /api/central-kitchen/v1/:organizationId/:id
  // Role: Owner, CTO only (no admin per PDF)
  Future<ApiResponse<void>> deleteTransfer(
    String organizationId,
    String transferId,
  ) async {
    try {
      final response = await _dio.delete(
        '${_basePath(organizationId)}/$transferId',
      );

      return ApiResponse<void>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Transfer deleted',
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }
}
