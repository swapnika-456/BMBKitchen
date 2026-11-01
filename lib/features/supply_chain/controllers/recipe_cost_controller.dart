import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/recipe_cost.dart';
import '../../../services/api/recipe_cost_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

// Provides the list of active recipe costs (#79)
class ActiveRecipeCostNotifier extends AsyncNotifier<List<RecipeCost>> {
  @override
  Future<List<RecipeCost>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(recipeCostApiServiceProvider);
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

  // #80: POST create
  Future<String?> createRecipeCost(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return 'User not authenticated';

    final apiService = ref.read(recipeCostApiServiceProvider);
    final res = await apiService.create(user.organizationId, data);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to create recipe cost';
  }

  // #83: PUT update
  Future<String?> updateRecipeCost(String id, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return 'User not authenticated';

    final apiService = ref.read(recipeCostApiServiceProvider);
    final res = await apiService.update(user.organizationId, id, data);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to update recipe cost';
  }

  // #85: DELETE soft delete
  Future<String?> deactivateRecipeCost(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return 'User not authenticated';

    final apiService = ref.read(recipeCostApiServiceProvider);
    final res = await apiService.deactivate(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactiveRecipeCostProvider);
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to deactivate recipe cost';
  }
}

final activeRecipeCostProvider =
    AsyncNotifierProvider<ActiveRecipeCostNotifier, List<RecipeCost>>(
  () => ActiveRecipeCostNotifier(),
);

// Provides the list of inactive recipe costs (#81)
class InactiveRecipeCostNotifier extends AsyncNotifier<List<RecipeCost>> {
  @override
  Future<List<RecipeCost>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(recipeCostApiServiceProvider);
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

  // #84: PATCH restore
  Future<String?> restoreRecipeCost(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return 'User not authenticated';

    final apiService = ref.read(recipeCostApiServiceProvider);
    final res = await apiService.restore(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeRecipeCostProvider);
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to restore recipe cost';
  }

  // #86: DELETE hard delete
  Future<String?> hardDeleteRecipeCost(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return 'User not authenticated';

    final apiService = ref.read(recipeCostApiServiceProvider);
    final res = await apiService.hardDelete(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message.isNotEmpty ? res.message : 'Failed to permanently delete recipe cost';
  }
}

final inactiveRecipeCostProvider =
    AsyncNotifierProvider<InactiveRecipeCostNotifier, List<RecipeCost>>(
  () => InactiveRecipeCostNotifier(),
);

/// Shared provider of active recipe costs keyed by menuItemId for Menu Management & POS
final recipeCostByMenuItemProvider = Provider<Map<String, RecipeCost>>((ref) {
  final activeAsync = ref.watch(activeRecipeCostProvider);
  return activeAsync.maybeWhen(
    data: (list) => {for (final rc in list) rc.menuItemId: rc},
    orElse: () => {},
  );
});
