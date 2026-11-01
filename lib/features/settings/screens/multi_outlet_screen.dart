import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/lifecycle_list_view.dart';
import '../../../models/outlet.dart';
import '../controllers/outlet_controller.dart';
import '../../../mock/mock_state.dart';

class MultiOutletScreen extends ConsumerStatefulWidget {
  const MultiOutletScreen({super.key});

  @override
  ConsumerState<MultiOutletScreen> createState() => _MultiOutletScreenState();
}

class _MultiOutletScreenState extends ConsumerState<MultiOutletScreen> {
  bool _showInactive = false;
  List<Outlet> _inactiveOutlets = [];
  bool _isLoadingInactive = false;

  Future<void> _loadInactive() async {
    setState(() => _isLoadingInactive = true);
    final inactive = await ref
        .read(outletControllerProvider.notifier)
        .fetchInactiveOutlets();
    if (mounted) {
      setState(() {
        _inactiveOutlets = inactive;
        _isLoadingInactive = false;
      });
    }
  }

  void _showOutletModal(BuildContext context, Outlet? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(existing != null ? 'Edit outlet' : 'Add outlet'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Outlet name',
                    hintText: 'e.g. BMB Kitchen — OMR',
                  ),
                ),
                const SizedBox(height: Gap.md),
                TextField(
                  controller: codeCtrl,
                  maxLength: 5,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Short code',
                    hintText: 'OMR',
                  ),
                ),
                const SizedBox(height: Gap.md),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Physical address',
                  ),
                ),
                const SizedBox(height: Gap.md),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '+91 93639 93814',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tandoor),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Outlet name is required')),
                );
                return;
              }

              final code = codeCtrl.text.trim().toUpperCase().isNotEmpty
                  ? codeCtrl.text.trim().toUpperCase()
                  : 'OUT';

              final data = {
                'name': name,
                'code': code,
                'address': addrCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              };

              final controller = ref.read(outletControllerProvider.notifier);
              bool success;
              if (existing != null) {
                success = await controller.updateOutlet(existing.id, data);
              } else {
                success = await controller.createOutlet(data);
              }

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Outlet saved successfully'
                          : 'Failed to save outlet',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onToggleView() {
    setState(() {
      _showInactive = !_showInactive;
    });
    if (_showInactive) {
      _loadInactive();
    }
  }

  Future<void> _handleDeactivate(Outlet outlet) async {
    final success = await ref
        .read(outletControllerProvider.notifier)
        .deactivateOutlet(outlet.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Outlet deactivated' : 'Failed to deactivate',
          ),
        ),
      );
    }
  }

  Future<void> _handleRestore(Outlet outlet) async {
    final success = await ref
        .read(outletControllerProvider.notifier)
        .restoreOutlet(outlet.id);
    if (success && mounted) {
      _loadInactive();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Outlet restored')));
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to restore')));
    }
  }

  Future<void> _handleHardDelete(Outlet outlet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently delete?'),
        content: Text(
          'Are you sure you want to permanently delete "${outlet.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.chilli),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(outletControllerProvider.notifier)
          .deleteOutlet(outlet.id);
      if (success && mounted) {
        _loadInactive();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Outlet deleted')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outletAsync = ref.watch(outletControllerProvider);
    final mockState = ref.watch(
      bmbStateProvider,
    ); // kept for orders/subscriptions context
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return outletAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (activeOutlets) {
        final currentList = _showInactive ? _inactiveOutlets : activeOutlets;

        // Metrics by outlet for today (using mock orders for now since we haven't integrated orders)
        final outletMetrics = activeOutlets.map((o) {
          final todayOrders = mockState.orders.where((order) {
            final orderDate = DateTime.fromMillisecondsSinceEpoch(
              order.createdAtMs,
            ).toIso8601String().substring(0, 10);
            return order.outlet == o.id &&
                order.isCompleted &&
                orderDate == todayStr;
          }).toList();

          final sales = todayOrders.fold<int>(
            0,
            (sum, order) =>
                sum +
                (order.totalPaid.value > 0
                    ? order.totalPaid.value
                    : order.subtotal.value),
          );

          return (outlet: o, sales: sales, orderCount: todayOrders.length);
        }).toList();

        final maxSales = outletMetrics.fold<int>(
          1,
          (max, m) => m.sales > max ? m.sales : max,
        );
        final groupSalesToday = outletMetrics.fold<int>(
          0,
          (sum, m) => sum + m.sales,
        );
        final groupOrdersToday = outletMetrics.fold<int>(
          0,
          (sum, m) => sum + m.orderCount,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallMobile = constraints.maxWidth < 640;
            final kpiCrossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BmbScreenHeader(
                    title: 'Multi-Outlet Management',
                    subtitle:
                        'Compare outlets and switch context from the sidebar',
                    trailing: BmbButton(
                      label: '+ Add outlet',
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      variant: BmbButtonVariant.primary,
                      onPressed: () => _showOutletModal(context, null),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),

                  // KPI Grid
                  GridView(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: kpiCrossAxisCount,
                      crossAxisSpacing: Gap.md,
                      mainAxisSpacing: Gap.md,
                      mainAxisExtent: 144,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BmbKpiTile(
                        label: 'Outlets',
                        value: '${activeOutlets.length}',
                        hint: '${activeOutlets.length} active',
                        icon: const Icon(Icons.domain),
                        iconBg: AppColors.tandoorSoft,
                        iconFg: AppColors.tandoor,
                      ),
                      BmbKpiTile(
                        label: 'Group sales today',
                        value: Paise(groupSalesToday).inr0,
                        hint: 'all outlets',
                        icon: const Icon(Icons.currency_rupee),
                        iconBg: AppColors.leafSoft,
                        iconFg: AppColors.leaf,
                      ),
                      BmbKpiTile(
                        label: 'Group orders today',
                        value: '$groupOrdersToday',
                        hint: 'settled today',
                        icon: const Icon(Icons.receipt_long),
                        iconBg: AppColors.blueSoft,
                        iconFg: AppColors.blue,
                      ),
                      BmbKpiTile(
                        label: 'Subscription covers',
                        value: '${mockState.subscription.outlets}',
                        hint: 'outlets on ${mockState.subscription.plan} plan',
                        icon: const Icon(Icons.card_membership),
                        iconBg: AppColors.plumSoft,
                        iconFg: AppColors.plum,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),

                  // Today by Outlet Breakdown Card
                  BmbCard(
                    padding: const EdgeInsets.all(Gap.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today by outlet', style: AppText.h3),
                        const SizedBox(height: Gap.md),
                        if (outletMetrics.isEmpty)
                          const Text('No outlets available.'),
                        ...outletMetrics.map((m) {
                          final isCurrent =
                              m.outlet.id == mockState.activeOutletId;
                          final ratio = maxSales > 0
                              ? (m.sales / maxSales)
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: Gap.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: Gap.xs,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            m.outlet.name,
                                            style: AppText.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: Gap.xs),
                                          const BmbTag.orange('current'),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${Paise(m.sales).inr0} · ${m.orderCount} ord',
                                      style: AppText.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.line,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.tandoor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),

                  // Outlet List / Table Using LifecycleListView
                  BmbCard(
                    padding: const EdgeInsets.all(Gap.md),
                    child: SizedBox(
                      height: 400,
                      child: _isLoadingInactive
                          ? const Center(child: CircularProgressIndicator())
                          : LifecycleListView<Outlet>(
                              title: 'Outlets',
                              showInactive: _showInactive,
                              onToggleView: _onToggleView,
                              onCreate: () => _showOutletModal(context, null),
                              onEdit: (item) => _showOutletModal(context, item),
                              onDeactivate: _handleDeactivate,
                              onRestore: _handleRestore,
                              onHardDelete: _handleHardDelete,
                              canHardDelete: true, // Outlet allows hard delete
                              items: currentList.map((o) {
                                return LifecycleItem(
                                  data: o,
                                  title: o.name,
                                  subtitle:
                                      '${o.code} · ${o.address ?? "No address"} · ${o.phone ?? "No phone"}',
                                  isActive: o.isActive,
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),

                  // Scoped Data Note Card
                  BmbCard(
                    padding: const EdgeInsets.all(Gap.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BmbTag.blue('How data is scoped'),
                        const SizedBox(height: Gap.sm),
                        Text(
                          'Orders, expenses, purchases and day closings are stored per outlet. '
                          'Menu, staff roles, tax and offers are shared across the group — that is the '
                          'head-office control your document asked for. Outlet-specific menu pricing is a Phase 3 addition.',
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
