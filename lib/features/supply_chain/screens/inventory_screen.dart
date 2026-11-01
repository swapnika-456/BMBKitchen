import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
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
import '../../../models/inventory_item.dart';
import '../../../models/vendor.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/inventory_providers.dart';
import '../providers/vendor_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showLowStockOnly = false;
  bool _showInactive = false;

  final _formKey = GlobalKey<FormState>();
  String _material = '';
  String _category = '';
  String _unit = 'kg';
  double _inStock = 0.0;
  double _minLevel = 0.0;
  double _rate = 0.0;
  String? _vendorId;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  final _adjustFormKey = GlobalKey<FormState>();
  String _adjustAction = 'add';
  double _adjustQty = 0.0;
  String _adjustReason = '';

  static const List<String> _allowedUnits = [
    'kg', 'g', 'l', 'ml', 'pcs', 'packet', 'box', 'dozen'
  ];

  bool _canWrite(String? role) {
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  bool _canHardDelete(String? role) {
    return role == 'owner' || role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role;
    final canWrite = _canWrite(role);
    final canHardDelete = _canHardDelete(role);

    if (_showInactive && !canWrite) {
      _showInactive = false;
    }

    final asyncInventory = _showInactive
        ? ref.watch(inactiveInventoryProvider)
        : ref.watch(activeInventoryProvider);
        
    final vendorsAsync = ref.watch(vendorDropdownProvider);

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Inventory Management',
            subtitle: _showInactive ? 'Inactive Materials' : 'Active Materials',
            icon: Icons.inventory_2_outlined,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BmbButton.outline(
                  label: 'Record Wastage',
                  size: BmbButtonSize.sm,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () => context.go('/wastage'),
                ),
                if (canWrite && !_showInactive)
                  BmbButton.primary(
                    label: 'Add Material',
                    size: BmbButtonSize.sm,
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _openStockSheet(context, null, vendorsAsync.value ?? []),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncInventory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading inventory', style: AppText.h3),
                    AppSpacing.gapHSm,
                    Text(err.toString(), style: AppText.body),
                    AppSpacing.gapHMd,
                    BmbButton.outline(
                      label: 'Retry',
                      size: BmbButtonSize.md,
                      onPressed: () {
                        if (_showInactive) {
                          ref.read(inactiveInventoryProvider.notifier).refresh();
                        } else {
                          ref.read(activeInventoryProvider.notifier).refresh();
                        }
                      },
                    ),
                  ],
                ),
              ),
              data: (items) {
                // Summary bar computation
                final totalItems = items.length;
                final lowStockCount = items.where((i) => i.isLow || i.isOut).length;
                var totalValue = 0.0;
                for (final item in items) {
                  totalValue += item.value;
                }

                // Categories
                final categories = {'All'};
                for (final i in items) {
                  if (i.category != null && i.category!.isNotEmpty) {
                    categories.add(i.category!);
                  }
                }

                if (!_selectedCategory.contains('All') &&
                    !categories.contains(_selectedCategory)) {
                  _selectedCategory = 'All';
                }

                // Filtering
                final filtered = items.where((i) {
                  if (_showLowStockOnly && !i.isLow && !i.isOut) return false;
                  if (_selectedCategory != 'All' && i.category != _selectedCategory) {
                    return false;
                  }
                  if (_searchQuery.trim().isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return i.material.toLowerCase().contains(q) ||
                      (i.category?.toLowerCase().contains(q) ?? false) ||
                      (i.inventoryNo?.toLowerCase().contains(q) ?? false);
                }).toList();

                return Column(
                  children: [
                    // Alerts and Summary
                    if (lowStockCount > 0 && !_showInactive)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                          horizontal: AppSpacing.horizontalPadding(context),
                          vertical: Gap.sm,
                        ),
                        padding: const EdgeInsets.all(Gap.sm),
                        decoration: BoxDecoration(
                          color: AppColors.chilliSoft,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.chilli.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.chilli, size: 20),
                            AppSpacing.gapWSm,
                            Expanded(
                              child: Text(
                                '$lowStockCount items are at or below minimum stock levels. Please reorder soon.',
                                style: AppText.body.copyWith(color: AppColors.chilli),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Summary Row
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.horizontalPadding(context),
                        vertical: Gap.sm,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildSummaryTile('Total Items', totalItems.toString(), Icons.layers, context)),
                                    AppSpacing.gapWMd,
                                    Expanded(child: _buildSummaryTile('Low Stock', lowStockCount.toString(), Icons.warning, context, color: AppColors.chilli)),
                                  ],
                                ),
                                AppSpacing.gapHMd,
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildSummaryTile('Total Value', '₹${totalValue.toStringAsFixed(2)}', Icons.account_balance_wallet, context),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: _buildSummaryTile('Total Items', totalItems.toString(), Icons.layers, context)),
                              AppSpacing.gapWMd,
                              Expanded(child: _buildSummaryTile('Low Stock', lowStockCount.toString(), Icons.warning, context, color: AppColors.chilli)),
                              AppSpacing.gapWMd,
                              Expanded(child: _buildSummaryTile('Total Value', '₹${totalValue.toStringAsFixed(2)}', Icons.account_balance_wallet, context)),
                            ],
                          );
                        },
                      ),
                    ),

                    // Controls
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.horizontalPadding(context),
                        vertical: Gap.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search material, category, or ID...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.input),
                                      borderSide: const BorderSide(color: AppColors.line),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.input),
                                      borderSide: const BorderSide(color: AppColors.line),
                                    ),
                                  ),
                                ),
                              ),
                              if (canWrite) ...[
                                AppSpacing.gapWMd,
                                TextButton(
                                  onPressed: () => setState(() => _showInactive = !_showInactive),
                                  child: Text(_showInactive ? 'View Active' : 'View Inactive'),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.gapHSm,
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                FilterChip(
                                  label: const Text('Low Stock Only'),
                                  selected: _showLowStockOnly,
                                  selectedColor: AppColors.chilliSoft,
                                  onSelected: (val) => setState(() => _showLowStockOnly = val),
                                ),
                                AppSpacing.gapWMd,
                                ...categories.map((cat) {
                                  final isSelected = cat == _selectedCategory;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: Gap.sm),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedCategory = cat);
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: filtered.isEmpty
                          ? const BmbEmptyState(
                              title: 'No inventory items yet',
                              description: 'Add your first item.',
                            )
                          : _showInactive
                              ? _buildInactiveList(filtered, canWrite, canHardDelete)
                              : _buildActiveData(filtered, canWrite, vendorsAsync.value ?? []),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon, BuildContext context, {Color color = AppColors.ink}) {
    return Container(
      padding: const EdgeInsets.all(Gap.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          AppSpacing.gapWSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.caption),
                Text(value, style: AppText.h3.copyWith(color: color), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveData(List<InventoryItem> items, bool canWrite, List<Vendor> vendors) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth >= 760) {
      return _buildWideTable(context, items, canWrite, vendors);
    }
    return _buildNarrowList(context, items, canWrite, vendors);
  }

  Widget _buildInactiveList(List<InventoryItem> items, bool canWrite, bool canHardDelete) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
      ),
      child: LifecycleListView<InventoryItem>(
        title: 'Inventory Item',
        items: items
            .map(
              (i) => LifecycleItem(
                data: i,
                title: i.material,
                subtitle: i.inventoryNo ?? i.category ?? 'Item',
                isActive: false,
              ),
            )
            .toList(),
        showInactive: true,
        onToggleView: () => setState(() => _showInactive = false),
        onCreate: () {},
        onEdit: (i) {},
        onDeactivate: (i) {},
        canHardDelete: canHardDelete,
        onRestore: (i) async {
          try {
            await ref.read(inactiveInventoryProvider.notifier).restoreItem(i.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item restored successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
        onHardDelete: (i) async {
          try {
            await ref.read(inactiveInventoryProvider.notifier).hardDeleteItem(i.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item permanently deleted')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildWideTable(BuildContext context, List<InventoryItem> items, bool canWrite, List<Vendor> vendors) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding(context)),
      child: BmbCard(
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.paper),
              headingTextStyle: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.muted),
              columns: const [
                DataColumn(label: Text('MATERIAL')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('IN STOCK')),
                DataColumn(label: Text('MIN LEVEL')),
                DataColumn(label: Text('RATE')),
                DataColumn(label: Text('VALUE')),
                DataColumn(label: Text('VENDOR')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.line,
                              borderRadius: BorderRadius.circular(AppRadii.card),
                              image: item.image?['url'] != null
                                  ? DecorationImage(image: NetworkImage(item.image!['url']), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: item.image?['url'] == null
                                ? const Icon(Icons.inventory_2, size: 20, color: AppColors.muted)
                                : null,
                          ),
                          AppSpacing.gapWSm,
                          Text('${item.material}\n${item.inventoryNo ?? ''}', style: AppText.bodyStrong),
                        ],
                      ),
                    ),
                    DataCell(BmbTag(label: item.category ?? 'N/A', variant: BmbTagVariant.grey)),
                    DataCell(_buildStockDisplay(item)),
                    DataCell(Text('${item.minLevel} ${item.unit ?? ''}', style: AppText.numeric)),
                    DataCell(Text('₹${item.rate.toStringAsFixed(2)}', style: AppText.numeric)),
                    DataCell(Text('₹${item.value.toStringAsFixed(2)}', style: AppText.numeric.copyWith(fontWeight: FontWeight.w700))),
                    DataCell(Text(item.vendorName ?? '-', style: AppText.caption)),
                    DataCell(
                      Wrap(
                        spacing: Gap.xs,
                        children: [
                          BmbButton.outline(
                            label: 'Adjust',
                            size: BmbButtonSize.sm,
                            onPressed: () => _openAdjustSheet(context, item),
                          ),
                          if (canWrite)
                            BmbButton.outline(
                              label: 'Edit',
                              size: BmbButtonSize.sm,
                              onPressed: () => _openStockSheet(context, item, vendors),
                            ),
                          if (canWrite)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.chilli),
                              onPressed: () => _deactivateItem(item),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowList(BuildContext context, List<InventoryItem> items, bool canWrite, List<Vendor> vendors) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding(context)),
      itemCount: items.length,
      separatorBuilder: (_, __) => AppSpacing.gapHMd,
      itemBuilder: (context, index) {
        final item = items[index];
        return BmbCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            image: item.image?['url'] != null
                                ? DecorationImage(image: NetworkImage(item.image!['url']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: item.image?['url'] == null
                              ? const Icon(Icons.inventory_2, size: 20, color: AppColors.muted)
                              : null,
                        ),
                        AppSpacing.gapWSm,
                        Flexible(
                          child: Text('${item.material} (${item.inventoryNo ?? ''})', style: AppText.h3, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  BmbTag(label: item.category ?? 'N/A', variant: BmbTagVariant.grey),
                ],
              ),
              AppSpacing.gapHSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Stock', style: AppText.caption),
                  _buildStockDisplay(item),
                ],
              ),
              AppSpacing.gapHXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Min Level', style: AppText.caption),
                  Text('${item.minLevel} ${item.unit ?? ''}', style: AppText.numeric),
                ],
              ),
              AppSpacing.gapHXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rate', style: AppText.caption),
                  Text('₹${item.rate.toStringAsFixed(2)} / ${item.unit ?? ''}', style: AppText.numeric),
                ],
              ),
              AppSpacing.gapHXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Value', style: AppText.caption),
                  Text('₹${item.value.toStringAsFixed(2)}', style: AppText.numeric.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              if (item.vendorName != null) ...[
                AppSpacing.gapHXs,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vendor', style: AppText.caption),
                    Text(item.vendorName!, style: AppText.body),
                  ],
                ),
              ],
              AppSpacing.gapHMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canWrite)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.chilli),
                      onPressed: () => _deactivateItem(item),
                    ),
                  if (canWrite) AppSpacing.gapWSm,
                  if (canWrite)
                    BmbButton.outline(
                      label: 'Edit',
                      size: BmbButtonSize.sm,
                      onPressed: () => _openStockSheet(context, item, vendors),
                    ),
                  AppSpacing.gapWSm,
                  BmbButton.primary(
                    label: 'Adjust',
                    size: BmbButtonSize.sm,
                    onPressed: () => _openAdjustSheet(context, item),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockDisplay(InventoryItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${item.inStock} ${item.unit ?? ''}',
          style: AppText.numeric.copyWith(
            fontWeight: FontWeight.w700,
            color: item.isOut ? AppColors.chilli : (item.isLow ? AppColors.amber : AppColors.ink),
          ),
        ),
        if (item.isOut || item.isLow) ...[
          AppSpacing.gapWXs,
          Icon(
            item.isOut ? Icons.error : Icons.warning,
            size: 14,
            color: item.isOut ? AppColors.chilli : AppColors.amber,
          ),
        ],
      ],
    );
  }

  void _deactivateItem(InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Item'),
        content: Text('Are you sure you want to deactivate ${item.material}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(color: AppColors.chilli)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(activeInventoryProvider.notifier).deactivateItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deactivated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _openStockSheet(BuildContext context, InventoryItem? item, List<Vendor> vendors) {
    _material = item?.material ?? '';
    _category = item?.category ?? '';
    _unit = item?.unit ?? 'kg';
    if (!const ['kg', 'g', 'l', 'ml', 'pcs', 'packet', 'box', 'dozen'].contains(_unit)) {
      _unit = 'kg'; // Fallback
    }
    _inStock = item?.inStock ?? 0.0;
    _minLevel = item?.minLevel ?? 0.0;
    _rate = item?.rate ?? 0.0;
    _vendorId = item?.vendorId;

    final isEdit = item != null;

    _pickedImage = null;
    Map<String, dynamic>? currentImage = item?.image != null ? Map<String, dynamic>.from(item!.image!) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasImage = _pickedImage != null || currentImage?['url'] != null;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.horizontalPadding(ctx),
                right: AppSpacing.horizontalPadding(ctx),
                top: Gap.lg,
              ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Material' : 'Add Material', style: AppText.h2),
                  AppSpacing.gapHLg,
                  
                  // Image Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.line.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            image: _pickedImage != null
                                ? DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover)
                                : (currentImage?['url'] != null
                                    ? DecorationImage(image: NetworkImage(currentImage!['url']), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: !hasImage
                              ? Center(child: Text('No image yet', style: AppText.caption))
                              : null,
                        ),
                        if (hasImage)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () async {
                                if (_pickedImage != null && !isEdit) {
                                  setSheetState(() => _pickedImage = null);
                                  return;
                                }
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Remove Image'),
                                    content: const Text('Are you sure you want to remove this image?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove', style: TextStyle(color: AppColors.chilli))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (isEdit) {
                                    try {
                                      await ref.read(activeInventoryProvider.notifier).deleteImage(item!.id);
                                      setSheetState(() {
                                        _pickedImage = null;
                                        currentImage = null;
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image removed successfully')));
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove image: $e')));
                                        print('Image delete failed: $e');
                                      }
                                    }
                                  } else {
                                    setSheetState(() => _pickedImage = null);
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapHSm,
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(hasImage ? 'Change image' : 'Add image'),
                      onPressed: () async {
                        final picked = await _picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          if (isEdit) {
                            try {
                              final bytes = await picked.readAsBytes();
                              final mFile = MultipartFile.fromBytes(bytes, filename: picked.name);
                              await ref.read(activeInventoryProvider.notifier).addImage(item!.id, mFile);
                              setSheetState(() {
                                _pickedImage = picked;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image updated successfully')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
                                print('Image upload failed: $e');
                              }
                            }
                          } else {
                            setSheetState(() => _pickedImage = picked);
                          }
                        }
                      },
                    ),
                  ),
                  AppSpacing.gapHLg,

                  TextFormField(
                    initialValue: _material,
                    decoration: const InputDecoration(labelText: 'Material Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => _material = v!.trim(),
                  ),
                  AppSpacing.gapHMd,
                  TextFormField(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => _category = v!.trim(),
                  ),
                  AppSpacing.gapHMd,
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit *'),
                    items: _allowedUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                    onSaved: (v) => _unit = v!,
                  ),
                  AppSpacing.gapHMd,
                  if (!isEdit) ...[
                    TextFormField(
                      initialValue: _inStock == 0 ? '' : _inStock.toString(),
                      decoration: const InputDecoration(labelText: 'Initial Stock'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (v) => _inStock = double.tryParse(v ?? '') ?? 0.0,
                    ),
                    AppSpacing.gapHMd,
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minLevel == 0 ? '' : _minLevel.toString(),
                          decoration: const InputDecoration(labelText: 'Min Level *'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) < 0) ? 'Invalid' : null,
                          onSaved: (v) => _minLevel = double.parse(v!),
                        ),
                      ),
                      AppSpacing.gapWMd,
                      Expanded(
                        child: TextFormField(
                          initialValue: _rate == 0 ? '' : _rate.toString(),
                          decoration: const InputDecoration(labelText: 'Rate (₹) *'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) < 0) ? 'Invalid' : null,
                          onSaved: (v) => _rate = double.parse(v!),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapHMd,
                  DropdownButtonFormField<String?>(
                    value: _vendorId,
                    decoration: const InputDecoration(labelText: 'Vendor'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.vendorName))).toList(),
                    ],
                    onChanged: (v) => setState(() => _vendorId = v),
                    onSaved: (v) => _vendorId = v,
                  ),
                  AppSpacing.gapHLg,
                  SizedBox(
                    width: double.infinity,
                    child: BmbButton.primary(
                      label: isEdit ? 'Save Changes' : 'Create Material',
                      size: BmbButtonSize.lg,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          try {
                            final data = {
                              'material': _material,
                              'category': _category,
                              'unit': _unit,
                              'minLevel': _minLevel,
                              'rate': _rate,
                            };
                            if (!isEdit) {
                              data['inStock'] = _inStock;
                              if (_pickedImage != null) {
                                final bytes = await _pickedImage!.readAsBytes();
                                data['file'] = MultipartFile.fromBytes(bytes, filename: _pickedImage!.name);
                              }
                            }
                            if (_vendorId != null) {
                              data['vendorId'] = _vendorId!;
                            }

                            if (isEdit) {
                              await ref.read(activeInventoryProvider.notifier).updateItem(item.id, data);
                            } else {
                              await ref.read(activeInventoryProvider.notifier).createItem(data);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Item updated successfully' : 'Item created successfully')),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            if (!isEdit) {
                              try {
                                ref.invalidate(activeInventoryProvider);
                                final items = await ref.read(activeInventoryProvider.future);
                                final exists = items.any((i) => i.material.toLowerCase() == _material.toLowerCase());
                                if (exists) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Item saved, but the image couldn't be uploaded. You can add it later from the edit form."),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  return;
                                }
                              } catch (_) {}
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  AppSpacing.gapHLg,
                ],
              ),
            ),
          ),
        );
      },
    );
  },
  );
}

  void _openAdjustSheet(BuildContext context, InventoryItem item) {
    _adjustAction = 'add';
    _adjustQty = 0.0;
    _adjustReason = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.horizontalPadding(ctx),
                right: AppSpacing.horizontalPadding(ctx),
                top: Gap.lg,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _adjustFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adjust Stock: ${item.material}', style: AppText.h2),
                      AppSpacing.gapHSm,
                      Text('Current Stock: ${item.inStock} ${item.unit ?? ''}', style: AppText.body),
                      AppSpacing.gapHLg,
                      DropdownButtonFormField<String>(
                        value: _adjustAction,
                        decoration: const InputDecoration(labelText: 'Action *'),
                        items: const [
                          DropdownMenuItem(value: 'add', child: Text('Add')),
                          DropdownMenuItem(value: 'remove', child: Text('Remove')),
                        ],
                        onChanged: (v) => setSheetState(() => _adjustAction = v!),
                        onSaved: (v) => _adjustAction = v!,
                      ),
                      AppSpacing.gapHMd,
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Quantity *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || double.tryParse(v) == null) return 'Invalid';
                          final val = double.parse(v);
                          if (val <= 0) return 'Must be greater than 0';
                          if (_adjustAction == 'remove' && val > item.inStock) {
                            return 'Cannot remove more than in-stock';
                          }
                          return null;
                        },
                        onSaved: (v) => _adjustQty = double.parse(v!),
                      ),
                      AppSpacing.gapHMd,
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Reason (Optional)'),
                        onSaved: (v) => _adjustReason = v?.trim() ?? '',
                      ),
                      AppSpacing.gapHLg,
                      SizedBox(
                        width: double.infinity,
                        child: BmbButton.primary(
                          label: 'Adjust Stock',
                          size: BmbButtonSize.lg,
                          onPressed: () async {
                            if (_adjustFormKey.currentState!.validate()) {
                              _adjustFormKey.currentState!.save();
                              try {
                                final data = {
                                  'action': _adjustAction,
                                  'quantity': _adjustQty,
                                };
                                if (_adjustReason.isNotEmpty) {
                                  data['reason'] = _adjustReason;
                                }
                                
                                await ref.read(activeInventoryProvider.notifier).adjustStock(item.id, data);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Inventory stock adjusted successfully')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                      AppSpacing.gapHLg,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
