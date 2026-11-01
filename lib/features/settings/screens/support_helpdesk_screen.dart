import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../models/support_ticket.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/active_outlet_provider.dart';
import '../controllers/outlet_controller.dart';
import '../controllers/staff_controller.dart';
import '../../support/controllers/support_ticket_controller.dart';

const List<String> kTicketCategories = [
  'Billing / POS',
  'Printer',
  'Inventory',
  'Reports',
  'Integration',
  'Account & plan',
  'Other',
];

const List<String> kTicketPriorities = ['Low', 'Medium', 'High'];

class SupportHelpdeskScreen extends ConsumerStatefulWidget {
  const SupportHelpdeskScreen({super.key});

  @override
  ConsumerState<SupportHelpdeskScreen> createState() =>
      _SupportHelpdeskScreenState();
}

class _SupportHelpdeskScreenState extends ConsumerState<SupportHelpdeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final ticketStateAsync = ref.watch(supportTicketControllerProvider);
    final notifier = ref.read(supportTicketControllerProvider.notifier);

    final role = user?.role.toLowerCase() ?? '';
    final canManageLifecycle = role == 'owner' || role == 'admin' || role == 'cto';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ticketStateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.tandoor),
        ),
        error: (err, stack) => _buildErrorState(err.toString(), notifier),
        data: (ticketState) {
          final displayedTickets = ticketState.displayedTickets;

          final targetTickets = ticketState.showInactive
              ? ticketState.inactiveTickets
              : ticketState.activeTickets;

          final openCount =
              targetTickets.where((t) => t.status == 'Open').length;
          final inProgressCount =
              targetTickets.where((t) => t.status == 'In progress').length;
          final closedCount =
              targetTickets.where((t) => t.status == 'Closed').length;
          final totalCount = targetTickets.length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final kpiCrossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;

              return RefreshIndicator(
                color: AppColors.tandoor,
                onRefresh: () => notifier.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(Gap.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      BmbScreenHeader(
                        title: 'Support & Helpdesk',
                        subtitle:
                            'Track and manage customer support & technical helpdesk tickets',
                        trailing: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (canManageLifecycle)
                              BmbButton(
                                label: ticketState.showInactive
                                    ? 'Show Active'
                                    : 'Inactive (${ticketState.inactiveTickets.length})',
                                icon: Icon(
                                  ticketState.showInactive
                                      ? Icons.visibility
                                      : Icons.archive_outlined,
                                  size: 16,
                                ),
                                variant: BmbButtonVariant.outline,
                                onPressed: () {
                                  notifier.setShowInactive(!ticketState.showInactive);
                                },
                              ),
                            BmbButton(
                              label: '+ Raise ticket',
                              icon: const Icon(Icons.add, size: 18),
                              variant: BmbButtonVariant.primary,
                              onPressed: () => _showRaiseTicketDialog(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.md),

                      // KPI Grid
                      GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: kpiCrossAxisCount,
                          crossAxisSpacing: Gap.sm,
                          mainAxisSpacing: Gap.sm,
                          mainAxisExtent: 110,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          BmbKpiTile(
                            label: 'Open',
                            value: '$openCount',
                            hint: 'in this view',
                            icon: const Icon(Icons.support_agent_outlined),
                            iconBg: AppColors.amberSoft,
                            iconFg: AppColors.amber,
                          ),
                          BmbKpiTile(
                            label: 'In Progress',
                            value: '$inProgressCount',
                            hint: 'in this view',
                            icon: const Icon(Icons.pending_actions),
                            iconBg: AppColors.blueSoft,
                            iconFg: AppColors.blue,
                          ),
                          BmbKpiTile(
                            label: 'Closed',
                            value: '$closedCount',
                            hint: 'in this view',
                            icon: const Icon(Icons.task_alt),
                            iconBg: AppColors.leafSoft,
                            iconFg: AppColors.leaf,
                          ),
                          BmbKpiTile(
                            label: ticketState.showInactive ? 'Inactive' : 'Total Active',
                            value: '$totalCount',
                            hint: 'in this view',
                            icon: const Icon(Icons.confirmation_number_outlined),
                            iconBg: AppColors.plumSoft,
                            iconFg: AppColors.plum,
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.md),

                      // Inactive view banner
                      if (ticketState.showInactive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberSoft,
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.archive_outlined,
                                size: 18,
                                color: AppColors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Viewing Inactive Tickets. These tickets are hidden from active support queues.',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => notifier.setShowInactive(false),
                                child: const Text('Back to Active'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gap.md),
                      ],

                      // Filters & Search Bar
                      _buildFiltersBar(ticketState, notifier),
                      const SizedBox(height: Gap.md),

                      // Tickets list
                      if (displayedTickets.isEmpty)
                        BmbCard(
                          child: Padding(
                            padding: const EdgeInsets.all(Gap.xxl),
                            child: BmbEmptyState(
                              icon: const Icon(
                                Icons.headset_mic_outlined,
                                size: 36,
                                color: AppColors.muted,
                              ),
                              title: ticketState.showInactive
                                  ? 'No inactive support tickets'
                                  : 'No support tickets found',
                              description: ticketState.showInactive
                                  ? 'No tickets have been deactivated.'
                                  : 'Click "+ Raise ticket" if you encounter any issue or need technical help.',
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedTickets.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ticket = displayedTickets[index];
                            return _buildTicketCard(
                              context,
                              ticket,
                              canManageLifecycle,
                              ticketState.showInactive,
                              notifier,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(
    SupportTicketState state,
    SupportTicketController notifier,
  ) {
    final outletsAsync = ref.watch(outletControllerProvider);
    final outlets = outletsAsync.value ?? [];

    return BmbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search box
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by ticket #, subject, details, outlet...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.setSearchQuery('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              filled: true,
              fillColor: AppColors.inputFill,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              notifier.setSearchQuery(val);
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          // Status Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChoiceChip('All', null, state.statusFilter, notifier),
                const SizedBox(width: 6),
                _buildStatusChoiceChip('Open', 'Open', state.statusFilter, notifier),
                const SizedBox(width: 6),
                _buildStatusChoiceChip('In progress', 'In progress', state.statusFilter, notifier),
                const SizedBox(width: 6),
                _buildStatusChoiceChip('Closed', 'Closed', state.statusFilter, notifier),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category filter
              DropdownButton<String?>(
                value: state.categoryFilter,
                hint: const Text('All Categories', style: TextStyle(fontSize: 12)),
                isDense: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Categories', style: TextStyle(fontSize: 12)),
                  ),
                  ...kTicketCategories.map((c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 12)),
                      )),
                ],
                onChanged: (val) => notifier.setCategoryFilter(val),
              ),

              // Priority filter
              DropdownButton<String?>(
                value: state.priorityFilter,
                hint: const Text('All Priorities', style: TextStyle(fontSize: 12)),
                isDense: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Priorities', style: TextStyle(fontSize: 12)),
                  ),
                  ...kTicketPriorities.map((p) => DropdownMenuItem<String?>(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 12)),
                      )),
                ],
                onChanged: (val) => notifier.setPriorityFilter(val),
              ),

              // Outlet filter
              if (outlets.isNotEmpty)
                DropdownButton<String?>(
                  value: state.outletIdFilter,
                  hint: const Text('All Outlets', style: TextStyle(fontSize: 12)),
                  isDense: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Outlets', style: TextStyle(fontSize: 12)),
                    ),
                    ...outlets.map((o) => DropdownMenuItem<String?>(
                          value: o.id,
                          child: Text(o.name, style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                  onChanged: (val) => notifier.setOutletIdFilter(val),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceChip(
    String label,
    String? statusValue,
    String? currentFilter,
    SupportTicketController notifier,
  ) {
    final isSelected = currentFilter == statusValue;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.ink,
      ),
      selectedColor: AppColors.tandoor,
      backgroundColor: AppColors.inputFill,
      onSelected: (_) => notifier.setStatusFilter(statusValue),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    SupportTicket ticket,
    bool canManageLifecycle,
    bool isInactive,
    SupportTicketController notifier,
  ) {
    final formattedDate = ticket.createdAt != null
        ? '${ticket.createdAt!.year}-${ticket.createdAt!.month.toString().padLeft(2, '0')}-${ticket.createdAt!.day.toString().padLeft(2, '0')}'
        : '';

    return BmbCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket # and Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Ticket #${ticket.ticketNo}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tandoor,
                  ),
                ),
              ),
              _buildStatusChip(ticket.status),
            ],
          ),
          const SizedBox(height: 6),

          // Subject
          Text(
            ticket.subject,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (ticket.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ticket.details,
              style: AppText.caption.copyWith(color: AppColors.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),

          // Tags row: Category, Priority, Outlet, Created Date
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildCategoryChip(ticket.category),
              _buildPriorityChip(ticket.priority),
              if (ticket.outletName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        ticket.outletName,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              if (formattedDate.isNotEmpty)
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions Row
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              // Details Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Details', style: TextStyle(fontSize: 12)),
                onPressed: () => _showTicketDetailSheet(context, ticket, canManageLifecycle, notifier),
              ),

              // Status Advance Button (Owner/Admin/CTO only per PDF)
              if (!isInactive && canManageLifecycle && ticket.nextStatus != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusActionColor(ticket.nextStatus!),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(_statusActionIcon(ticket.nextStatus!), size: 14),
                  label: Text(
                    ticket.nextActionLabel ?? 'Advance',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmUpdateStatus(
                    context,
                    ticket,
                    ticket.nextStatus!,
                    notifier,
                  ),
                ),

              // Deactivate Button (#142, Owner/Admin/CTO only)
              if (!isInactive && canManageLifecycle)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.archive_outlined, size: 15),
                  label: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                  onPressed: () => _confirmDeactivate(context, ticket, notifier),
                ),

              // Inactive Actions
              if (isInactive && canManageLifecycle) ...[
                // Restore (#143)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.leaf,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.unarchive_outlined, size: 15),
                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                  onPressed: () => notifier.restoreTicket(ticket.id),
                ),
                // Delete permanently (#144)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.tandoor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 15),
                  label: const Text('Delete permanently', style: TextStyle(fontSize: 12)),
                  onPressed: () => _confirmDeleteTicket(context, ticket, notifier),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    BmbTagVariant variant;
    switch (status) {
      case 'Open':
        variant = BmbTagVariant.amber;
        break;
      case 'In progress':
        variant = BmbTagVariant.blue;
        break;
      case 'Closed':
        variant = BmbTagVariant.green;
        break;
      default:
        variant = BmbTagVariant.grey;
    }
    return BmbTag(label: status.toUpperCase(), variant: variant);
  }

  Widget _buildCategoryChip(String category) {
    return BmbTag(
      label: category,
      variant: BmbTagVariant.grey,
    );
  }

  Widget _buildPriorityChip(String priority) {
    BmbTagVariant variant;
    switch (priority) {
      case 'High':
        variant = BmbTagVariant.red;
        break;
      case 'Medium':
        variant = BmbTagVariant.amber;
        break;
      case 'Low':
      default:
        variant = BmbTagVariant.grey;
    }
    return BmbTag(label: priority, variant: variant);
  }

  Color _statusActionColor(String nextStatus) {
    switch (nextStatus) {
      case 'In progress':
        return AppColors.blue;
      case 'Closed':
        return AppColors.leaf;
      case 'Open':
        return AppColors.amber;
      default:
        return AppColors.ink;
    }
  }

  IconData _statusActionIcon(String nextStatus) {
    switch (nextStatus) {
      case 'In progress':
        return Icons.play_arrow;
      case 'Closed':
        return Icons.check_circle_outline;
      case 'Open':
        return Icons.replay;
      default:
        return Icons.arrow_forward;
    }
  }

  void _confirmUpdateStatus(
    BuildContext context,
    SupportTicket ticket,
    String nextStatus,
    SupportTicketController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Ticket Status to $nextStatus'),
        content: Text(
          'Update status of Ticket #${ticket.ticketNo} from "${ticket.status}" to "$nextStatus"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusActionColor(nextStatus),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await notifier.updateStatus(ticket.id, nextStatus);
              if (!ok && context.mounted) {
                final err = ref.read(supportTicketControllerProvider).value?.errorMessage;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.tandoor),
                  );
                }
              }
            },
            child: Text('Confirm $nextStatus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(
    BuildContext context,
    SupportTicket ticket,
    SupportTicketController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Ticket'),
        content: Text(
          'Deactivate Ticket #${ticket.ticketNo}? It will be hidden from the active support queue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deactivateTicket(ticket.id);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTicket(
    BuildContext context,
    SupportTicket ticket,
    SupportTicketController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text(
          'Permanently delete Ticket #${ticket.ticketNo}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tandoor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteTicket(ticket.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String? _resolveRaisedByName(SupportTicket ticket) {
    final currentUser = ref.read(authControllerProvider).value;
    if (ticket.raisedBy != null && ticket.raisedBy!.isNotEmpty) {
      if (currentUser != null && ticket.raisedBy == currentUser.id) {
        return 'You';
      }
      // For other ids, look the name up from the existing users/staff provider only if it's already available for the role, else hide the field.
      final staffList = ref.read(staffListProvider).value;
      if (staffList != null) {
        final match = staffList.where((u) => u.id == ticket.raisedBy).firstOrNull;
        if (match != null) {
          return match.name.isNotEmpty ? match.name : match.email;
        }
      }
      // If server returned a populated raisedByName, show it
      if (ticket.raisedByName != null && ticket.raisedByName!.isNotEmpty) {
        return ticket.raisedByName;
      }
      return null;
    }
    if (ticket.raisedByName != null && ticket.raisedByName!.isNotEmpty) {
      return ticket.raisedByName;
    }
    return null;
  }

  void _showTicketDetailSheet(
    BuildContext context,
    SupportTicket ticket,
    bool canManageLifecycle,
    SupportTicketController notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(ticket.status),
                  _buildPriorityChip(ticket.priority),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ticket #${ticket.ticketNo}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tandoor),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.subject,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ticket.details.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    ticket.details,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildDetailRow('Category', ticket.category),
              _buildDetailRow('Outlet', ticket.outletName.isNotEmpty ? ticket.outletName : ticket.outletId),
              if (_resolveRaisedByName(ticket) != null)
                _buildDetailRow('Raised By', _resolveRaisedByName(ticket)!),
              if (ticket.createdAt != null)
                _buildDetailRow('Created At', ticket.createdAt!.toIso8601String().substring(0, 16)),
              if (ticket.updatedAt != null)
                _buildDetailRow('Updated At', ticket.updatedAt!.toIso8601String().substring(0, 16)),

              const SizedBox(height: 16),
              // Backend limitation banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replies, attachments and live chat are not supported by the backend.',
                        style: AppText.caption.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (canManageLifecycle && ticket.nextStatus != null)
                BmbButton(
                  label: ticket.nextActionLabel ?? 'Advance Status',
                  variant: BmbButtonVariant.primary,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmUpdateStatus(context, ticket, ticket.nextStatus!, notifier);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRaiseTicketDialog(BuildContext context) {
    final outletsAsync = ref.read(outletControllerProvider);
    final outlets = outletsAsync.value ?? [];
    final activeOutlet = ref.read(activeOutletProvider);

    String selectedOutletId = activeOutlet?.id ?? (outlets.isNotEmpty ? outlets.first.id : '');
    String selectedCategory = 'Other';
    String selectedPriority = 'Medium';
    final subjectCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Raise Support Ticket', style: AppText.h3),
                  const SizedBox(height: 16),

                  // Outlet selector
                  const Text('Outlet *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (outlets.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedOutletId.isNotEmpty ? selectedOutletId : outlets.first.id,
                      items: outlets.map((o) {
                        return DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(o.name, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedOutletId = val);
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                      ),
                    )
                  else
                    const Text('No outlets available', style: TextStyle(color: AppColors.tandoor)),
                  const SizedBox(height: 12),

                  // Subject (required)
                  const Text('Subject *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      hintText: 'Brief summary of the issue',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                    ),
                    style: const TextStyle(fontSize: 13),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Subject is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Category dropdown
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: kTicketCategories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority selector
                  const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kTicketPriorities.map((p) {
                        final isSelected = selectedPriority == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(p),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                            selectedColor: p == 'High'
                                ? AppColors.tandoor
                                : (p == 'Medium' ? AppColors.amber : AppColors.blue),
                            onSelected: (_) {
                              setSheetState(() => selectedPriority = p);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Details
                  const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Provide additional details or steps to reproduce',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Submit
                  BmbButton(
                    label: 'Submit Ticket',
                    variant: BmbButtonVariant.primary,
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final payload = {
                          'outletId': selectedOutletId,
                          'subject': subjectCtrl.text.trim(),
                          'category': selectedCategory,
                          'priority': selectedPriority,
                          if (detailsCtrl.text.trim().isNotEmpty)
                            'details': detailsCtrl.text.trim(),
                        };

                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(supportTicketControllerProvider.notifier)
                            .createTicket(payload);

                        if (context.mounted) {
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Support ticket created successfully'),
                                backgroundColor: AppColors.leaf,
                              ),
                            );
                          } else {
                            final err = ref
                                .read(supportTicketControllerProvider)
                                .value
                                ?.errorMessage;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err ?? 'Failed to create ticket'),
                                backgroundColor: AppColors.tandoor,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, SupportTicketController notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.tandoor),
            const SizedBox(height: 12),
            Text('Failed to load tickets', style: AppText.h3),
            const SizedBox(height: 6),
            Text(
              error,
              style: AppText.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BmbPrimaryButton(
              label: 'Try Again',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
      ),
    );
  }
}
