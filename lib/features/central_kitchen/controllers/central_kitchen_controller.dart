import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/central_kitchen_transfer.dart';
import '../../../services/api/central_kitchen_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class CentralKitchenState {
  final List<CentralKitchenTransfer> activeTransfers;
  final List<CentralKitchenTransfer> inactiveTransfers;
  final bool showInactive;
  final String searchQuery;
  final String? statusFilter; // null (All) | Requested | Approved | Dispatched | Received
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const CentralKitchenState({
    this.activeTransfers = const [],
    this.inactiveTransfers = const [],
    this.showInactive = false,
    this.searchQuery = '',
    this.statusFilter,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  CentralKitchenState copyWith({
    List<CentralKitchenTransfer>? activeTransfers,
    List<CentralKitchenTransfer>? inactiveTransfers,
    bool? showInactive,
    String? searchQuery,
    String? Function()? statusFilter,
    bool? isSubmitting,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return CentralKitchenState(
      activeTransfers: activeTransfers ?? this.activeTransfers,
      inactiveTransfers: inactiveTransfers ?? this.inactiveTransfers,
      showInactive: showInactive ?? this.showInactive,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  List<CentralKitchenTransfer> get displayedTransfers {
    final source = showInactive ? inactiveTransfers : activeTransfers;
    return source.where((t) {
      if (statusFilter != null && t.status != statusFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchNo = t.transferNo.toLowerCase().contains(q);
        final matchFrom = t.fromOutletName.toLowerCase().contains(q);
        final matchTo = t.toOutletName.toLowerCase().contains(q);
        if (!matchNo && !matchFrom && !matchTo) return false;
      }
      return true;
    }).toList();
  }
}

final centralKitchenControllerProvider =
    AsyncNotifierProvider<CentralKitchenController, CentralKitchenState>(() {
  return CentralKitchenController();
});

class CentralKitchenController extends AsyncNotifier<CentralKitchenState> {
  @override
  Future<CentralKitchenState> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return const CentralKitchenState();
    }

    final api = ref.read(centralKitchenApiServiceProvider);
    final activeRes = await api.getActiveTransfers(user.organizationId);

    if (!activeRes.success) {
      return CentralKitchenState(errorMessage: activeRes.message);
    }

    return CentralKitchenState(
      activeTransfers: activeRes.data ?? [],
    );
  }

  Future<void> toggleShowInactive() async {
    final cur = state.value ?? const CentralKitchenState();
    final newShowInactive = !cur.showInactive;
    state = AsyncData(cur.copyWith(showInactive: newShowInactive));

    if (newShowInactive && cur.inactiveTransfers.isEmpty) {
      final user = ref.read(authControllerProvider).value;
      if (user != null && user.organizationId.isNotEmpty) {
        final api = ref.read(centralKitchenApiServiceProvider);
        final inactRes = await api.getInactiveTransfers(user.organizationId);
        if (inactRes.success) {
          state = AsyncData(
            (state.value ?? cur).copyWith(inactiveTransfers: inactRes.data ?? []),
          );
        }
      }
    }
  }

  void setSearchQuery(String query) {
    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(searchQuery: query.trim()));
  }

  void setStatusFilter(String? status) {
    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(statusFilter: () => status));
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return;

    state = const AsyncLoading();
    final api = ref.read(centralKitchenApiServiceProvider);

    final activeRes = await api.getActiveTransfers(user.organizationId);
    List<CentralKitchenTransfer> inactList = [];
    if (state.value?.showInactive == true) {
      final inactRes = await api.getInactiveTransfers(user.organizationId);
      if (inactRes.success) inactList = inactRes.data ?? [];
    }

    if (!activeRes.success) {
      state = AsyncData(
        CentralKitchenState(errorMessage: activeRes.message),
      );
      return;
    }

    state = AsyncData(
      CentralKitchenState(
        activeTransfers: activeRes.data ?? [],
        inactiveTransfers: inactList,
        showInactive: state.value?.showInactive ?? false,
        statusFilter: state.value?.statusFilter,
        searchQuery: state.value?.searchQuery ?? '',
      ),
    );
  }

  Future<bool> createTransfer({
    required String fromOutletId,
    required String toOutletId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(centralKitchenApiServiceProvider);
    final res = await api.createTransfer(
      user.organizationId,
      fromOutletId: fromOutletId,
      toOutletId: toOutletId,
      lines: lines,
    );

    if (res.success && res.data != null) {
      final updatedList = [res.data!, ...cur.activeTransfers];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTransfers: updatedList,
          successMessage: () => 'Transfer #${res.data!.transferNo} created',
        ),
      );
      return true;
    } else {
      final errorMsg = res.statusCode == 500
          ? "Couldn't create the transfer. A known backend numbering issue allows only one transfer at a time."
          : res.message;
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => errorMsg,
        ),
      );
      return false;
    }
  }

  Future<bool> advanceStage(String transferId, String nextStage) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(centralKitchenApiServiceProvider);
    final res = await api.updateStage(user.organizationId, transferId, nextStage);

    if (res.success && res.data != null) {
      final updatedActives = cur.activeTransfers.map((t) {
        return t.id == transferId ? res.data! : t;
      }).toList();
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTransfers: updatedActives,
          successMessage: () => 'Transfer stage updated to $nextStage',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }

  Future<bool> deactivateTransfer(String transferId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(centralKitchenApiServiceProvider);
    final res = await api.deactivateTransfer(user.organizationId, transferId);

    if (res.success && res.data != null) {
      final updatedActives = cur.activeTransfers.where((t) => t.id != transferId).toList();
      final updatedInactives = [res.data!, ...cur.inactiveTransfers];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTransfers: updatedActives,
          inactiveTransfers: updatedInactives,
          successMessage: () => 'Transfer deactivated',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }

  Future<bool> restoreTransfer(String transferId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(centralKitchenApiServiceProvider);
    final res = await api.restoreTransfer(user.organizationId, transferId);

    if (res.success && res.data != null) {
      final updatedInactives = cur.inactiveTransfers.where((t) => t.id != transferId).toList();
      final updatedActives = [res.data!, ...cur.activeTransfers];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTransfers: updatedActives,
          inactiveTransfers: updatedInactives,
          successMessage: () => 'Transfer restored',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }

  Future<bool> deleteTransfer(String transferId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const CentralKitchenState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(centralKitchenApiServiceProvider);
    final res = await api.deleteTransfer(user.organizationId, transferId);

    if (res.success) {
      final updatedActives = cur.activeTransfers.where((t) => t.id != transferId).toList();
      final updatedInactives = cur.inactiveTransfers.where((t) => t.id != transferId).toList();
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTransfers: updatedActives,
          inactiveTransfers: updatedInactives,
          successMessage: () => 'Transfer deleted',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }
}
