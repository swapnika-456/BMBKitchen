import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/outlet.dart';
import '../../../../services/api/outlet_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final outletControllerProvider =
    AsyncNotifierProvider<OutletController, List<Outlet>>(() {
      return OutletController();
    });

class OutletController extends AsyncNotifier<List<Outlet>> {
  @override
  Future<List<Outlet>> build() async {
    return _fetchOutlets();
  }

  Future<List<Outlet>> _fetchOutlets() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return [];
    }

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.getActiveOutlets(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Outlet.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Outlet>> fetchInactiveOutlets() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.getInactiveOutlets(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Outlet.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> createOutlet(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.createOutlet(user.organizationId, data);

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> updateOutlet(String outletId, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.updateOutlet(
      user.organizationId,
      outletId,
      data,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> deactivateOutlet(String outletId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.deactivateOutlet(
      user.organizationId,
      outletId,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> restoreOutlet(String outletId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.restoreOutlet(
      user.organizationId,
      outletId,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> deleteOutlet(String outletId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final apiService = ref.read(outletApiServiceProvider);
    final response = await apiService.deleteOutlet(
      user.organizationId,
      outletId,
    );

    if (response.success) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOutlets());
  }
}
