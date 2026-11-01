import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/printer.dart';

final printerApiServiceProvider = Provider<PrinterApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return PrinterApiService(dio);
});

class PrinterApiService {
  final Dio _dio;

  PrinterApiService(this._dio);

  String _basePath(String organizationId) => '/api/printer/v1/$organizationId';

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

  /// #129 POST /api/printer/v1/:organizationId
  /// Owner/Admin/CTO. Body: { outletId (required), name (required), type (required),
  /// printerModel?, conn?, size?, copies?, categories? }
  Future<ApiResponse<Printer>> createPrinter(
    String organizationId, {
    required String outletId,
    required String name,
    required String type, // "Bill" | "KOT"
    String? printerModel,
    String? conn,
    String? size,
    int? copies,
    List<String>? categories,
  }) async {
    try {
      final body = <String, dynamic>{
        'outletId': outletId,
        'name': name,
        'type': type,
        if (printerModel != null && printerModel.isNotEmpty) 'printerModel': printerModel,
        if (conn != null && conn.isNotEmpty) 'conn': conn,
        if (size != null && size.isNotEmpty) 'size': size,
        'copies': ?copies,
        'categories': ?categories,
      };

      final response = await _dio.post(_basePath(organizationId), data: body);
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Printer>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Printer created',
        data: Printer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Printer>(e);
    }
  }

  /// #130 GET /api/printer/v1/:organizationId
  /// Owner/Admin/CTO/Staff. Query: outletId? -> data: printers
  Future<ApiResponse<List<Printer>>> getActivePrinters(
    String organizationId, {
    String? outletId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
      };

      final response = await _dio.get(
        _basePath(organizationId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final listData = JsonUtils.extractList(response.data['data']);
      final printers = listData
          .map((e) => Printer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return ApiResponse<List<Printer>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: printers,
      );
    } catch (e) {
      return _errorResponse<List<Printer>>(e);
    }
  }

  /// #131 GET /api/printer/v1/:organizationId/inactive
  /// Owner/Admin/CTO. Query: outletId? -> data: printers
  Future<ApiResponse<List<Printer>>> getInactivePrinters(
    String organizationId, {
    String? outletId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
      };

      final response = await _dio.get(
        '${_basePath(organizationId)}/inactive',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final listData = JsonUtils.extractList(response.data['data']);
      final printers = listData
          .map((e) => Printer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return ApiResponse<List<Printer>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: printers,
      );
    } catch (e) {
      return _errorResponse<List<Printer>>(e);
    }
  }

  /// #132 GET /api/printer/v1/:organizationId/:id
  /// Owner/Admin/CTO/Staff -> data: printer
  Future<ApiResponse<Printer>> getPrinter(
    String organizationId,
    String printerId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$printerId');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Printer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: Printer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Printer>(e);
    }
  }

  /// #133 PATCH /api/printer/v1/:organizationId/:id
  /// Owner/Admin/CTO. Body: same fields, all optional
  Future<ApiResponse<Printer>> updatePrinter(
    String organizationId,
    String printerId, {
    String? outletId,
    String? name,
    String? type,
    String? printerModel,
    String? conn,
    String? size,
    int? copies,
    List<String>? categories,
  }) async {
    try {
      final body = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        if (name != null && name.isNotEmpty) 'name': name,
        if (type != null && type.isNotEmpty) 'type': type,
        'printerModel': ?printerModel,
        'conn': ?conn,
        if (size != null && size.isNotEmpty) 'size': size,
        'copies': ?copies,
        'categories': ?categories,
      };

      final response = await _dio.patch(
        '${_basePath(organizationId)}/$printerId',
        data: body,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Printer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Printer updated',
        data: Printer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Printer>(e);
    }
  }

  /// #134 PATCH /api/printer/v1/:organizationId/:id/deactivate
  /// Owner/Admin/CTO -> data: printer
  Future<ApiResponse<Printer>> deactivatePrinter(
    String organizationId,
    String printerId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$printerId/deactivate',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Printer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Printer deactivated',
        data: Printer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Printer>(e);
    }
  }

  /// #135 PATCH /api/printer/v1/:organizationId/:id/restore
  /// Owner/Admin/CTO -> data: printer
  Future<ApiResponse<Printer>> restorePrinter(
    String organizationId,
    String printerId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$printerId/restore',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Printer>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Printer restored',
        data: Printer.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Printer>(e);
    }
  }

  /// #136 DELETE /api/printer/v1/:organizationId/:id
  /// Owner/Admin/CTO -> { ok: true, message: "Printer deleted" }
  Future<ApiResponse<void>> deletePrinter(
    String organizationId,
    String printerId,
  ) async {
    try {
      final response = await _dio.delete(
        '${_basePath(organizationId)}/$printerId',
      );
      return ApiResponse<void>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Printer deleted',
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }
}
