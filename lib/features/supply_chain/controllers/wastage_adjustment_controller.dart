import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/wastage_adjustment.dart';
import '../../../services/api/wastage_adjustment_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/inventory_providers.dart';

/// Provides the list of active wastage & adjustment records (#87)
class ActiveWastageAdjustmentNotifier
    extends AsyncNotifier<List<WastageAdjustment>> {
  @override
  Future<List<WastageAdjustment>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(wastageAdjustmentApiServiceProvider);
    final response = await apiService.getActive(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!;
    }
    if (!response.success && response.message.isNotEmpty) {
      throw Exception(response.message);
    }
    return [];
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// #88: POST create
  Future<String?> createWastageAdjustment(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return 'User not authenticated';
    }

    final apiService = ref.read(wastageAdjustmentApiServiceProvider);
    final res = await apiService.create(user.organizationId, data);

    if (res.success) {
      ref.invalidateSelf();
      // Invalidate inventory providers so stock balances update immediately
      ref.invalidate(activeInventoryProvider);
      return null;
    }
    return res.message.isNotEmpty
        ? res.message
        : 'Failed to create wastage/adjustment record';
  }

  /// #91: PUT update
  Future<String?> updateWastageAdjustment(
      String id, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return 'User not authenticated';
    }

    final apiService = ref.read(wastageAdjustmentApiServiceProvider);
    final res = await apiService.update(user.organizationId, id, data);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeInventoryProvider);
      return null;
    }
    return res.message.isNotEmpty
        ? res.message
        : 'Failed to update wastage/adjustment record';
  }

  /// #93: DELETE soft delete
  Future<String?> deactivateWastageAdjustment(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return 'User not authenticated';
    }

    final apiService = ref.read(wastageAdjustmentApiServiceProvider);
    final res = await apiService.deactivate(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactiveWastageAdjustmentProvider);
      ref.invalidate(activeInventoryProvider);
      return null;
    }
    return res.message.isNotEmpty
        ? res.message
        : 'Failed to deactivate record';
  }
}

final activeWastageAdjustmentProvider = AsyncNotifierProvider<
    ActiveWastageAdjustmentNotifier, List<WastageAdjustment>>(
  () => ActiveWastageAdjustmentNotifier(),
);

/// Provides the list of inactive wastage & adjustment records (#89)
class InactiveWastageAdjustmentNotifier
    extends AsyncNotifier<List<WastageAdjustment>> {
  @override
  Future<List<WastageAdjustment>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(wastageAdjustmentApiServiceProvider);
    final response = await apiService.getInactive(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!;
    }
    if (!response.success && response.message.isNotEmpty) {
      throw Exception(response.message);
    }
    return [];
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// #92: PATCH restore
  Future<String?> restoreWastageAdjustment(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return 'User not authenticated';
    }

    final apiService = ref.read(wastageAdjustmentApiServiceProvider);
    final res = await apiService.restore(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeWastageAdjustmentProvider);
      ref.invalidate(activeInventoryProvider);
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to restore record';
  }

  /// #94: DELETE permanent hard delete (owner/admin only)
  Future<String?> hardDeleteWastageAdjustment(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return 'User not authenticated';
    }

    final apiService = ref.read(wastageAdjustmentApiServiceProvider);
    final res = await apiService.hardDelete(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeInventoryProvider);
      return null;
    }
    return res.message.isNotEmpty
        ? res.message
        : 'Failed to permanently delete record';
  }
}

final inactiveWastageAdjustmentProvider = AsyncNotifierProvider<
    InactiveWastageAdjustmentNotifier, List<WastageAdjustment>>(
  () => InactiveWastageAdjustmentNotifier(),
);
