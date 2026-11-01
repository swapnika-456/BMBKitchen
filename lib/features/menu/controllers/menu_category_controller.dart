import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/menu_category.dart';
import '../../../services/api/menu_category_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final menuCategoryDropdownProvider = FutureProvider<List<MenuCategory>>((
  ref,
) async {
  final user = ref.watch(authControllerProvider).value;
  if (user?.organizationId == null || user!.organizationId.isEmpty) return [];

  final api = ref.read(menuCategoryApiProvider);
  final res = await api.getDropdown(user.organizationId);
  if (res.success && res.data != null) {
    return res.data!;
  }
  return [];
});

final menuCategoryControllerProvider =
    AsyncNotifierProvider<MenuCategoryController, List<MenuCategory>>(
      MenuCategoryController.new,
    );

class MenuCategoryController extends AsyncNotifier<List<MenuCategory>> {
  @override
  Future<List<MenuCategory>> build() async {
    return fetchActive();
  }

  Future<List<MenuCategory>> fetchActive() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty) return [];

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.getActive(user.organizationId);

    if (res.success && res.data != null) {
      return res.data!;
    }

    if (!res.success) {
      throw res.message;
    }

    return [];
  }

  Future<List<MenuCategory>> fetchInactive() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty) return [];

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.getInactive(user.organizationId);

    if (res.success && res.data != null) {
      return res.data!;
    }

    if (!res.success) {
      throw res.message;
    }

    return [];
  }

  Future<String?> createCategory({
    required String name,
    String? description,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.create(
      user.organizationId,
      name: name,
      description: description,
    );

    if (res.success && res.data != null) {
      ref.invalidateSelf();
      ref.invalidate(menuCategoryDropdownProvider);
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to create category';
  }

  Future<String?> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.update(
      user.organizationId,
      id,
      name: name,
      description: description,
    );

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(menuCategoryDropdownProvider);
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to update category';
  }

  Future<String?> deactivateCategory(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.deactivate(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(menuCategoryDropdownProvider);
      return null;
    }

    return res.message.isNotEmpty
        ? res.message
        : 'Failed to deactivate category';
  }

  Future<String?> recoverCategory(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.recover(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(menuCategoryDropdownProvider);
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to recover category';
  }

  Future<String?> hardDeleteCategory(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuCategoryApiProvider);
    final res = await api.hardDelete(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(menuCategoryDropdownProvider);
      return null;
    }

    return res.message.isNotEmpty
        ? res.message
        : 'Failed to permanently delete category';
  }
}
