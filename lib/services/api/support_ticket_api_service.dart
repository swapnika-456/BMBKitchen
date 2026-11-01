import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/support_ticket.dart';

final supportTicketApiServiceProvider = Provider<SupportTicketApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return SupportTicketApiService(dio);
});

/// Support Ticket API Service covering endpoints #137 to #144
/// Base: /api/support-ticket/v1/:organizationId
class SupportTicketApiService {
  final Dio _dio;

  SupportTicketApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/support-ticket/v1/$organizationId';

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

  // #137: POST /api/support-ticket/v1/:organizationId
  // Body: { outletId (required), subject (required), category?, priority?, details? }
  Future<ApiResponse<SupportTicket>> createTicket(
    String organizationId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        _basePath(organizationId),
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SupportTicket>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Ticket created',
        data: SupportTicket.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SupportTicket>(e);
    }
  }

  // #138: GET /api/support-ticket/v1/:organizationId
  // Query: outletId?, status?, category?, priority?
  Future<ApiResponse<List<SupportTicket>>> getActiveTickets(
    String organizationId, {
    String? outletId,
    String? status,
    String? category,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (outletId != null && outletId.isNotEmpty) {
        queryParams['outletId'] = outletId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (priority != null && priority.isNotEmpty) {
        queryParams['priority'] = priority;
      }

      final response = await _dio.get(
        _basePath(organizationId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final listData = JsonUtils.extractList(response.data['data']);
      final tickets = listData.map((item) => SupportTicket.fromJson(item)).toList();

      return ApiResponse<List<SupportTicket>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: tickets,
      );
    } catch (e) {
      return _errorResponse<List<SupportTicket>>(e);
    }
  }

  // #139: GET /api/support-ticket/v1/:organizationId/inactive
  Future<ApiResponse<List<SupportTicket>>> getInactiveTickets(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/inactive');
      final listData = JsonUtils.extractList(response.data['data']);
      final tickets = listData.map((item) => SupportTicket.fromJson(item)).toList();

      return ApiResponse<List<SupportTicket>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: tickets,
      );
    } catch (e) {
      return _errorResponse<List<SupportTicket>>(e);
    }
  }

  // #140: GET /api/support-ticket/v1/:organizationId/:id
  Future<ApiResponse<SupportTicket>> getTicketById(
    String organizationId,
    String ticketId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$ticketId');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SupportTicket>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? '',
        data: SupportTicket.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SupportTicket>(e);
    }
  }

  // #141: PATCH /api/support-ticket/v1/:organizationId/:id/status
  // Body: { status }
  Future<ApiResponse<SupportTicket>> updateStatus(
    String organizationId,
    String ticketId,
    String status,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$ticketId/status',
        data: {'status': status},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SupportTicket>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Ticket status updated',
        data: SupportTicket.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SupportTicket>(e);
    }
  }

  // #142: PATCH /api/support-ticket/v1/:organizationId/:id/deactivate
  Future<ApiResponse<SupportTicket>> deactivateTicket(
    String organizationId,
    String ticketId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$ticketId/deactivate',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SupportTicket>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Ticket deactivated',
        data: SupportTicket.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SupportTicket>(e);
    }
  }

  // #143: PATCH /api/support-ticket/v1/:organizationId/:id/restore
  Future<ApiResponse<SupportTicket>> restoreTicket(
    String organizationId,
    String ticketId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$ticketId/restore',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SupportTicket>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Ticket restored',
        data: SupportTicket.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SupportTicket>(e);
    }
  }

  // #144: DELETE /api/support-ticket/v1/:organizationId/:id
  Future<ApiResponse<bool>> deleteTicket(
    String organizationId,
    String ticketId,
  ) async {
    try {
      final response = await _dio.delete(
        '${_basePath(organizationId)}/$ticketId',
      );
      return ApiResponse<bool>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Ticket deleted',
        data: true,
      );
    } catch (e) {
      return _errorResponse<bool>(e);
    }
  }
}
