import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/support_ticket.dart';
import '../../../services/api/support_ticket_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class SupportTicketState {
  final List<SupportTicket> activeTickets;
  final List<SupportTicket> inactiveTickets;
  final bool showInactive;
  final String searchQuery;
  final String? statusFilter; // null (All) | Open | In progress | Closed
  final String? categoryFilter; // null (All) | Billing / POS | Printer | ...
  final String? priorityFilter; // null (All) | Low | Medium | High
  final String? outletIdFilter; // null (All) | outlet id
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const SupportTicketState({
    this.activeTickets = const [],
    this.inactiveTickets = const [],
    this.showInactive = false,
    this.searchQuery = '',
    this.statusFilter,
    this.categoryFilter,
    this.priorityFilter,
    this.outletIdFilter,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  SupportTicketState copyWith({
    List<SupportTicket>? activeTickets,
    List<SupportTicket>? inactiveTickets,
    bool? showInactive,
    String? searchQuery,
    String? Function()? statusFilter,
    String? Function()? categoryFilter,
    String? Function()? priorityFilter,
    String? Function()? outletIdFilter,
    bool? isSubmitting,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return SupportTicketState(
      activeTickets: activeTickets ?? this.activeTickets,
      inactiveTickets: inactiveTickets ?? this.inactiveTickets,
      showInactive: showInactive ?? this.showInactive,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      outletIdFilter: outletIdFilter != null ? outletIdFilter() : this.outletIdFilter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  List<SupportTicket> get displayedTickets {
    final source = showInactive ? inactiveTickets : activeTickets;
    return source.where((t) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchNo = t.ticketNo.toLowerCase().contains(q);
        final matchSubject = t.subject.toLowerCase().contains(q);
        final matchDetails = t.details.toLowerCase().contains(q);
        final matchOutlet = t.outletName.toLowerCase().contains(q);
        if (!matchNo && !matchSubject && !matchDetails && !matchOutlet) return false;
      }
      if (statusFilter != null && t.status != statusFilter) {
        return false;
      }
      if (categoryFilter != null && t.category != categoryFilter) {
        return false;
      }
      if (priorityFilter != null && t.priority != priorityFilter) {
        return false;
      }
      if (outletIdFilter != null && t.outletId != outletIdFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}

final supportTicketControllerProvider =
    AsyncNotifierProvider<SupportTicketController, SupportTicketState>(() {
  return SupportTicketController();
});

class SupportTicketController extends AsyncNotifier<SupportTicketState> {
  @override
  Future<SupportTicketState> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return const SupportTicketState();
    }

    final api = ref.watch(supportTicketApiServiceProvider);
    final activeRes = await api.getActiveTickets(user.organizationId);

    List<SupportTicket> inactives = [];
    final role = user.role.toLowerCase();
    final canViewInactive = role == 'owner' || role == 'admin' || role == 'cto';

    if (canViewInactive) {
      final inactiveRes = await api.getInactiveTickets(user.organizationId);
      if (inactiveRes.success && inactiveRes.data != null) {
        inactives = inactiveRes.data!;
      }
    }

    return SupportTicketState(
      activeTickets: activeRes.data ?? [],
      inactiveTickets: inactives,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  void setSearchQuery(String q) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(searchQuery: q));
  }

  void setStatusFilter(String? status) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(statusFilter: () => status));
  }

  void setCategoryFilter(String? category) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(categoryFilter: () => category));
  }

  void setPriorityFilter(String? priority) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(priorityFilter: () => priority));
  }

  void setOutletIdFilter(String? outletId) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(outletIdFilter: () => outletId));
  }

  void setShowInactive(bool show) {
    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(showInactive: show));
  }

  void clearMessages() {
    final cur = state.value;
    if (cur != null) {
      state = AsyncData(cur.copyWith(
        errorMessage: () => null,
        successMessage: () => null,
      ));
    }
  }

  Future<bool> createTicket(Map<String, dynamic> payload) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(supportTicketApiServiceProvider);
    final res = await api.createTicket(user.organizationId, payload);

    if (res.success && res.data != null) {
      final updated = [res.data!, ...cur.activeTickets];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTickets: updated,
          successMessage: () => 'Ticket #${res.data!.ticketNo} created successfully',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message.isNotEmpty ? res.message : 'Failed to create ticket',
        ),
      );
      return false;
    }
  }

  Future<bool> updateStatus(String ticketId, String nextStatus) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(supportTicketApiServiceProvider);
    final res = await api.updateStatus(user.organizationId, ticketId, nextStatus);

    if (res.success && res.data != null) {
      final updatedActives = cur.activeTickets.map((t) {
        return t.id == ticketId ? res.data! : t;
      }).toList();
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTickets: updatedActives,
          successMessage: () => 'Ticket status updated to $nextStatus',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message.isNotEmpty ? res.message : 'Failed to update ticket status',
        ),
      );
      return false;
    }
  }

  Future<bool> deactivateTicket(String ticketId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(supportTicketApiServiceProvider);
    final res = await api.deactivateTicket(user.organizationId, ticketId);

    if (res.success && res.data != null) {
      final updatedActives = cur.activeTickets.where((t) => t.id != ticketId).toList();
      final updatedInactives = [res.data!, ...cur.inactiveTickets];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTickets: updatedActives,
          inactiveTickets: updatedInactives,
          successMessage: () => 'Ticket deactivated',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message.isNotEmpty ? res.message : 'Failed to deactivate ticket',
        ),
      );
      return false;
    }
  }

  Future<bool> restoreTicket(String ticketId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(supportTicketApiServiceProvider);
    final res = await api.restoreTicket(user.organizationId, ticketId);

    if (res.success && res.data != null) {
      final updatedInactives = cur.inactiveTickets.where((t) => t.id != ticketId).toList();
      final updatedActives = [res.data!, ...cur.activeTickets];
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTickets: updatedActives,
          inactiveTickets: updatedInactives,
          successMessage: () => 'Ticket restored to active list',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message.isNotEmpty ? res.message : 'Failed to restore ticket',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteTicket(String ticketId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SupportTicketState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(supportTicketApiServiceProvider);
    final res = await api.deleteTicket(user.organizationId, ticketId);

    if (res.success) {
      final updatedActives = cur.activeTickets.where((t) => t.id != ticketId).toList();
      final updatedInactives = cur.inactiveTickets.where((t) => t.id != ticketId).toList();
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          activeTickets: updatedActives,
          inactiveTickets: updatedInactives,
          successMessage: () => 'Ticket permanently deleted',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message.isNotEmpty ? res.message : 'Failed to delete ticket',
        ),
      );
      return false;
    }
  }
}
