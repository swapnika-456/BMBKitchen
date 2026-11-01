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
import '../../../core/widgets/lifecycle_list_view.dart';
import '../../../models/models.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wastage_adjustment_controller.dart';
import '../providers/inventory_providers.dart';

/// Module 11 — Wastage & Stock Adjustment Screen (#87 - #94)
class WastageScreen extends ConsumerStatefulWidget {
  const WastageScreen({super.key});

  @override
  ConsumerState<WastageScreen> createState() => _WastageScreenState();
}

class _WastageScreenState extends ConsumerState<WastageScreen> {
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'wastage', 'adjustment'
  bool _showInactive = false;

  bool _canWrite(String? role) {
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  bool _canHardDelete(String? role) {
    return role == 'owner' || role == 'admin';
  }

  String _resolveMaterialName(WastageAdjustment wa, List<InventoryItem> invItems) {
    if (wa.inventoryMaterial.isNotEmpty) return wa.inventoryMaterial;
    final match = invItems.where((i) => i.id == wa.inventoryId).firstOrNull;
    if (match != null && match.material.isNotEmpty) return match.material;
    return wa.inventoryId.isNotEmpty ? wa.inventoryId : 'Unknown Material';
  }

  String _resolveUnit(WastageAdjustment wa, List<InventoryItem> invItems) {
    if (wa.inventoryUnit.isNotEmpty) return wa.inventoryUnit;
    final match = invItems.where((i) => i.id == wa.inventoryId).firstOrNull;
    if (match != null && match.unit != null && match.unit!.isNotEmpty) {
      return match.unit!;
    }
    return '';
  }

  static Widget _buildTypeChip(String type) {
    final isWastage = type.toLowerCase() == 'wastage';
    if (isWastage) {
      return const BmbTag.amber('Wastage');
    } else {
      return const BmbTag.blue('Adjustment');
    }
  }

  static Widget? _buildActionChip(String? action) {
    if (action == null || action.isEmpty) return null;
    final a = action.toLowerCase();
    if (a == 'add') {
      return const BmbTag.green('+ Added');
    } else if (a == 'remove') {
      return const BmbTag.red('- Removed');
    }
    return BmbTag.grey(action);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final canWrite = _canWrite(user?.role);
    final canHardDelete = _canHardDelete(user?.role);
    final isStaff = !canWrite;

    final activeAsync = ref.watch(activeWastageAdjustmentProvider);
    final inactiveAsync = ref.watch(inactiveWastageAdjustmentProvider);
    final recordsAsync = _showInactive ? inactiveAsync : activeAsync;

    final inventoryAsync = ref.watch(activeInventoryProvider);
    final inventoryItems = inventoryAsync.value ?? [];

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Wastage & Stock Adjustment',
            subtitle: 'Log waste, spoilage, and stock corrections to keep inventory accurate',
            icon: Icons.delete_outline,
            iconBg: AppColors.chilliSoft,
            iconColor: AppColors.chilli,
            // Staff is allowed to create records (#88)!
            trailing: BmbButton.primary(
              label: 'Record Wastage',
              size: BmbButtonSize.sm,
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => _openRecordSheet(context, null, inventoryItems),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: recordsAsync.when(
                data: (records) {
                  // Filter client-side by search query and type filter
                  final q = _searchQuery.trim().toLowerCase();
                  final filtered = records.where((wa) {
                    if (_typeFilter != 'all' && wa.type.toLowerCase() != _typeFilter) {
                      return false;
                    }
                    if (q.isEmpty) return true;
                    final mat = _resolveMaterialName(wa, inventoryItems).toLowerCase();
                    final no = wa.wastageNo.toLowerCase();
                    final r = (wa.reason ?? '').toLowerCase();
                    return mat.contains(q) || no.contains(q) || r.contains(q);
                  }).toList();

                  // Newest records first
                  filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKpiAndFilters(context, records),
                      AppSpacing.gapHLg,

                      if (records.isEmpty && !_showInactive)
                        const BmbEmptyState(
                          title: 'No wastage or adjustments recorded',
                          description: 'Record wastage or stock corrections to maintain accurate inventory levels.',
                        )
                      else if (filtered.isEmpty)
                        const BmbEmptyState(
                          title: 'No matching records found',
                          description: 'Try adjusting your search criteria or type filter.',
                        )
                      else if (!isStaff)
                        BmbCard(
                          child: SizedBox(
                            height: 600,
                            child: LifecycleListView<WastageAdjustment>(
                              title: 'Wastage & Adjustments',
                              items: filtered.map((wa) {
                                final mat = _resolveMaterialName(wa, inventoryItems);
                                final unit = _resolveUnit(wa, inventoryItems);
                                final dateStr = wa.createdAt != null
                                    ? wa.createdAt!.toLocal().toString().split(' ')[0]
                                    : '';
                                final actionStr = wa.action != null && wa.action!.isNotEmpty
                                    ? '[${wa.action!.toUpperCase()}] '
                                    : '';
                                return LifecycleItem(
                                  data: wa,
                                  title: '${wa.wastageNo.isNotEmpty ? "${wa.wastageNo} — " : ""}$mat',
                                  subtitle:
                                      '${wa.type.toUpperCase()} $actionStr| Qty: ${wa.quantity} $unit | Reason: ${wa.reason ?? "None"}${dateStr.isNotEmpty ? " | Date: $dateStr" : ""}',
                                  isActive: wa.isActive,
                                );
                              }).toList(),
                              showInactive: _showInactive,
                              onToggleView: () => setState(() => _showInactive = !_showInactive),
                              onCreate: () => _openRecordSheet(context, null, inventoryItems),
                              onEdit: (wa) => _openDetailOrEditModal(context, wa, inventoryItems, canWrite),
                              onDeactivate: _deactivateRecord,
                              onRestore: _restoreRecord,
                              onHardDelete: _hardDeleteRecord,
                              canHardDelete: canHardDelete,
                            ),
                          ),
                        )
                      else
                        _buildStaffView(context, filtered, inventoryItems),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error loading records: $e', style: AppText.body),
                        const SizedBox(height: Gap.md),
                        BmbButton.outline(
                          label: 'Retry',
                          onPressed: () {
                            ref.read(activeWastageAdjustmentProvider.notifier).refresh();
                            ref.read(inactiveWastageAdjustmentProvider.notifier).refresh();
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiAndFilters(BuildContext context, List<WastageAdjustment> records) {
    int total = records.length;
    int wastageCount = records.where((r) => r.type.toLowerCase() == 'wastage').length;
    int adjCount = records.where((r) => r.type.toLowerCase() == 'adjustment').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            BmbKpiTile(
              label: 'Total Logged',
              value: '$total',
              icon: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.tandoor),
              iconBg: AppColors.tandoorSoft,
              iconFg: AppColors.tandoor,
            ),
            BmbKpiTile(
              label: 'Wastage Entries',
              value: '$wastageCount',
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.chilli),
              iconBg: AppColors.chilliSoft,
              iconFg: AppColors.chilli,
            ),
            BmbKpiTile(
              label: 'Adjustments',
              value: '$adjCount',
              icon: const Icon(Icons.tune, size: 20, color: AppColors.blue),
              iconBg: AppColors.blueSoft,
              iconFg: AppColors.blue,
            ),
          ],
        ),
        AppSpacing.gapHLg,
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by material, WA code, or reason...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                    ),
                  ),
                  const SizedBox(height: Gap.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _typeFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'wastage', child: Text('Wastage Only')),
                          DropdownMenuItem(value: 'adjustment', child: Text('Adjustment Only')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _typeFilter = v);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by material, WA code, or reason...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                    ),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _typeFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Types')),
                        DropdownMenuItem(value: 'wastage', child: Text('Wastage Only')),
                        DropdownMenuItem(value: 'adjustment', child: Text('Adjustment Only')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _typeFilter = v);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStaffView(
    BuildContext context,
    List<WastageAdjustment> filtered,
    List<InventoryItem> inventoryItems,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final wa = filtered[index];
        final mat = _resolveMaterialName(wa, inventoryItems);
        final unit = _resolveUnit(wa, inventoryItems);
        final dateStr = wa.createdAt != null
            ? wa.createdAt!.toLocal().toString().split(' ')[0]
            : '';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs),
          title: Wrap(
            spacing: Gap.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${wa.wastageNo.isNotEmpty ? "${wa.wastageNo} — " : ""}$mat',
                style: AppText.bodyStrong,
              ),
              _buildTypeChip(wa.type),
              if (wa.action != null && wa.action!.isNotEmpty && _buildActionChip(wa.action) != null)
                _buildActionChip(wa.action)!,
            ],
          ),
          subtitle: Text(
            'Quantity: ${wa.quantity} $unit | Reason: ${wa.reason ?? "None"}${dateStr.isNotEmpty ? " | $dateStr" : ""}',
            style: AppText.caption,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _openDetailModal(context, wa, inventoryItems, false),
        );
      },
    );
  }

  void _openDetailOrEditModal(
    BuildContext context,
    WastageAdjustment wa,
    List<InventoryItem> inventoryItems,
    bool canWrite,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetCtx) {
        final mat = _resolveMaterialName(wa, inventoryItems);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wa.wastageNo.isNotEmpty ? wa.wastageNo : 'Record Details',
                      style: AppText.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                Text(
                  mat,
                  style: AppText.bodyStrong.copyWith(color: AppColors.tandoor),
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: BmbButton.outline(
                        label: 'View Details (#90)',
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openDetailModal(context, wa, inventoryItems, canWrite);
                        },
                      ),
                    ),
                    if (canWrite) ...[
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: BmbButton.primary(
                          label: 'Edit Reason/Type (#91)',
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _openEditModal(context, wa, inventoryItems);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetailModal(
    BuildContext context,
    WastageAdjustment wa,
    List<InventoryItem> inventoryItems,
    bool canWrite,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetCtx) {
        final mat = _resolveMaterialName(wa, inventoryItems);
        final unit = _resolveUnit(wa, inventoryItems);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wa.wastageNo.isNotEmpty ? wa.wastageNo : 'Record Detail',
                            style: AppText.h3,
                          ),
                          Text(mat, style: AppText.bodyStrong.copyWith(color: AppColors.tandoor)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  Container(
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Type', style: AppText.caption),
                            const SizedBox(height: 4),
                            _buildTypeChip(wa.type),
                          ],
                        ),
                        if (wa.action != null && wa.action!.isNotEmpty)
                          Column(
                            children: [
                              Text('Action', style: AppText.caption),
                              const SizedBox(height: 4),
                              _buildActionChip(wa.action) ?? const SizedBox.shrink(),
                            ],
                          ),
                        Column(
                          children: [
                            Text('Quantity', style: AppText.caption),
                            const SizedBox(height: 4),
                            Text('${wa.quantity} $unit', style: AppText.bodyStrong),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Text('Reason:', style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(wa.reason?.isNotEmpty == true ? wa.reason! : 'No reason provided', style: AppText.body),
                  const Divider(height: Gap.xl),
                  if (wa.createdBy.isNotEmpty) ...[
                    Text('Logged By: ${wa.createdBy}', style: AppText.caption),
                    const SizedBox(height: 2),
                  ],
                  if (wa.createdAt != null) ...[
                    Text(
                      'Logged At: ${wa.createdAt!.toLocal().toString().split('.')[0]}',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (wa.updatedAt != null) ...[
                    Text(
                      'Last Updated: ${wa.updatedAt!.toLocal().toString().split('.')[0]}',
                      style: AppText.caption,
                    ),
                  ],
                  if (canWrite) ...[
                    const SizedBox(height: Gap.lg),
                    SizedBox(
                      width: double.infinity,
                      child: BmbButton.outline(
                        label: 'Edit Type / Reason (#91)',
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openEditModal(context, wa, inventoryItems);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openRecordSheet(
    BuildContext context,
    WastageAdjustment? existing,
    List<InventoryItem> inventoryItems,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetCtx) {
        return _WastageRecordForm(
          inventoryItems: inventoryItems,
        );
      },
    );
  }

  void _openEditModal(
    BuildContext context,
    WastageAdjustment existing,
    List<InventoryItem> inventoryItems,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetCtx) {
        return _WastageEditForm(
          existing: existing,
          inventoryItems: inventoryItems,
        );
      },
    );
  }

  Future<void> _deactivateRecord(WastageAdjustment wa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Record'),
        content: Text(
          'Are you sure you want to deactivate record "${wa.wastageNo}"?\n\nDeactivating doesn\'t change stock. To add stock back, use Adjust in Inventory.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(color: AppColors.chilli)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final err = await ref.read(activeWastageAdjustmentProvider.notifier).deactivateWastageAdjustment(wa.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wastage/adjustment deleted successfully'), backgroundColor: AppColors.leaf),
      );
    }
  }

  Future<void> _restoreRecord(WastageAdjustment wa) async {
    final err = await ref.read(inactiveWastageAdjustmentProvider.notifier).restoreWastageAdjustment(wa.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wastage/adjustment restored successfully'), backgroundColor: AppColors.leaf),
      );
    }
  }

  Future<void> _hardDeleteRecord(WastageAdjustment wa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Record'),
        content: Text(
          'Are you sure you want to PERMANENTLY delete record "${wa.wastageNo}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.chilli)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final err = await ref.read(inactiveWastageAdjustmentProvider.notifier).hardDeleteWastageAdjustment(wa.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wastage/adjustment permanently deleted'), backgroundColor: AppColors.leaf),
      );
    }
  }
}

