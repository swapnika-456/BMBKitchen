import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/role.dart';
import '../../../../services/api/role_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final roleControllerProvider =
    AsyncNotifierProvider<RoleController, List<Role>>(() {
      return RoleController();
    });

class RoleController extends AsyncNotifier<List<Role>> {
  @override
  Future<List<Role>> build() async {
    return _fetchRoles();
  }

  Future<List<Role>> _fetchRoles() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return [];
    }

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.getActiveRoles(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Role.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Role>> fetchInactiveRoles() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.getInactiveRoles(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Role.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> createRole(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.createRole(user.organizationId, data);

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> updateRole(String roleId, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.updateRole(
      user.organizationId,
      roleId,
      data,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> deactivateRole(String roleId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.deactivateRole(
      user.organizationId,
      roleId,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> restoreRole(String roleId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.restoreRole(user.organizationId, roleId);

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> deleteRole(String roleId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);
    final response = await apiService.deleteRole(user.organizationId, roleId);

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRoles());
  }

  Future<bool> updateRolePermissions(
    String roleId,
    List<String> permissions,
  ) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(roleApiServiceProvider);

    // Update API
    final response = await apiService.updateRole(user.organizationId, roleId, {
      'permissions': permissions,
    });

    if (response.success) {
      // Refresh local state
      await refresh();
      return true;
    } else {
      // Ideally show error toast
      return false;
    }
  }
}
