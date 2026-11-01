import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../models/central_kitchen_transfer.dart';
import '../../../models/inventory_item.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../central_kitchen/controllers/central_kitchen_controller.dart';
import '../../supply_chain/providers/inventory_providers.dart';
import '../controllers/outlet_controller.dart';

class CentralKitchenScreen extends ConsumerStatefulWidget {
  const CentralKitchenScreen({super.key});

  @override
  ConsumerState<CentralKitchenScreen> createState() =>
      _CentralKitchenScreenState();
}

class _CentralKitchenScreenState extends ConsumerState<CentralKitchenScreen> {
  final _searchController = TextEditingController();
  bool _showStockInfoBanner = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role.toLowerCase() ?? '';
    final isStaff = role == 'staff';
    final isOwnerOrCto = role == 'owner' || role == 'cto';
    final canManageLifecycle = role == 'owner' || role == 'admin' || role == 'cto';

    final ckAsync = ref.watch(centralKitchenControllerProvider);
    final notifier = ref.read(centralKitchenControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, ckAsync.value, notifier, isStaff),
            // Dismissible Info Banner (Backend Limitation)
            if (_showStockInfoBanner) _buildStockInfoBanner(),
            // Search and Status Filters
            _buildFilterBar(ckAsync.value, notifier),
            const Divider(height: 1),
            // Body with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.refresh(),
                child: ckAsync.when(
                  data: (state) => _buildTransferList(
                    context,
                    state,
                    notifier,
                    isStaff: isStaff,
                    canManageLifecycle: canManageLifecycle,
                    canDeletePermanently: isOwnerOrCto,
                  ),
                  loading: () => _buildLoadingSkeleton(),
                  error: (err, _) => _buildErrorState(err.toString(), notifier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    CentralKitchenState? state,
    CentralKitchenController notifier,
    bool isStaff,
  ) {
    final showInactive = state?.showInactive ?? false;
    final inactCount = state?.inactiveTransfers.length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding(context),
            vertical: Gap.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(AppRadii.icon),
                    ),
                    child: const Icon(Icons.kitchen, color: AppColors.amber, size: 20),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Central Kitchen (30)',
                          style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Inter-Outlet Transfers & Dispatches (#119-#126)',
                          style: AppText.caption.copyWith(color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    AppSpacing.gapWMd,
                    BmbPrimaryButton(
                      label: 'New Transfer',
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      onPressed: () => _showCreateTransferSheet(context),
                    ),
                  ],
                ],
              ),
              if (!isWide) ...[
                AppSpacing.gapHSm,
                BmbPrimaryButton(
                  label: 'New Transfer',
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  onPressed: () => _showCreateTransferSheet(context),
                  expanded: true,
                ),
              ],
              AppSpacing.gapHSm,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(
                        showInactive
                            ? 'Hide Inactive ($inactCount)'
                            : 'Show Inactive ($inactCount)',
                        style: TextStyle(
                          fontSize: 12,
                          color: showInactive ? AppColors.tandoor : AppColors.ink,
                        ),
                      ),
                      selected: showInactive,
                      selectedColor: AppColors.tandoorSoft,
                      backgroundColor: AppColors.inputFill,
                      side: BorderSide(
                        color: showInactive ? AppColors.tandoor : AppColors.line,
                      ),
                      onSelected: (_) => notifier.toggleShowInactive(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh transfers',
                      onPressed: () => notifier.refresh(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.blueSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.blue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Stock is organization-wide, so the receiving outlet isn't credited (backend limitation)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.blue,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showStockInfoBanner = false),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(CentralKitchenState? state, CentralKitchenController notifier) {
    final curStatus = state?.statusFilter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Transfer # (e.g. TR-001) or outlet...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) {
                notifier.setSearchQuery(val);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          // Status Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('All', null, curStatus, notifier),
                const SizedBox(width: 6),
                _buildStatusChip('Requested', 'Requested', curStatus, notifier),
                const SizedBox(width: 6),
                _buildStatusChip('Approved', 'Approved', curStatus, notifier),
                const SizedBox(width: 6),
                _buildStatusChip('Dispatched', 'Dispatched', curStatus, notifier),
                const SizedBox(width: 6),
                _buildStatusChip('Received', 'Received', curStatus, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String? statusValue,
    String? currentFilter,
    CentralKitchenController notifier,
  ) {
    final isSelected = currentFilter == statusValue;

    return ChoiceChip(
      selected: isSelected,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(
        color: isSelected ? AppColors.tandoor : AppColors.line,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.tandoor : AppColors.ink,
        ),
      ),
      onSelected: (_) => notifier.setStatusFilter(statusValue),
    );
  }

  Widget _buildTransferList(
    BuildContext context,
    CentralKitchenState state,
    CentralKitchenController notifier, {
    required bool isStaff,
    required bool canManageLifecycle,
    required bool canDeletePermanently,
  }) {
    final transfers = state.displayedTransfers;

    if (transfers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: BmbEmptyState(
              title: state.showInactive ? 'No Inactive Transfers' : 'No Transfers Found',
              description: state.showInactive
                  ? 'There are no deactivated transfers.'
                  : 'No active transfers match the current filter or search criteria.',
              icon: const Icon(Icons.kitchen_outlined, size: 48, color: AppColors.muted),
              actionLabel: state.showInactive ? null : 'New Transfer',
              onAction: state.showInactive ? null : () => _showCreateTransferSheet(context),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return _buildTransferCard(
          context,
          transfer,
          notifier,
          isInactive: state.showInactive,
          canManageLifecycle: canManageLifecycle,
          canDeletePermanently: canDeletePermanently,
        );
      },
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    CentralKitchenTransfer transfer,
    CentralKitchenController notifier, {
    required bool isInactive,
    required bool canManageLifecycle,
    required bool canDeletePermanently,
  }) {
    return BmbCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Transfer No, Value, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _statusBgColor(transfer.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _statusIcon(transfer.status),
                        size: 16,
                        color: _statusFgColor(transfer.status),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Transfer #${transfer.transferNo}',
                        style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(transfer.status),
            ],
          ),
          const SizedBox(height: 10),

          // Route: From Outlet -> To Outlet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FROM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.muted)),
                      Text(
                        transfer.fromOutletName.isNotEmpty ? transfer.fromOutletName : 'Source Outlet',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.muted)),
                      Text(
                        transfer.toOutletName.isNotEmpty ? transfer.toOutletName : 'Destination Outlet',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Items summary & value
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${transfer.lines.length} ${transfer.lines.length == 1 ? 'item' : 'items'} (${transfer.lines.map((l) => "${l.quantity.toStringAsFixed(l.quantity % 1 == 0 ? 0 : 2)}x ${l.materialName.isNotEmpty ? l.materialName : 'Item'}").take(2).join(', ')}${transfer.lines.length > 2 ? '...' : ''})',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              Text(
                'Value: ₹${transfer.value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.leaf),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action Buttons Row
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
                onPressed: () => _showDetailSheet(context, transfer),
              ),

              // Active Stage Action (#123)
              if (!isInactive && transfer.nextStatus != null) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nextActionBgColor(transfer.nextStatus!),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(_nextActionIcon(transfer.nextStatus!), size: 14),
                  label: Text(
                    transfer.nextActionLabel ?? 'Next Step',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmAdvanceStage(
                    context,
                    transfer,
                    transfer.nextStatus!,
                    notifier,
                  ),
                ),
              ],

