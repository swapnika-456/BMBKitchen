import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../services/api/auth_api_service.dart';
import '../../../services/api/organization_api_service.dart';
import '../../../core/local_storage/session_manager.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApiService = ref.watch(authApiServiceProvider);
  final orgApiService = ref.watch(organizationApiServiceProvider);
  return AuthRepository(authApiService, orgApiService);
});

class AuthRepository {
  final AuthApiService _apiService;
  final OrganizationApiService _orgApiService;

  AuthRepository(this._apiService, this._orgApiService);

  Future<User?> login(String email, String password) async {
    final response = await _apiService.login({
      'email': email,
      'password': password,
    });

    if (response.success && response.data != null) {
      final data = response.data!;

      // Parse organizationId, which comes as a nested object in login response
      final orgData = data['organizationId'];
      final orgId = orgData is Map
          ? orgData['_id'] as String?
          : orgData as String?;

      final userId = data['_id'] as String?;
      final role = data['role'] as String? ?? 'staff';
      final userName = data['userName'] as String? ?? '';

      if (orgId != null && userId != null) {
        await SessionManager.saveSession(
          organizationId: orgId,
          userId: userId,
          role: role,
          userName: userName,
        );
      }
      return User.fromJson(data);
    }
    throw Exception(response.message);
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String organizationId,
  }) async {
    final response = await _apiService.register({
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'organizationId': organizationId,
    });

    if (response.success && response.data != null) {
      return User.fromJson(response.data!);
    }
    throw Exception(response.message);
  }

  Future<User?> registerOrganization({
    required String userName,
    required String email,
    required String password,
    required String organizationName,
    String? phone,
  }) async {
    final response = await _orgApiService.register({
      'userName': userName,
      'email': email,
      'password': password,
      'organizationName': organizationName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    if (response.success && response.data != null) {
      final data = response.data!;

      // Parse organizationId, which comes as a string in register response
      final orgId = data['organizationId'] as String?;
      final userId = data['_id'] as String?;
      final role = data['role'] as String? ?? 'owner';
      final name = data['userName'] as String? ?? '';

      if (orgId != null && userId != null) {
        await SessionManager.saveSession(
          organizationId: orgId,
          userId: userId,
          role: role,
          userName: name,
        );
      }
      return User.fromJson(data);
    }
    throw Exception(response.message);
  }

  Future<User?> checkAuth() async {
    final response = await _apiService.getMe();

    if (response.success && response.data != null) {
      // Just in case we need to refresh the session cache on app start
      final data = response.data!;
      final orgData = data['organizationId'];
      final orgId = orgData is Map
          ? orgData['_id'] as String?
          : orgData as String?;
      final userId = data['_id'] as String?;
      final role = data['role'] as String? ?? 'staff';
      final userName = data['userName'] as String? ?? '';

      if (orgId != null && userId != null) {
        await SessionManager.saveSession(
          organizationId: orgId,
          userId: userId,
          role: role,
          userName: userName,
        );
      }
      return User.fromJson(data);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // ignore
    }
    await SessionManager.clear();
  }
}
