import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_bottom_sheet.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_section_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/bmb_text_field.dart';
import '../../../core/widgets/lifecycle_list_view.dart';
import '../../../mock/mock_state.dart';
import '../../../models/models.dart';
import '../../../routing/app_router.dart';
import '../../settings/controllers/tax_settings_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../providers/table_providers.dart';

class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() =>
      _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen> {
  Timer? _ticker;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool _canManageTables(Role role) {
    final name = role.name.toLowerCase();
    return name == 'owner' || name == 'admin' || name == 'cto';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final activeTablesAsync = ref.watch(activeTablesProvider);
    final inactiveTablesAsync = ref.watch(inactiveTablesProvider);

    final canManage = _canManageTables(state.currentUserRole);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: Gap.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Top Header
          if (isTablet)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table Management',
                        style: AppText.h1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapHXs,
                      Text(
                        'Tap a table to take or continue an order, or manage table status',
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapWLg,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canManage) ...[
                      BmbSecondaryButton(
                        label: 'Add Table',
                        onPressed: () =>
                            _showEditTableModal(context, ref, null),
                      ),
                      AppSpacing.gapWMd,
                    ],
                    BmbPrimaryButton(
                      label: 'Takeaway Order',
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      onPressed: () {
                        final order = ref
                            .read(bmbStateProvider.notifier)
                            .startNewOrder(type: OrderType.takeaway);
                        ref
                            .read(appRouterProvider)
                            .go('/pos?orderId=${order.id}');
                      },
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table Management',
                  style: AppText.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.gapHXs,
                Text(
                  'Tap a table to take or continue an order',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.gapHMd,
                Row(
                  children: [
                    if (canManage) ...[
                      Expanded(
                        child: BmbSecondaryButton(
                          label: 'Add Table',
                          onPressed: () =>
                              _showEditTableModal(context, ref, null),
                        ),
                      ),
                      AppSpacing.gapWMd,
                    ],
                    Expanded(
                      child: BmbPrimaryButton(
                        label: 'Takeaway Order',
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        onPressed: () {
                          final order = ref
                              .read(bmbStateProvider.notifier)
                              .startNewOrder(type: OrderType.takeaway);
                          ref
                              .read(appRouterProvider)
                              .go('/pos?orderId=${order.id}');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          AppSpacing.gapHLg,

          // Status Legend
          Row(
            children: [
              _buildLegendItem('Available', AppColors.leaf),
              AppSpacing.gapWLg,
              _buildLegendItem('Occupied', AppColors.tandoor),
              AppSpacing.gapWLg,
              _buildLegendItem('Reserved', AppColors.blue),
            ],
          ),
          AppSpacing.gapHXxl,

          activeTablesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                children: [
                  Text('Failed to load tables: $err', style: AppText.body),
                  TextButton(
                    onPressed: () =>
                        ref.read(activeTablesProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (tables) {
              if (tables.isEmpty) {
                return BmbEmptyState(
                  emoji: '🪑',
                  title: 'No Tables yet for this outlet',
                  description:
                      'Add floor sections and tables to start seating dine-in guests.',
                  actionLabel: canManage ? 'Add Table' : null,
                  onAction: canManage
                      ? () => _showEditTableModal(context, ref, null)
                      : null,
                );
              }

              final areas = tables.map((t) => t.area).toSet().toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final area in areas) ...[
                    _buildAreaGrid(context, ref, area, tables),
                    AppSpacing.gapHXxl,
                  ],
                ],
              );
            },
          ),

          if (canManage) ...[
            const BmbSectionHeader(
              title: 'TABLE SETUP & CONFIGURATION',
              isOverline: true,
            ),
            AppSpacing.gapHMd,
            SizedBox(
              height: 400,
              child: activeTablesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const SizedBox(),
                data: (activeTables) {
                  return inactiveTablesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const SizedBox(),
                    data: (inactiveTables) {
                      final tables = _showInactive ? inactiveTables : activeTables;
                      return _buildCustomTableList(context, ref, tables, !_showInactive, canManage);
                    },
                  );
                },
              ),
            ),
            AppSpacing.gapHXxl,
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTableList(
    BuildContext context,
    WidgetRef ref,
    List<RestaurantTable> tables,
    bool isActive,
    bool canManage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            Text(
              isActive ? 'Active Tables' : 'Inactive Tables',
              style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showInactive = !_showInactive),
                  child: Text(isActive ? 'View Inactive' : 'View Active'),
                ),
                if (canManage)
                  ElevatedButton.icon(
                    onPressed: () => _showEditTableModal(context, ref, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tandoor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
        AppSpacing.gapHMd,
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('TABLE', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(flex: 3, child: Text('AREA', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('SEATS', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('STATUS', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 80), // For Edit button
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: tables.isEmpty
                    ? Center(child: Text('No items found.', style: AppText.body))
                    : ListView.separated(
                        itemCount: tables.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, index) {
                          final t = tables[index];
                          
                          Widget statusWidget;
                          switch (t.status) {
                            case TableStatus.available:
                              statusWidget = const BmbTag.green('available');
                              break;
                            case TableStatus.occupied:
                              statusWidget = const BmbTag(label: 'occupied', variant: BmbTagVariant.orange);
                              break;
                            case TableStatus.reserved:
                              statusWidget = const BmbTag.blue('reserved');
                              break;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(t.name, style: AppText.bodyStrong)),
                                Expanded(flex: 3, child: Text(t.area, style: AppText.body)),
                                Expanded(flex: 2, child: Text('${t.cap}', style: AppText.body)),
                                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: statusWidget)),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        if (isActive) {
                                          _showEditTableModal(context, ref, t);
                                        } else {
                                          ref.read(inactiveTablesProvider.notifier).recoverTable(t.id);
                                        }
                                      },
                                      child: Text(isActive ? 'Edit' : 'Restore', style: AppText.caption),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmHardDelete(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: Text(
          'Are you sure you want to permanently delete table "${table.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(inactiveTablesProvider.notifier)
                  .hardDeleteTable(table.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Table permanently deleted')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.chilli),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AppSpacing.gapWSm,
        Text(
          label,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAreaGrid(
    BuildContext context,
    WidgetRef ref,
    String area,
    List<RestaurantTable> allTables,
  ) {
    final tables = allTables.where((t) => t.area == area).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BmbSectionHeader(
          title: area.toUpperCase(),
          count: tables.length.toString(),
          isOverline: true,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 136,
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableTile(context, ref, table);
          },
        ),
      ],
    );
  }

  Widget _buildTableTile(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    Color bg;
    Color borderCol;
    Widget statusWidget;

    switch (table.status) {
      case TableStatus.available:
        bg = AppColors.card;
        borderCol = AppColors.line;
        statusWidget = const BmbTag.green('Available');
        break;
      case TableStatus.occupied:
        bg = AppColors.tandoorSoft;
        borderCol = AppColors.tandoor;
        statusWidget = const BmbTag(
          label: 'Occupied',
          variant: BmbTagVariant.orange,
        );
        break;
      case TableStatus.reserved:
        bg = AppColors.blueSoft;
        borderCol = AppColors.blue;
        statusWidget = const BmbTag.blue('Reserved');
        break;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: () => _showTableActionsModal(context, ref, table),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: borderCol,
              width: table.status == TableStatus.available ? 1.0 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                table.name,
                style: AppText.h3.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${table.cap} seats', style: AppText.caption),
              statusWidget,
            ],
          ),
        ),
      ),
    );
  }

  void _showTableActionsModal(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    showBmbModal(
      context: context,
      title: 'Table ${table.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Change table status or make a reservation.',
            style: AppText.body,
          ),
          AppSpacing.gapHLg,
          Row(
            children: [
              Expanded(
                child: BmbSecondaryButton(
                  label: 'Mark Available',
                  onPressed: () {
                    ref
                        .read(activeTablesProvider.notifier)
                        .updateStatus(table.id, 'available');
                    Navigator.pop(context);
                  },
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: BmbSecondaryButton(
                  label: 'Mark Occupied',
                  onPressed: () {
                    ref
                        .read(activeTablesProvider.notifier)
                        .updateStatus(table.id, 'occupied');
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          AppSpacing.gapHMd,
          BmbPrimaryButton(
            label: 'Reserve Table',
            onPressed: () {
              Navigator.pop(context);
              _showReserveModal(context, ref, table);
            },
          ),
        ],
      ),
    );
  }

  void _showReserveModal(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showBmbModal(
      context: context,
      title: 'Reserve Table ${table.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BmbTextField(
            label: 'Customer Name *',
            controller: nameCtrl,
            autofocus: true,
          ),
          AppSpacing.gapHMd,
          BmbTextField(
            label: 'Reservation Time *',
            hint: 'e.g. 8:00 PM',
            controller: timeCtrl,
          ),
          AppSpacing.gapHMd,
          BmbTextField(
            label: 'Phone (Optional)',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          AppSpacing.gapHMd,
          BmbTextField(label: 'Notes (Optional)', controller: notesCtrl),
          AppSpacing.gapHXxl,
          Row(
            children: [
              Expanded(
                child: BmbSecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: BmbPrimaryButton(
                  label: 'Confirm Reservation',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final time = timeCtrl.text.trim();
                    if (name.isEmpty || time.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Time are required'),
                        ),
                      );
                      return;
                    }

                    final data = {
                      'customerName': name,
                      'reservationTime': time,
                      'phone': phoneCtrl.text.trim(),
                      'notes': notesCtrl.text.trim(),
                    };

                    final success = await ref
                        .read(activeTablesProvider.notifier)
                        .reserveTable(table.id, data);
                    if (success && mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Table reserved successfully'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditTableModal(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable? table,
  ) {
    final isEditing = table != null;
    final nameCtrl = TextEditingController(text: table?.name ?? '');
    final capCtrl = TextEditingController(text: '${table?.cap ?? 4}');
    final locCtrl = TextEditingController(text: table?.area ?? 'Main Area');
    final taxCtrl = TextEditingController(
      text: table?.taxPercent?.toString() ?? '',
    );

    showBmbModal(
      context: context,
      title: isEditing ? 'Edit Table ${table.name}' : 'Add New Table',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BmbTextField(
            label: 'Table Name / Number *',
            hint: 'e.g. T1, T2, Outdoor 1',
            controller: nameCtrl,
            autofocus: !isEditing,
          ),
          AppSpacing.gapHLg,
          Row(
            children: [
              Expanded(
                child: BmbTextField(
                  label: 'Capacity (Seats) *',
                  hint: '4',
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: BmbTextField(
                  label: 'Area / Section (Optional)',
                  hint: 'Ground Floor',
                  controller: locCtrl,
                ),
              ),
            ],
          ),
          AppSpacing.gapHLg,
          if (!isEditing)
            BmbTextField(
              label: 'Tax Percent (Optional)',
              hint: 'e.g. 5',
              controller: taxCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          AppSpacing.gapHXxl,
          Row(
            children: [
              Expanded(
                child: BmbSecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: BmbPrimaryButton(
                  label: isEditing ? 'Save Changes' : 'Create Table',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final cap = int.tryParse(capCtrl.text.trim());
                    if (name.isEmpty || cap == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and valid capacity are required'),
                        ),
                      );
                      return;
                    }

                    final data = <String, dynamic>{
                      'tableName': name,
                      'capacity': cap,
                    };

                    final loc = locCtrl.text.trim();
                    if (loc.isNotEmpty) {
                      data['location'] = loc;
                    }

                    if (!isEditing) {
                      final activeOutlet = ref.read(activeOutletProvider);
                      if (activeOutlet == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active outlet found')),
                        );
                        return;
                      }
                      data['outletId'] = activeOutlet.id;

                      final tax = double.tryParse(taxCtrl.text.trim());
                      if (tax != null) {
                        data['taxPercent'] = tax;
                      }

                      final success = await ref
                          .read(activeTablesProvider.notifier)
                          .createTable(data);
                      if (success && mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      final success = await ref
                          .read(activeTablesProvider.notifier)
                          .updateTable(table.id, data);
                      if (success && mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