              // Deactivate Button (#124, Owner/Admin/CTO only)
              if (!isInactive && canManageLifecycle) ...[
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.archive_outlined, size: 15),
                  label: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                  onPressed: () => _confirmDeactivate(context, transfer, notifier),
                ),
              ],

              // Inactive Actions
              if (isInactive) ...[
                // Restore (#125)
                if (canManageLifecycle)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.leaf,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.unarchive_outlined, size: 15),
                    label: const Text('Restore', style: TextStyle(fontSize: 12)),
                    onPressed: () => notifier.restoreTransfer(transfer.id),
                  ),
                // Delete Permanently (#126, Owner/CTO only per PDF)
                if (canDeletePermanently)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.tandoor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_forever_outlined, size: 15),
                    label: const Text('Delete permanently', style: TextStyle(fontSize: 12)),
                    onPressed: () => _confirmDeletePermanently(context, transfer, notifier),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    BmbTagVariant variant;
    switch (status) {
      case 'Requested':
        variant = BmbTagVariant.amber;
        break;
      case 'Approved':
        variant = BmbTagVariant.blue;
        break;
      case 'Dispatched':
        variant = BmbTagVariant.grey;
        break;
      case 'Received':
        variant = BmbTagVariant.green;
        break;
      default:
        variant = BmbTagVariant.grey;
    }
    return BmbTag(label: status, variant: variant);
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Requested':
        return AppColors.amberSoft;
      case 'Approved':
        return AppColors.blueSoft;
      case 'Dispatched':
        return AppColors.card;
      case 'Received':
        return AppColors.leafSoft;
      default:
        return AppColors.inputFill;
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'Requested':
        return AppColors.amber;
      case 'Approved':
        return AppColors.blue;
      case 'Dispatched':
        return AppColors.ink;
      case 'Received':
        return AppColors.leaf;
      default:
        return AppColors.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Requested':
        return Icons.pending_actions;
      case 'Approved':
        return Icons.thumb_up_alt_outlined;
      case 'Dispatched':
        return Icons.local_shipping_outlined;
      case 'Received':
        return Icons.check_circle_outline;
      default:
        return Icons.kitchen;
    }
  }

  Color _nextActionBgColor(String nextStatus) {
    switch (nextStatus) {
      case 'Approved':
        return AppColors.blue;
      case 'Dispatched':
        return AppColors.tandoor;
      case 'Received':
        return AppColors.leaf;
      default:
        return AppColors.ink;
    }
  }

  IconData _nextActionIcon(String nextStatus) {
    switch (nextStatus) {
      case 'Approved':
        return Icons.thumb_up_alt_outlined;
      case 'Dispatched':
        return Icons.local_shipping;
      case 'Received':
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }

  void _confirmAdvanceStage(
    BuildContext context,
    CentralKitchenTransfer transfer,
    String nextStage,
    CentralKitchenController notifier,
  ) {
    String message;
    if (nextStage == 'Dispatched') {
      message =
          "Dispatching reduces total stock and can't be undone by deleting or deactivating.";
    } else if (nextStage == 'Received') {
      message = 'Confirm that the destination outlet has received this transfer?';
    } else {
      message = 'Approve Transfer #${transfer.transferNo}?';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Advance to $nextStage'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _nextActionBgColor(nextStage),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await notifier.advanceStage(transfer.id, nextStage);
              if (!ok && context.mounted) {
                final err = ref.read(centralKitchenControllerProvider).value?.errorMessage;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.tandoor),
                  );
                }
              }
            },
            child: Text('Confirm $nextStage'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(
    BuildContext context,
    CentralKitchenTransfer transfer,
    CentralKitchenController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Transfer'),
        content: Text(
          'Deactivate Transfer #${transfer.transferNo}? It will be moved to the inactive list.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deactivateTransfer(transfer.id);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(
    BuildContext context,
    CentralKitchenTransfer transfer,
    CentralKitchenController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transfer Permanently (#126)'),
        content: Text(
          'Are you sure you want to permanently delete Transfer #${transfer.transferNo}? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tandoor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteTransfer(transfer.id);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, CentralKitchenTransfer transfer) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Text(
                      'Transfer #${transfer.transferNo}',
                      style: AppText.h2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(transfer.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'From: ${transfer.fromOutletName} → To: ${transfer.toOutletName}',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stage Pipeline Steps
              const Text('Pipeline Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPipelineProgress(transfer.status),
              const SizedBox(height: 16),

              // Line Items
              const Text('Line Items:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transfer.lines.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = transfer.lines[i];
                    return ListTile(
                      dense: true,
                      title: Text(l.materialName.isNotEmpty ? l.materialName : l.inventoryId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      trailing: Text('${l.quantity.toStringAsFixed(l.quantity % 1 == 0 ? 0 : 2)} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Value:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${transfer.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.leaf),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: BmbButton(
                  label: 'Close',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineProgress(String currentStatus) {
    final stages = ['Requested', 'Approved', 'Dispatched', 'Received'];
    final curIdx = stages.indexOf(currentStatus);

    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: i <= curIdx ? AppColors.leaf : AppColors.inputFill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i <= curIdx ? AppColors.leaf : AppColors.line,
                    ),
                  ),
                  child: Center(
                    child: i < curIdx
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: i == curIdx ? Colors.white : AppColors.muted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stages[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == curIdx ? FontWeight.bold : FontWeight.normal,
                    color: i <= curIdx ? AppColors.ink : AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (i < stages.length - 1)
            Container(
              width: 16,
              height: 2,
              color: i < curIdx ? AppColors.leaf : AppColors.line,
            ),
        ],
      ],
    );
  }

  void _showCreateTransferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateTransferSheet(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 140, height: 16, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(width: 200, height: 12, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 60, height: 20, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Container(width: 80, height: 20, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, CentralKitchenController notifier) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.tandoor),
                const SizedBox(height: 12),
                Text('Failed to load transfers', style: AppText.h3),
                const SizedBox(height: 6),
                Text(
                  error,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => notifier.refresh(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateTransferSheet extends ConsumerStatefulWidget {
  const _CreateTransferSheet();

  @override
  ConsumerState<_CreateTransferSheet> createState() => _CreateTransferSheetState();
}

class _CreateTransferSheetState extends ConsumerState<_CreateTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _fromOutletId;
  String? _toOutletId;
  final List<_LineItemDraft> _lines = [_LineItemDraft()];
  bool _isSaving = false;
  String? _formError;

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(outletControllerProvider);
    final inventoryAsync = ref.watch(activeInventoryProvider);

    final outlets = outletsAsync.value ?? [];
    final inventoryItems = inventoryAsync.value ?? [];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Transfer Request (#121)', style: AppText.h3),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tandoorSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.tandoor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.tandoor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: const TextStyle(fontSize: 12, color: AppColors.tandoor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Outlets Row
              DropdownButtonFormField<String>(
                initialValue: _fromOutletId,
                decoration: const InputDecoration(
                  labelText: 'From Outlet *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: outlets.map((o) {
                  return DropdownMenuItem(
                    value: o.id,
                    child: Text('${o.name} (${o.code})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _fromOutletId = val;
                    _validateOutlets();
                  });
                },
                validator: (val) => val == null || val.isEmpty ? 'Select source outlet' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _toOutletId,
                decoration: const InputDecoration(
                  labelText: 'To Outlet *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: outlets.map((o) {
                  return DropdownMenuItem(
                    value: o.id,
                    child: Text('${o.name} (${o.code})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _toOutletId = val;
                    _validateOutlets();
                  });
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Select destination outlet';
                  if (val == _fromOutletId) return 'Source and destination outlet must differ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Lines Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Line Items *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _lines.add(_LineItemDraft());
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Line Items List
              for (int i = 0; i < _lines.length; i++) ...[
                _buildLineItemRow(i, inventoryItems),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 16),
              // Live estimated total value
              _buildEstimatedTotal(inventoryItems),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tandoor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isSaving ? 'Submitting...' : 'Submit Transfer Request'),
                  onPressed: _isSaving ? null : () => _submitTransfer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateOutlets() {
    if (_fromOutletId != null && _toOutletId != null && _fromOutletId == _toOutletId) {
      _formError = 'Source and destination outlet must differ';
    } else {
      _formError = null;
    }
  }

  Widget _buildLineItemRow(int index, List<InventoryItem> inventoryItems) {
    final line = _lines[index];
    final selectedMatches = inventoryItems.where((inv) => inv.id == line.inventoryId);
    final selectedInv = selectedMatches.isNotEmpty ? selectedMatches.first : null;
    final isOverStock = selectedInv != null && line.quantity > selectedInv.inStock;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: line.inventoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Item *',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: inventoryItems.map((inv) {
                    return DropdownMenuItem(
                      value: inv.id,
                      child: Text(
                        '${inv.material} (Stock: ${inv.inStock} ${inv.unit})',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      line.inventoryId = val;
                    });
                  },
                  validator: (val) => val == null || val.isEmpty ? 'Select item' : null,
                ),
              ),
              if (_lines.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.chilli),
                  tooltip: 'Remove line',
                  onPressed: () {
                    setState(() {
                      _lines.removeAt(index);
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: line.quantity > 0 ? line.quantity.toString() : '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quantity *',
              hintText: 'e.g. 5',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              final parsed = double.tryParse(val.trim());
              line.quantity = parsed ?? 0.0;
              setState(() {});
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter quantity';
              final parsed = double.tryParse(val.trim());
              if (parsed == null || parsed <= 0) return 'Quantity must be > 0';
              return null;
            },
          ),
          if (isOverStock) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Only ${selectedInv.inStock} ${selectedInv.unit} in stock. Dispatch will fail unless stock is available.',
                      style: const TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimatedTotal(List<InventoryItem> inventoryItems) {
    double totalEst = 0.0;
    for (final l in _lines) {
      if (l.inventoryId != null && l.quantity > 0) {
        final matches = inventoryItems.where((inv) => inv.id == l.inventoryId);
        if (matches.isNotEmpty) {
          totalEst += l.quantity * matches.first.rate;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.leafSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.leaf.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Estimated Value:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(
            '₹${totalEst.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.leaf),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_fromOutletId == _toOutletId) {
      setState(() => _formError = 'Source and destination outlet must differ');
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    final payloadLines = _lines.map((l) {
      return {
        'inventoryId': l.inventoryId!,
        'quantity': l.quantity,
      };
    }).toList();

    final notifier = ref.read(centralKitchenControllerProvider.notifier);
    final ok = await notifier.createTransfer(
      fromOutletId: _fromOutletId!,
      toOutletId: _toOutletId!,
      lines: payloadLines,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer created successfully'),
            backgroundColor: AppColors.leaf,
          ),
        );
      } else {
        final err = ref.read(centralKitchenControllerProvider).value?.errorMessage;
        setState(() => _formError = err ?? 'Failed to create transfer');
      }
    }
  }
}

class _LineItemDraft {
  String? inventoryId;
  double quantity = 0.0;
}
