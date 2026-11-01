import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/lifecycle_list_view.dart';
import '../../../models/models.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/purchase_controller.dart';
import '../providers/vendor_providers.dart';
import '../providers/inventory_providers.dart';

class PurchaseManagementScreen extends ConsumerStatefulWidget {
  const PurchaseManagementScreen({super.key});

  @override
  ConsumerState<PurchaseManagementScreen> createState() => _PurchaseManagementScreenState();
}

class _PurchaseManagementScreenState extends ConsumerState<PurchaseManagementScreen> {
  String _searchQuery = '';
  String _vendorFilter = '';
  String _statusFilter = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activeVendorsProvider.notifier).refresh();
      ref.read(activeInventoryProvider.notifier).refresh();
    });
  }

  bool _canWrite(String? role) {
    final r = role?.toLowerCase();
    return r == 'owner' || r == 'admin' || r == 'cto';
  }

  bool _canHardDelete(String? role) {
    final r = role?.toLowerCase();
    return r == 'owner' || r == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final canWrite = _canWrite(user?.role);
    final canHardDelete = _canHardDelete(user?.role);
    final isStaff = !canWrite;

    final activeAsync = ref.watch(activePurchaseProvider);
    final inactiveAsync = ref.watch(inactivePurchaseProvider);
    final purchasesAsync = _showInactive ? inactiveAsync : activeAsync;

    final vendorsAsync = ref.watch(activeVendorsProvider);
    final vendors = vendorsAsync.value ?? [];

    final activeInventoryAsync = ref.watch(activeInventoryProvider);
    final inventoryItems = activeInventoryAsync.value ?? [];


    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Purchase Management',
            subtitle: 'Manage purchase entries & stock updates',
            icon: Icons.shopping_cart_outlined,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: isStaff ? null : BmbButton.primary(
              label: 'New Purchase',
              size: BmbButtonSize.sm,
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => _openNewPurchaseSheet(context, vendors, inventoryItems),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: purchasesAsync.when(
                data: (purchases) {
                  // Filter purchases
                  final filtered = purchases.where((p) {
                    final q = _searchQuery.toLowerCase();
                    final vendorName = _resolveVendorName(p, vendors).toLowerCase();
                    final matchesSearch = p.purchaseNo.toLowerCase().contains(q) || vendorName.contains(q);
                    final matchesVendor = _vendorFilter.isEmpty || p.vendorId == _vendorFilter;
                    final matchesStatus = _statusFilter.isEmpty || p.paymentStatus == _statusFilter;
                    return matchesSearch && matchesVendor && matchesStatus;
                  }).toList();
                  
                  // Latest first
                  filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filters & KPI
                      _buildFiltersAndKpis(context, purchases, vendors),
                      AppSpacing.gapHLg,

                      // Purchases List
                      if (isStaff && filtered.isEmpty)
                         const BmbEmptyState(
                          title: 'No purchase records found',
                          description: 'No active purchases match your search.',
                        )
                      else if (!isStaff)
                        BmbCard(
                          child: SizedBox(
                            height: 600, // Fixed height for lifecycle list view
                            child: LifecycleListView<Purchase>(
                              title: 'Purchases',
                              items: filtered.map((p) => LifecycleItem(
                                data: p,
                                title: '${p.purchaseNo} - ${_resolveVendorName(p, vendors)}',
                                subtitle: '${p.items.length} items | Total: ₹${p.totalAmount.toStringAsFixed(2)} | Status: ${p.paymentStatus}',
                                isActive: p.isActive,
                              )).toList(),
                              showInactive: _showInactive,
                              onToggleView: () => setState(() => _showInactive = !_showInactive),
                              onCreate: () => _openNewPurchaseSheet(context, vendors, inventoryItems),
                              onEdit: (p) => _openViewPurchaseModal(context, p, vendors, inventoryItems, !isStaff),
                              onDeactivate: _deactivatePurchase,
                              onRestore: _restorePurchase,
                              onHardDelete: _hardDeletePurchase,
                              canHardDelete: canHardDelete,
                            ),
                          ),
                        )
                      else
                         _buildStaffView(context, filtered, vendors, inventoryItems),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $e'),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(activePurchaseProvider);
                          ref.invalidate(inactivePurchaseProvider);
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveVendorName(Purchase p, List<Vendor> vendors) {
    if (p.vendorName.isNotEmpty && p.vendorName != 'Unknown Vendor') {
      return p.vendorName;
    }
    final match = vendors.where((v) => v.id == p.vendorId).firstOrNull;
    if (match != null && match.vendorName.isNotEmpty) {
      return match.vendorName;
    }
    return p.vendorName.isNotEmpty ? p.vendorName : 'Unknown Vendor';
  }

  Widget _buildStaffView(BuildContext context, List<Purchase> filtered, List<Vendor> vendors, List<InventoryItem> inventoryItems) {
      if (filtered.isEmpty) return const SizedBox();
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
            final p = filtered[index];
            return ListTile(
                title: Text('${p.purchaseNo} - ${_resolveVendorName(p, vendors)}'),
                subtitle: Text('${p.items.length} items | Total: ₹${p.totalAmount.toStringAsFixed(2)} | Status: ${p.paymentStatus}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _openViewPurchaseModal(context, p, vendors, inventoryItems, false),
            );
        },
      );
  }

  Widget _buildFiltersAndKpis(BuildContext context, List<Purchase> purchases, List<Vendor> vendors) {
    // Basic KPI calculation
    double totalSpend = 0;
    double outstanding = 0;
    for (final p in purchases) {
      totalSpend += p.totalAmount;
      if (p.paymentStatus != 'paid') {
        outstanding += p.totalAmount;
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                    BmbKpiTile(
                        label: 'Total Spend',
                        value: '₹${totalSpend.toStringAsFixed(0)}',
                        icon: const Icon(Icons.shopping_cart, size: 20),
                    ),
                    BmbKpiTile(
                        label: 'Unpaid / part-paid total',
                        value: '₹${outstanding.toStringAsFixed(0)}',
                        hint: "Partial payments aren't tracked",
                        icon: const Icon(Icons.money_off, size: 20),
                    ),
                ]
            ),
            AppSpacing.gapHLg,
            Row(
                children: [
                    Expanded(
                        child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                            hintText: 'Search by PO number or vendor...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(),
                        ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                        value: _vendorFilter.isEmpty ? null : _vendorFilter,
                        hint: const Text('All Vendors'),
                        items: [
                            const DropdownMenuItem(value: '', child: Text('All Vendors')),
                            ...vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.vendorName))),
                        ],
                        onChanged: (v) => setState(() => _vendorFilter = v ?? ''),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                        value: _statusFilter.isEmpty ? null : _statusFilter,
                        hint: const Text('All Statuses'),
                        items: const [
                            DropdownMenuItem(value: '', child: Text('All Statuses')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'partial', child: Text('Partial')),
                            DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v ?? ''),
                    ),
                ]
            )
        ]
    );
  }

  Future<void> _deactivatePurchase(Purchase p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Purchase'),
        content: Text('Are you sure you want to deactivate purchase ${p.purchaseNo}?\n\nDeactivating doesn\'t change stock. If this purchase was entered by mistake, use Adjust in Inventory (remove) to correct stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate', style: TextStyle(color: AppColors.chilli))),
        ],
      ),
    );
    if (confirm == true) {
      final err = await ref.read(activePurchaseProvider.notifier).deletePurchase(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Purchase deactivated successfully')));
        if (err == null) ref.read(activeInventoryProvider.notifier).refresh(); // check stock
      }
    }
  }

  Future<void> _restorePurchase(Purchase p) async {
    final err = await ref.read(inactivePurchaseProvider.notifier).restorePurchase(p.id);
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Purchase restored successfully')));
        if (err == null) ref.read(activeInventoryProvider.notifier).refresh(); // check stock
    }
  }

  Future<void> _hardDeletePurchase(Purchase p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Purchase'),
        content: Text('This action cannot be undone. Are you sure you want to permanently delete purchase ${p.purchaseNo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.chilli))),
        ],
      ),
    );
    if (confirm == true) {
      final err = await ref.read(inactivePurchaseProvider.notifier).hardDeletePurchase(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Purchase permanently deleted')));
        if (err == null) ref.read(activeInventoryProvider.notifier).refresh(); // check stock
      }
    }
  }

  void _openViewPurchaseModal(BuildContext context, Purchase p, List<Vendor> vendors, List<InventoryItem> inventoryItems, bool canChangeStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PO: ${p.purchaseNo}', style: AppText.h3),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                  ],
                ),
                Text('Vendor: ${_resolveVendorName(p, vendors)}', style: AppText.bodyStrong),
                Text('Date: ${p.createdAt?.toLocal().toString().split('.')[0] ?? ''}'),
                Text('Status: ${p.paymentStatus}', style: AppText.bodyStrong.copyWith(color: AppColors.tandoor)),
                if (canChangeStatus)
                    TextButton(
                        onPressed: () async {
                            final status = await showDialog<String>(
                                context: context,
                                builder: (ctx) => SimpleDialog(
                                    title: const Text('Change Payment Status'),
                                    children: [
                                        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'pending'), child: const Text('Pending')),
                                        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'partial'), child: const Text('Partial')),
                                        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'paid'), child: const Text('Paid')),
                                    ],
                                )
                            );
                            if (status != null && status != p.paymentStatus) {
                                final err = await ref.read(activePurchaseProvider.notifier).updatePaymentStatus(p.id, status);
                                if (mounted) {
                                    Navigator.pop(sheetCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Payment status updated')));
                                }
                            }
                        },
                        child: const Text('Change Status')
                    ),
                const Divider(),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                ...p.items.map((i) {
                    final inv = inventoryItems.firstWhere((inv) => inv.id == i.inventoryId, orElse: () => InventoryItem(id: '', organizationId: '', material: i.inventoryName, category: '', unit: '', minLevel: 0, rate: 0, inStock: 0, isActive: true));
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${inv.material} (${i.quantity} ${inv.unit})'),
                        subtitle: Text('Rate: ₹${i.rate}'),
                        trailing: Text('₹${i.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                }),
                const Divider(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹${p.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ]
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _openNewPurchaseSheet(BuildContext context, List<Vendor> vendors, List<InventoryItem> inventoryItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (sheetCtx) {
        return _NewPurchaseForm(vendors: vendors, inventoryItems: inventoryItems);
      },
    );
  }
}

class _NewPurchaseForm extends ConsumerStatefulWidget {
  final List<Vendor> vendors;
  final List<InventoryItem> inventoryItems;

  const _NewPurchaseForm({required this.vendors, required this.inventoryItems});

  @override
  ConsumerState<_NewPurchaseForm> createState() => _NewPurchaseFormState();
}

class _NewPurchaseFormState extends ConsumerState<_NewPurchaseForm> {
  String? _selectedVendor;
  String _paymentStatus = 'pending';
  final List<Map<String, dynamic>> _lines = [];
  bool _isSaving = false;

  void _addLine() {
    setState(() {
      _lines.add({'inventoryId': null, 'quantity': 1.0, 'rate': 0.0});
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  double get _total {
    double t = 0;
    for (final l in _lines) {
      t += (l['quantity'] as double) * (l['rate'] as double);
    }
    return t;
  }

  Future<void> _save() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
      return;
    }
    
    final validLines = _lines.where((l) => l['inventoryId'] != null && l['quantity'] > 0).toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one valid item with quantity > 0')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: const Text('Items cannot be edited after saving. To correct a mistake, you must delete and re-create. Do you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm & Save')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    final vendorObj = widget.vendors.where((v) => v.id == _selectedVendor).firstOrNull;
    final data = {
      'vendorId': _selectedVendor,
      if (vendorObj != null) 'vendorName': vendorObj.vendorName,
      'paymentStatus': _paymentStatus,
      'items': validLines.map((l) => {
        'inventoryId': l['inventoryId'],
        'quantity': l['quantity'],
        'rate': l['rate'],
      }).toList(),
    };

    final err = await ref.read(activePurchaseProvider.notifier).createPurchase(data);
    
    if (!mounted) return;
    
    setState(() => _isSaving = false);
    
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase created successfully'), backgroundColor: AppColors.leaf));
      // Refresh inventory because stock might change
      ref.read(activeInventoryProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Gap.lg, right: Gap.lg, top: Gap.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Purchase', style: AppText.h3),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedVendor,
            decoration: const InputDecoration(labelText: 'Vendor', border: OutlineInputBorder()),
            items: widget.vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.vendorName))).toList(),
            onChanged: (v) => setState(() => _selectedVendor = v),
          ),
          const SizedBox(height: 16),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _lines.length,
              itemBuilder: (ctx, i) {
                final line = _lines[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: line['inventoryId'],
                          decoration: const InputDecoration(labelText: 'Material', border: OutlineInputBorder()),
                          items: widget.inventoryItems.map((inv) => DropdownMenuItem<String>(value: inv.id, child: Text('${inv.material} (${inv.unit ?? ''})'))).toList(),
                          onChanged: (v) {
                            setState(() {
                              line['inventoryId'] = v;
                              if (v != null) {
                                final inv = widget.inventoryItems.firstWhere((item) => item.id == v);
                                line['rate'] = inv.rate;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: line['quantity'].toString(),
                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => line['quantity'] = double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          key: ValueKey('${line['inventoryId']}_rate'), // rebuild if inventory selected
                          initialValue: line['rate'].toString(),
                          decoration: const InputDecoration(labelText: 'Rate', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => line['rate'] = double.tryParse(v) ?? 0),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeLine(i)),
                    ],
                  ),
                );
              },
            ),
          ),
          TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Add Item Line')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentStatus,
            decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'partial', child: Text('Partial')),
              DropdownMenuItem(value: 'paid', child: Text('Paid')),
            ],
            onChanged: (v) => setState(() => _paymentStatus = v!),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ₹${_total.toStringAsFixed(2)}', style: AppText.h3),
              BmbButton.primary(
                label: _isSaving ? 'Saving...' : 'Save Purchase',
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