/// Create Form (#88)
class _WastageRecordForm extends ConsumerStatefulWidget {
  final List<InventoryItem> inventoryItems;

  const _WastageRecordForm({required this.inventoryItems});

  @override
  ConsumerState<_WastageRecordForm> createState() => _WastageRecordFormState();
}

class _WastageRecordFormState extends ConsumerState<_WastageRecordForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedInventoryId;
  final String _type = 'wastage';
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInventoryId == null) {
      setState(() => _errorMessage = 'Please select an inventory item');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final payload = {
      'inventoryId': _selectedInventoryId,
      'type': _type,
      'quantity': qty,
      'reason': _reasonController.text.trim(),
    };

    final err = await ref.read(activeWastageAdjustmentProvider.notifier).createWastageAdjustment(payload);

    if (!mounted) return;

    if (err != null) {
      // Keep form open with typed values and server message
      setState(() {
        _isSaving = false;
        _errorMessage = err;
      });
    } else {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wastage/adjustment created successfully'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedInv = widget.inventoryItems.where((i) => i.id == _selectedInventoryId).firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Record Wastage (Deducts Stock)', style: AppText.h3),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  'Direct wastage entry (#88) always deducts inventory stock.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Gap.md),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Gap.md),
                    padding: const EdgeInsets.all(Gap.sm),
                    decoration: BoxDecoration(
                      color: AppColors.chilliSoft,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.chilli),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.chilli, size: 18),
                        const SizedBox(width: Gap.xs),
                        Expanded(child: Text(_errorMessage!, style: AppText.caption.copyWith(color: AppColors.chilli))),
                      ],
                    ),
                  ),

                // Notice about quantity immutability per specification
                Container(
                  padding: const EdgeInsets.all(Gap.sm),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.amber),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.amber, size: 18),
                      const SizedBox(width: Gap.xs),
                      Expanded(
                        child: Text(
                          'Quantity can\'t be changed after saving. Deactivating a record does not return stock to inventory. To add stock back, use Adjust in Inventory.',
                          style: AppText.caption.copyWith(color: AppColors.ink, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.md),

                // Inventory Item Picker (#52)
                Text('Inventory Material *', style: AppText.bodyStrong),
                const SizedBox(height: Gap.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedInventoryId,
                  hint: const Text('Select an inventory item'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                  ),
                  items: widget.inventoryItems.map((inv) {
                    return DropdownMenuItem<String>(
                      value: inv.id,
                      child: Text('${inv.material} (Stock: ${inv.inStock} ${inv.unit})'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedInventoryId = v),
                  validator: (v) => v == null ? 'Inventory item is required' : null,
                ),
                const SizedBox(height: Gap.md),

                // Type: Locked to Wastage per #88 semantics
                Text('Record Type (Deduction)', style: AppText.bodyStrong),
                const SizedBox(height: Gap.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                  decoration: BoxDecoration(
                    color: AppColors.chilliSoft,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.chilli),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.chilli),
                      const SizedBox(width: Gap.xs),
                      Text(
                        'Wastage (Deducts stock)',
                        style: AppText.bodyStrong.copyWith(color: AppColors.chilli),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Direct entries always deduct stock. To add stock back, use Adjust in Inventory.',
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: Gap.md),

                // Quantity Field
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity *', style: AppText.bodyStrong),
                          const SizedBox(height: Gap.xs),
                          TextFormField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              suffixText: selectedInv?.unit ?? '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (selectedInv != null) ...[
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Stock', style: AppText.caption),
                            const SizedBox(height: Gap.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm + 2),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(AppRadii.card),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Text(
                                '${selectedInv.inStock} ${selectedInv.unit}',
                                style: AppText.bodyStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Gap.md),

                // Reason Field
                Text('Reason *', style: AppText.bodyStrong),
                const SizedBox(height: Gap.xs),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Spilled during prep, expired batch, count discrepancy...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please provide a short reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Gap.xl),

                // Save Action
                BmbButton.primary(
                  label: _isSaving ? 'Saving...' : 'Save Record',
                  size: BmbButtonSize.lg,
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit Form (#91) - Only type and reason are mutable per backend schema
class _WastageEditForm extends ConsumerStatefulWidget {
  final WastageAdjustment existing;
  final List<InventoryItem> inventoryItems;

  const _WastageEditForm({
    required this.existing,
    required this.inventoryItems,
  });

  @override
  ConsumerState<_WastageEditForm> createState() => _WastageEditFormState();
}

class _WastageEditFormState extends ConsumerState<_WastageEditForm> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _reasonController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _type = widget.existing.type;
    _reasonController = TextEditingController(text: widget.existing.reason ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'type': _type,
      'reason': _reasonController.text.trim(),
    };

    final err = await ref
        .read(activeWastageAdjustmentProvider.notifier)
        .updateWastageAdjustment(widget.existing.id, payload);

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _isSaving = false;
        _errorMessage = err;
      });
    } else {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wastage/adjustment updated successfully'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mat = widget.existing.inventoryMaterial.isNotEmpty
        ? widget.existing.inventoryMaterial
        : (widget.inventoryItems.where((i) => i.id == widget.existing.inventoryId).firstOrNull?.material ??
            widget.existing.inventoryId);
    final unit = widget.existing.inventoryUnit.isNotEmpty
        ? widget.existing.inventoryUnit
        : (widget.inventoryItems.where((i) => i.id == widget.existing.inventoryId).firstOrNull?.unit ?? '');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Record (${widget.existing.wastageNo})',
                      style: AppText.h3,
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  'Per system rules, quantity and inventory item cannot be changed.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Gap.md),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: Gap.md),
                    padding: const EdgeInsets.all(Gap.sm),
                    decoration: BoxDecoration(
                      color: AppColors.chilliSoft,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.chilli),
                    ),
                    child: Text(_errorMessage!, style: AppText.caption.copyWith(color: AppColors.chilli)),
                  ),

                // Read-only Item and Quantity
                Container(
                  padding: const EdgeInsets.all(Gap.md),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Material (Immutable)', style: AppText.caption),
                          const SizedBox(height: 2),
                          Text(mat, style: AppText.bodyStrong),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Quantity (Immutable)', style: AppText.caption),
                          const SizedBox(height: 2),
                          Text('${widget.existing.quantity} $unit', style: AppText.bodyStrong),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.md),

                // Type Toggle
                Text('Record Type *', style: AppText.bodyStrong),
                const SizedBox(height: Gap.xs),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'wastage'),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                          decoration: BoxDecoration(
                            color: _type == 'wastage' ? AppColors.chilliSoft : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: _type == 'wastage' ? AppColors.chilli : AppColors.line),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Wastage',
                            style: AppText.bodyStrong.copyWith(
                              color: _type == 'wastage' ? AppColors.chilli : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'adjustment'),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                          decoration: BoxDecoration(
                            color: _type == 'adjustment' ? AppColors.blueSoft : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: _type == 'adjustment' ? AppColors.blue : AppColors.line),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Adjustment',
                            style: AppText.bodyStrong.copyWith(
                              color: _type == 'adjustment' ? AppColors.blue : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),

                // Reason Field
                Text('Reason *', style: AppText.bodyStrong),
                const SizedBox(height: Gap.xs),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter updated reason...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Reason cannot be empty';
                    return null;
                  },
                ),
                const SizedBox(height: Gap.xl),

                BmbButton.primary(
                  label: _isSaving ? 'Updating...' : 'Update Record',
                  size: BmbButtonSize.lg,
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
