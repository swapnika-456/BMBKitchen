import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio);
});

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  // ---------- Routes ----------
  static const String _register = '/api/auth/v1/register';
  static const String _login = '/api/auth/v1/login';
  static const String _forgotPassword = '/api/auth/v1/forgot-password';
  static const String _isAuthenticated = '/api/auth/v1/isauthenticated';
  static const String _me = '/api/auth/v1/me';
  static const String _logout = '/api/auth/v1/logout';
  static const String _updatePermissions = '/api/auth/v1/update-permissions';
  static const String _users = '/api/auth/';

  static String _resetPassword(String userId, String token) =>
      '/api/auth/v1/reset-password/$userId/$token';

  static String _deactivateUser(String userId) => '/api/auth/v1/$userId/deactivate';
  static String _recoverUser(String userId) => '/api/auth/v1/$userId/recover';
  static String _deleteUser(String userId) => '/api/auth/v1/$userId/delete';
  static String _updateUserRole(String userId) => '/api/auth/v1/$userId/role';

  // ---------- Methods ----------
  Future<ApiResponse<Map<String, dynamic>>> register(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(_register, data: data);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(_login, data: data);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(_forgotPassword, data: {'email': email});
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> resetPassword(
    String userId,
    String token,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        _resetPassword(userId, token),
        data: {'password': password},
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> isAuthenticated() async {
    try {
      final response = await _dio.get(_isAuthenticated);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMe([String? userId]) async {
    try {
      final response = await _dio.get(_me);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final data = body is Map ? (body['data'] ?? body) : null;
        if (data is Map<String, dynamic>) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            statusCode: 200,
            message: 'Success',
            data: data,
          );
        }
      }
    } catch (_) {}

    // Fallback 1: isAuthenticated (#5)
    try {
      final isAuth = await isAuthenticated();
      if (isAuth.success && isAuth.data != null) {
        final userData = isAuth.data!['user'] ?? isAuth.data;
        if (userData is Map<String, dynamic>) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            statusCode: 200,
            message: 'Success',
            data: userData,
          );
        }
      }
    } catch (_) {}

    // Fallback 2: user by id (#9)
    if (userId != null && userId.isNotEmpty) {
      try {
        final response = await _dio.get('/api/auth/v1/$userId');
        if (response.statusCode == 200 && response.data != null) {
          final body = response.data;
          final data = body is Map ? body['data'] : null;
          if (data is Map<String, dynamic>) {
            return ApiResponse<Map<String, dynamic>>(
              success: true,
              statusCode: 200,
              message: 'Success',
              data: data,
            );
          }
        }
      } catch (_) {}
    }

    return ApiResponse<Map<String, dynamic>>(
      success: false,
      statusCode: 400,
      message: 'Failed to fetch current user',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserById(String userId) async {
    try {
      final response = await _dio.get('/api/auth/v1/$userId');
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  /// Endpoint #7A: PUT /api/auth/v1/:organizationId/:userId/profile-image
  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage(
    String organizationId,
    String userId,
    MultipartFile file,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': file,
      });
      final response = await _dio.put(
        '/api/auth/v1/$organizationId/$userId/profile-image',
        data: formData,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }


  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _dio.post(_logout);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePermissions(
    String userId,
    List<String> permissions,
  ) async {
    try {
      final response = await _dio.post(
        _updatePermissions,
        data: {'userId': userId, 'permissions': permissions},
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deactivateUser(String userId) async {
    try {
      final response = await _dio.patch(_deactivateUser(userId));
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> recoverUser(String userId) async {
    try {
      final response = await _dio.patch(_recoverUser(userId));
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data ?? {}, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteUser(String userId) async {
    try {
      final response = await _dio.delete(_deleteUser(userId));
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data ?? {}, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserRole(String userId, String role) async {
    try {
      final response = await _dio.put(_updateUserRole(userId), data: {'role': role});
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data ?? {}, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getOrganizationUsers({
    int? page,
    int? limit,
    String? search,
    String? role,
  }) async {
    try {
      final response = await _dio.get(
        _users,
        queryParameters: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null && role.isNotEmpty) 'role': role,
        },
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;

      if (response.statusCode == 200) {
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data.containsKey('users') && data['users'] is List) {
            list = data['users'] as List;
          } else {
            list = [data];
          }
        }

        return ApiResponse<List<dynamic>>(
          success: true,
          statusCode: 200,
          message: 'Success',
          data: list,
        );
      }

      return ApiResponse<List<dynamic>>(
        success: false,
        statusCode: response.statusCode ?? 400,
        message:
            (body is Map ? body['message'] : null) ??
            'Failed to get organization users',
        data: const [],
      );
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
        data: const [],
      );
    }
  }

  // ---------- Helpers ----------
  ApiResponse<T> _errorResponse<T>(Object e) {
    return ApiResponse<T>(
      success: false,
      statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
      message: ApiExceptions.getDetailedErrorMessage(e),
    );
  }
}
