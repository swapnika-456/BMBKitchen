import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/food_type_dot.dart';
import '../../../mock/mock_state.dart';
import '../../../models/models.dart';

class CaptainOrderingScreen extends ConsumerStatefulWidget {
  const CaptainOrderingScreen({super.key});

  @override
  ConsumerState<CaptainOrderingScreen> createState() =>
      _CaptainOrderingScreenState();
}

class _CaptainOrderingScreenState extends ConsumerState<CaptainOrderingScreen> {
  String _selectedTableId = 'T3';
  String? _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final notifier = ref.read(bmbStateProvider.notifier);

    // Active table
    final table = state.tables.firstWhere(
      (t) => t.id == _selectedTableId,
      orElse: () => state.tables.first,
    );

    // Find order associated with table
    Order? currentOrder;
    for (final o in state.orders) {
      if (o.tableId == table.id && o.status == OrderStatus.open) {
        currentOrder = o;
        break;
      }
    }

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final totalPendingQty =
        currentOrder?.pending.fold(0, (sum, l) => sum + l.qty) ?? 0;

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Captain Ordering (09)',
            subtitle:
                'Table-side mobile waiter interface · instant kitchen dispatch',
            icon: Icons.phone_android_outlined,
            iconBg: AppColors.plumSoft,
            iconColor: AppColors.plum,
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.plumSoft,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.plum.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: AppColors.plum,
                  ),
                  AppSpacing.gapWSm,
                  Text(
                    'Captain Suresh · Section: All Floors',
                    style: AppText.caption.copyWith(
                      color: AppColors.plum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Table Selector Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontalPadding(context),
              vertical: Gap.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Text('Table:', style: AppText.bodyStrong),
                AppSpacing.gapWMd,
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: state.tables.map((tbl) {
                        final isSel = tbl.id == _selectedTableId;
                        final isOcc = tbl.status == TableStatus.occupied;
                        final isRes = tbl.status == TableStatus.reserved;

                        Color tagBg = AppColors.paper;
                        Color tagFg = AppColors.ink;
                        if (isOcc) {
                          tagBg = AppColors.tandoorSoft;
                          tagFg = AppColors.tandoor;
                        } else if (isRes) {
                          tagBg = AppColors.blueSoft;
                          tagFg = AppColors.blue;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: Gap.sm),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedTableId = tbl.id),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.ink : tagBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                border: Border.all(
                                  color: isSel ? AppColors.ink : AppColors.line,
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tbl.name,
                                    style: AppText.bodyStrong.copyWith(
                                      color: isSel ? Colors.white : tagFg,
                                      fontWeight: isSel
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isOcc
                                          ? AppColors.tandoor
                                          : (isRes
                                                ? AppColors.blue
                                                : AppColors.leaf),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Body
          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left 60%: Menu & Categories
                      Expanded(
                        flex: 6,
                        child: _buildMenuPane(
                          context,
                          state,
                          notifier,
                          currentOrder,
                          table,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.line),
                      // Right 40%: Order Ticket & Kitchen Actions
                      Expanded(
                        flex: 4,
                        child: _buildTicketPane(
                          context,
                          state,
                          notifier,
                          currentOrder,
                          table,
                          totalPendingQty,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _buildMenuPane(
                          context,
                          state,
                          notifier,
                          currentOrder,
                          table,
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      _buildMobileTicketSummary(
                        context,
                        state,
                        notifier,
                        currentOrder,
                        table,
                        totalPendingQty,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPane(
    BuildContext context,
    BmbState state,
    BmbStateNotifier notifier,
    Order? currentOrder,
    RestaurantTable table,
  ) {
    final categories = state.categories;
    var filteredItems = state.menuItems.where((m) => m.avail).toList();
    if (_selectedCategory != null) {
      filteredItems = filteredItems
          .where((m) => m.cat == _selectedCategory)
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filteredItems = filteredItems
          .where((m) => m.name.toLowerCase().contains(q))
          .toList();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: Gap.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filters Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search dishes for table ${table.name}...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Gap.md,
                      vertical: 12,
                    ),
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
              if (_searchQuery.isNotEmpty) ...[
                AppSpacing.gapWSm,
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ],
            ],
          ),
          AppSpacing.gapHMd,

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Dishes'),
                  selected: _selectedCategory == null,
                  onSelected: (s) {
                    if (s) setState(() => _selectedCategory = null);
                  },
                  showCheckmark: false,
                ),
                ...categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(left: Gap.sm),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (s) {
                        if (s) setState(() => _selectedCategory = cat);
                      },
                      showCheckmark: false,
                    ),
                  );
                }),
              ],
            ),
          ),
          AppSpacing.gapHLg,

          // Dishes Grid
          if (filteredItems.isEmpty)
            const BmbEmptyState(
              title: 'No Dishes Found',
              description: 'Try another category or search term.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: Gap.md,
                    mainAxisSpacing: Gap.md,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, idx) {
                    final item = filteredItems[idx];
                    return _buildDishCard(item, notifier, currentOrder, table);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDishCard(
    MenuItem item,
    BmbStateNotifier notifier,
    Order? currentOrder,
    RestaurantTable table,
  ) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FoodTypeDot(type: item.type),
              Text(
                item.price.inr,
                style: AppText.numeric.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.tandoor,
                ),
              ),
            ],
          ),
          AppSpacing.gapHSm,
          Expanded(
            child: Text(
              item.name,
              style: AppText.bodyStrong.copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: BmbButton.primary(
              label: 'Add',
              size: BmbButtonSize.sm,
              onPressed: () {
                Order order =
                    currentOrder ??
                    notifier.startNewOrder(
                      type: OrderType.dinein,
                      tableId: table.id,
                      src: OrderSource.captain,
                    );
                notifier.addLineToPending(order.id, item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${item.name} to Table ${table.name}'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.ink,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketPane(
    BuildContext context,
    BmbState state,
    BmbStateNotifier notifier,
    Order? currentOrder,
    RestaurantTable table,
    int totalPendingQty,
  ) {
    final hasPending = currentOrder != null && currentOrder.pending.isNotEmpty;
    final hasSent = currentOrder != null && currentOrder.items.isNotEmpty;

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table info headline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table ${table.name}', style: AppText.h2),
                  Text(
                    '${table.area} · Max ${table.cap} Pax',
                    style: AppText.caption,
                  ),
                ],
              ),
              BmbTag(
                label: table.isOccupied ? 'Occupied' : 'Vacant',
                variant: table.isOccupied
                    ? BmbTagVariant.orange
                    : BmbTagVariant.green,
              ),
            ],
          ),
          AppSpacing.gapHLg,
          const Divider(height: 1, color: AppColors.line),
          AppSpacing.gapHLg,

          // Pending & Sent items list
          Expanded(
            child: currentOrder == null || (!hasPending && !hasSent)
                ? const BmbEmptyState(
                    title: 'No Items Ordered',
                    description:
                        'Select dishes from the menu to start ordering for this table.',
                  )
                : ListView(
                    children: [
                      if (hasPending) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unsent Items ($totalPendingQty)',
                              style: AppText.bodyStrong.copyWith(
                                color: AppColors.tandoor,
                              ),
                            ),
                            BmbTag(
                              label: 'Not in Kitchen',
                              variant: BmbTagVariant.orange,
                            ),
                          ],
                        ),
                        AppSpacing.gapHSm,
                        ...currentOrder.pending.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final line = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Gap.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.name,
                                        style: AppText.bodyStrong,
                                      ),
                                      Text(
                                        line.unitPrice.inr,
                                        style: AppText.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () => notifier.updatePendingQty(
                                    currentOrder.id,
                                    idx,
                                    -1,
                                  ),
                                ),
                                Text('${line.qty}', style: AppText.bodyStrong),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: AppColors.tandoor,
                                  ),
                                  onPressed: () => notifier.updatePendingQty(
                                    currentOrder.id,
                                    idx,
                                    1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        AppSpacing.gapHLg,
                      ],

                      if (hasSent) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sent to Kitchen',
                              style: AppText.bodyStrong.copyWith(
                                color: AppColors.leaf,
                              ),
                            ),
                            BmbTag(
                              label: 'Active KOT',
                              variant: BmbTagVariant.green,
                            ),
                          ],
                        ),
                        AppSpacing.gapHSm,
                        ...currentOrder.items.map((line) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Gap.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${line.qty}x ${line.name}',
                                  style: AppText.body,
                                ),
                                Text(
                                  line.lineTotal.inr,
                                  style: AppText.numeric,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
          ),

          // Dispatch / Action Bar
          if (hasPending)
            SizedBox(
              width: double.infinity,
              child: BmbButton.primary(
                label: 'Send $totalPendingQty Items to Kitchen (KOT)',
                size: BmbButtonSize.lg,
                icon: const Icon(Icons.soup_kitchen_outlined, size: 20),
                onPressed: () {
                  notifier.sendOrderKOT(currentOrder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('KOT sent to Kitchen successfully!'),
                      backgroundColor: AppColors.leaf,
                    ),
                  );
                },
              ),
            ),
          if (hasSent && !hasPending)
            SizedBox(
              width: double.infinity,
              child: BmbButton.outline(
                label: 'Open in POS Billing',
                onPressed: () => context.go(
                  '/pos?tableId=${table.id}&orderId=${currentOrder.id}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileTicketSummary(
    BuildContext context,
    BmbState state,
    BmbStateNotifier notifier,
    Order? currentOrder,
    RestaurantTable table,
    int totalPendingQty,
  ) {
    final hasPending = currentOrder != null && currentOrder.pending.isNotEmpty;

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(Gap.md),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table ${table.name}', style: AppText.bodyStrong),
                  Text(
                    hasPending
                        ? '$totalPendingQty unsent items'
                        : (table.isOccupied ? 'KOT sent' : 'No items'),
                    style: AppText.caption.copyWith(
                      color: hasPending ? AppColors.tandoor : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (hasPending)
              BmbButton.primary(
                label: 'Send KOT',
                icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
                onPressed: () {
                  notifier.sendOrderKOT(currentOrder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('KOT sent to Kitchen!'),
                      backgroundColor: AppColors.leaf,
                    ),
                  );
                },
              )
            else if (table.isOccupied && currentOrder != null)
              BmbButton.outline(
                label: 'View POS',
                onPressed: () => context.go(
                  '/pos?tableId=${table.id}&orderId=${currentOrder.id}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
