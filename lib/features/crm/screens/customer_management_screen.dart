import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
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
import '../../../mock/mock_state.dart';
import '../../../models/models.dart';

/// Module 15 — Customer Management (CRM)
/// Strict alignment with VIEWS.crm in the HTML reference:
/// - Screen header with total customer count, Export CSV & Add Customer actions
/// - 4 responsive KPI tiles with fixed 135px height (immune to aspect-ratio overflow)
/// - Search filter bar by name, mobile number, and notes
/// - Data table on wide viewports and clean cards on mobile with safe text wrapping
/// - Tier calculation based on loyalty settings (Silver, Gold, Platinum)
/// - Add / Edit / Delete Customer bottom sheet
class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState
    extends ConsumerState<CustomerManagementScreen> {
  String _searchQuery = '';

  String _tierOf(Customer c, LoyaltySettings loyalty) {
    return loyalty.getTierForSpend(c.spend);
  }

  BmbTagVariant _tierVariant(String tier) {
    if (tier == 'Platinum') return BmbTagVariant.plum;
    if (tier == 'Gold') return BmbTagVariant.amber;
    return BmbTagVariant.grey;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final customers = [...state.customers]
      ..sort((a, b) => b.spend.compareTo(a.spend));

    // Filter by search query
    final filtered = customers.where((c) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.notes.toLowerCase().contains(q) ||
          c.addr.toLowerCase().contains(q);
    }).toList();

    // KPI Metrics calculation
    var totalSpendPaise = const Paise(0);
    for (final c in customers) {
      totalSpendPaise = totalSpendPaise + c.spend;
    }
    final repeatCount = customers.where((c) => c.visits > 1).length;
    final repeatPct = customers.isNotEmpty
        ? ((repeatCount / customers.length) * 100).round()
        : 0;
    final avgSpendPaise = customers.isNotEmpty
        ? totalSpendPaise / customers.length
        : const Paise(0);

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Customer Management',
            subtitle:
                '${customers.length} customers · attach a customer at billing to build this database',
            icon: Icons.favorite_border,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BmbButton.outline(
                  label: 'Export CSV',
                  size: BmbButtonSize.sm,
                  icon: const Icon(Icons.download, size: 16),
                  onPressed: () {
                    String csvValue(String value) =>
                        '"${value.replaceAll('"', '""')}"';
                    final csv = [
                      'Name,Phone,Email,Address,Visits,Spend,Points,Tier',
                      ...customers.map(
                        (customer) => [
                          customer.name,
                          customer.phone,
                          customer.email,
                          customer.addr,
                          customer.visits,
                          customer.spend.inr,
                          customer.points,
                          _tierOf(customer, state.loyalty),
                        ].map((value) => csvValue(value.toString())).join(','),
                      ),
                    ].join('\n');
                    Clipboard.setData(ClipboardData(text: csv));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied ${customers.length} customer records as CSV',
                        ),
                        backgroundColor: AppColors.leaf,
                      ),
                    );
                  },
                ),
                BmbButton.primary(
                  label: 'Add Customer',
                  size: BmbButtonSize.sm,
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  onPressed: () => _openCustomerSheet(context, null),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 Responsive KPI Tiles with guaranteed 130px height
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int crossAxisCount = width >= 900 ? 4 : 2;

                      final tiles = [
                        BmbKpiTile(
                          label: 'Customers',
                          value: '${customers.length}',
                          hint: 'in database',
                          icon: const Icon(
                            Icons.favorite_outline,
                            color: AppColors.tandoor,
                            size: 20,
                          ),
                          iconBg: AppColors.tandoorSoft,
                          iconFg: AppColors.tandoor,
                        ),
                        BmbKpiTile(
                          label: 'Repeat customers',
                          value: '$repeatCount',
                          hint: '$repeatPct% of base',
                          icon: const Icon(
                            Icons.people_outline,
                            color: AppColors.leaf,
                            size: 20,
                          ),
                          iconBg: AppColors.leafSoft,
                          iconFg: AppColors.leaf,
                        ),
                        BmbKpiTile(
                          label: 'Lifetime value',
                          value: totalSpendPaise.inr,
                          hint: 'total recorded spend',
                          icon: const Icon(
                            Icons.currency_rupee,
                            color: AppColors.blue,
                            size: 20,
                          ),
                          iconBg: AppColors.blueSoft,
                          iconFg: AppColors.blue,
                        ),
                        BmbKpiTile(
                          label: 'Avg spend / customer',
                          value: avgSpendPaise.inr,
                          hint: 'lifetime average',
                          icon: const Icon(
                            Icons.bar_chart_outlined,
                            color: Color(0xFF96650B),
                            size: 20,
                          ),
                          iconBg: AppColors.amberSoft,
                          iconFg: const Color(0xFF96650B),
                        ),
                      ];

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: Gap.sm,
                          mainAxisSpacing: Gap.sm,
                          mainAxisExtent: 144,
                        ),
                        itemCount: tiles.length,
                        itemBuilder: (context, index) => tiles[index],
                      );
                    },
                  ),
                  AppSpacing.gapHLg,

                  // Search Bar
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by customer name, phone, or notes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
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
                  AppSpacing.gapHLg,

                  // Customer Directory Table or Mobile Cards
                  if (filtered.isEmpty)
                    const BmbEmptyState(
                      title: 'No customers found',
                      description:
                          'Try a different search query or add a customer using the button above.',
                    )
                  else if (screenWidth >= 760)
                    _buildWideTable(context, filtered, state.loyalty)
                  else
                    _buildNarrowList(context, filtered, state.loyalty),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideTable(
    BuildContext context,
    List<Customer> customers,
    LoyaltySettings loyalty,
  ) {
    return BmbCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.paper),
              headingTextStyle: AppText.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              columns: const [
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('MOBILE')),
                DataColumn(label: Text('VISITS')),
                DataColumn(label: Text('LIFETIME SPEND')),
                DataColumn(label: Text('POINTS')),
                DataColumn(label: Text('TIER')),
                DataColumn(label: Text('SINCE')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: customers.map((c) {
                final tier = _tierOf(c, loyalty);
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: AppText.bodyStrong),
                          if (c.notes.isNotEmpty)
                            Text(
                              c.notes,
                              style: AppText.caption.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(c.phone, style: AppText.numeric)),
                    DataCell(Text('${c.visits}', style: AppText.numeric)),
                    DataCell(
                      Text(
                        c.spend.inr,
                        style: AppText.numeric.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(Text('${c.points}', style: AppText.numeric)),
                    DataCell(BmbTag(label: tier, variant: _tierVariant(tier))),
                    DataCell(Text(c.since, style: AppText.caption)),
                    DataCell(
                      BmbButton.outline(
                        label: 'Edit',
                        size: BmbButtonSize.sm,
                        onPressed: () => _openCustomerSheet(context, c),
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

  Widget _buildNarrowList(
    BuildContext context,
    List<Customer> customers,
    LoyaltySettings loyalty,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) => AppSpacing.gapHMd,
      itemBuilder: (context, index) {
        final c = customers[index];
        final tier = _tierOf(c, loyalty);

        return BmbCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: AppText.bodyStrong.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.gapWSm,
                  BmbTag(label: tier, variant: _tierVariant(tier)),
                ],
              ),
              if (c.notes.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text(
                  c.notes,
                  style: AppText.caption.copyWith(
                    color: AppColors.tandoor,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              AppSpacing.gapHSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      c.phone,
                      style: AppText.numeric.copyWith(color: AppColors.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Flexible(
                    child: Text(
                      '${c.visits} visits · ${c.points} pts',
                      style: AppText.caption,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: AppColors.line),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lifetime Spend', style: AppText.caption),
                        Text(
                          c.spend.inr,
                          style: AppText.bodyStrong.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BmbButton.outline(
                    label: 'Edit',
                    size: BmbButtonSize.sm,
                    onPressed: () => _openCustomerSheet(context, c),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCustomerSheet(BuildContext context, Customer? customer) {
    final isEdit = customer != null;
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addrCtrl = TextEditingController(text: customer?.addr ?? '');
    final notesCtrl = TextEditingController(text: customer?.notes ?? '');
    final pointsCtrl = TextEditingController(
      text: (customer?.points ?? 0).toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            top: Gap.lg,
            left: Gap.lg,
            right: Gap.lg,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + Gap.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Customer' : 'Add Customer',
                      style: AppText.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.line),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    hintText: 'e.g. Karthik R',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapHMd,
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. 9840012345',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapHMd,
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'e.g. karthik@example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapHMd,
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address / Area',
                    hintText: 'e.g. AF Block, Anna Nagar',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapHMd,
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Notes & Preferences',
                    hintText: 'e.g. Prefers less spicy, bulk orders',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isEdit) ...[
                  AppSpacing.gapHMd,
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pointsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Loyalty Points',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      AppSpacing.gapWMd,
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Lifetime Spend',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            customer.spend.inr,
                            style: AppText.bodyStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AppSpacing.gapHLg,
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isEdit)
                      BmbButton.danger(
                        label: 'Delete',
                        size: BmbButtonSize.md,
                        onPressed: () {
                          ref
                              .read(bmbStateProvider.notifier)
                              .deleteCustomer(customer.id);
                          Navigator.of(sheetCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer deleted')),
                          );
                        },
                      )
                    else
                      const SizedBox.shrink(),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.xs,
                      children: [
                        BmbButton.outline(
                          label: 'Cancel',
                          size: BmbButtonSize.md,
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                        BmbButton.primary(
                          label: 'Save Customer',
                          size: BmbButtonSize.md,
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            if (name.isEmpty || phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Name and mobile number are required',
                                  ),
                                ),
                              );
                              return;
                            }

                            final updated = Customer(
                              id:
                                  customer?.id ??
                                  'c_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              phone: phone,
                              email: emailCtrl.text.trim(),
                              addr: addrCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                              visits: customer?.visits ?? 0,
                              spend: customer?.spend ?? const Paise(0),
                              points:
                                  int.tryParse(pointsCtrl.text) ??
                                  (customer?.points ?? 0),
                              since:
                                  customer?.since ??
                                  DateTime.now()
                                      .toIso8601String()
                                      .split('T')
                                      .first,
                            );

                            ref
                                .read(bmbStateProvider.notifier)
                                .saveCustomer(updated);
                            Navigator.of(sheetCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Customer ${updated.name} saved!',
                                ),
                                backgroundColor: AppColors.leaf,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
