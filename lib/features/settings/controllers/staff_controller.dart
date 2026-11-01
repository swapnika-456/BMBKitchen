import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../../models/user.dart';

class StaffListParams {
  final int page;
  final int limit;
  final String search;
  final String? role;

  StaffListParams({
    this.page = 1,
    this.limit = 20,
    this.search = '',
    this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffListParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          search == other.search &&
          role == other.role;

  @override
  int get hashCode =>
      page.hashCode ^ limit.hashCode ^ search.hashCode ^ role.hashCode;
  StaffListParams copyWith({
    int? page,
    int? limit,
    String? search,
    Wrapped<String?>? role,
  }) {
    return StaffListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      role: role != null ? role.value : this.role,
    );
  }
}

class Wrapped<T> {
  final T value;
  const Wrapped(this.value);
}

class StaffFilterNotifier extends Notifier<StaffListParams> {
  @override
  StaffListParams build() => StaffListParams();

  void updateFilter(StaffListParams newFilter) {
    state = newFilter;
  }
}

final staffFilterProvider =
    NotifierProvider<StaffFilterNotifier, StaffListParams>(
      () => StaffFilterNotifier(),
    );

class StaffListNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    ref.watch(staffFilterProvider); // Watch to trigger rebuilds on filter changes
    return _fetchPage(1);
  }

  Future<List<User>> _fetchPage(int page) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final params = ref.read(staffFilterProvider);
    final apiService = ref.read(authApiServiceProvider);

    final response = await apiService.getOrganizationUsers(
      page: page,
      limit: params.limit,
      search: params.search,
      role: params.role,
    );

    if (response.success && response.data != null) {
      return response.data!.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !state.hasValue) return;
    
    final currentList = state.value!;
    final limit = ref.read(staffFilterProvider).limit;
    
    // Only load more if we got a full page last time
    if (currentList.length % limit != 0 || currentList.isEmpty) return;
    
    final nextPage = (currentList.length ~/ limit) + 1;
    
    state = const AsyncValue.loading();
    try {
      final newItems = await _fetchPage(nextPage);
      state = AsyncValue.data([...currentList, ...newItems]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }
}

final staffListProvider = AsyncNotifierProvider<StaffListNotifier, List<User>>(
  () => StaffListNotifier(),
);
