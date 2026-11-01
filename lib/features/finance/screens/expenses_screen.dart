import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_bottom_sheet.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../mock/mock_state.dart';
import '../../../models/expense.dart';

const List<String> kExpenseCategories = [
  'Rent',
  'Salary & wages',
  'Electricity',
  'Gas',
  'Water',
  'Maintenance',
  'Marketing',
  'Packaging',
  'Transport',
  'Licences',
  'Miscellaneous',
];

const List<String> kPaymentModes = [
  'Cash',
  'UPI',
  'Bank transfer',
  'Card',
  'Cheque',
];

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final now = DateTime.now();
    final currentYearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final outletExpenses =
        state.expenses.where((e) => e.outlet == state.activeOutletId).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final mtdExpenses = outletExpenses
        .where((e) => e.date.startsWith(currentYearMonth))
        .toList();

    final totalExpenseMtd = mtdExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amt.value,
    );

    // Group MTD by category
    final byCat = <String, int>{};
    for (final e in mtdExpenses) {
      byCat[e.cat] = (byCat[e.cat] ?? 0) + e.amt.value;
    }
    final maxCatValue = byCat.values.fold<int>(
      1,
      (max, v) => v > max ? v : max,
    );

    // Sales MTD
    final completedOrders = state.orders.where(
      (o) =>
          o.isCompleted &&
          o.outlet == state.activeOutletId &&
          DateTime.fromMillisecondsSinceEpoch(
            o.createdAtMs,
          ).toIso8601String().startsWith(currentYearMonth),
    );
    final salesMtd = completedOrders.fold<int>(
      0,
      (sum, o) =>
          sum + (o.totalPaid.value > 0 ? o.totalPaid.value : o.subtotal.value),
    );

    // Purchases MTD
    final purMtd = state.purchases
        .where(
          (p) =>
              p.outlet == state.activeOutletId &&
              p.date.startsWith(currentYearMonth),
        )
        .fold<int>(0, (sum, p) => sum + p.total.value);

    // Rough operating margin
    final roughMargin = salesMtd > 0
        ? (((salesMtd - totalExpenseMtd - purMtd) / salesMtd) * 100).round()
        : null;

    // Filtered expenses
    final query = _searchController.text.trim().toLowerCase();
    final filteredExpenses = outletExpenses.where((e) {
      if (_selectedCategory != null && e.cat != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final descMatch = e.desc.toLowerCase().contains(query);
        final payeeMatch = e.payee.toLowerCase().contains(query);
        final modeMatch = e.mode.toLowerCase().contains(query);
        if (!descMatch && !payeeMatch && !modeMatch) return false;
      }
      return true;
    }).toList();

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
                title: 'Expense Management',
                subtitle: 'Running costs outside raw material purchases',
                trailing: BmbButton(
                  label: '+ Log expense',
                  icon: const Icon(Icons.add, size: 18),
                  variant: BmbButtonVariant.primary,
                  onPressed: () => _showAddExpenseDialog(context),
                ),
              ),
              const SizedBox(height: Gap.lg),

              // KPI Tiles (2*2 grid on mobile/tablet)
              GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: kpiCrossAxisCount,
                  crossAxisSpacing: Gap.sm,
                  mainAxisSpacing: Gap.sm,
                  mainAxisExtent: 144,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  BmbKpiTile(
                    label: 'Expenses this month',
                    value: Paise(totalExpenseMtd).inr0,
                    hint: '${mtdExpenses.length} entries',
                    icon: const Icon(Icons.currency_rupee),
                    iconBg: AppColors.chilliSoft,
                    iconFg: AppColors.chilli,
                  ),
                  BmbKpiTile(
                    label: 'Purchases this month',
                    value: Paise(purMtd).inr0,
                    hint: 'raw materials',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    iconBg: AppColors.amberSoft,
                    iconFg: AppColors.amber,
                  ),
                  BmbKpiTile(
                    label: 'Sales this month',
                    value: Paise(salesMtd).inr0,
                    hint: 'settled bills',
                    icon: const Icon(Icons.trending_up),
                    iconBg: AppColors.leafSoft,
                    iconFg: AppColors.leaf,
                  ),
                  BmbKpiTile(
                    label: 'Rough operating margin',
                    value: roughMargin != null ? '$roughMargin%' : '—',
                    hint: 'sales − purchases − expenses',
                    icon: const Icon(Icons.pie_chart_outline),
                    iconBg: AppColors.blueSoft,
                    iconFg: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: Gap.lg),

              // Breakdown & Margin Note Grid
              if (constraints.maxWidth < 850) ...[
                _buildCategoryBreakdownCard(byCat, maxCatValue),
                const SizedBox(height: Gap.md),
                _buildMarginNoteCard(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildCategoryBreakdownCard(byCat, maxCatValue),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(flex: 5, child: _buildMarginNoteCard()),
                  ],
                ),
              ],
              const SizedBox(height: Gap.xl),

              // Search & Filter controls
              _buildFilterRow(isSmallMobile),
              const SizedBox(height: Gap.md),

              // Expense List / Table
              if (filteredExpenses.isEmpty)
                const BmbCard(
                  child: Padding(
                    padding: EdgeInsets.all(Gap.xxl),
                    child: BmbEmptyState(
                      icon: Icon(
                        Icons.receipt_long_outlined,
                        size: 28,
                        color: AppColors.muted,
                      ),
                      title: 'No expenses logged yet',
                      description:
                          'Click "+ Log expense" to record operational costs for this outlet.',
                    ),
                  ),
                )
              else if (isSmallMobile)
                _buildMobileCardList(filteredExpenses)
              else
                _buildDesktopTable(filteredExpenses),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdownCard(Map<String, int> byCat, int maxCatValue) {
    final sortedCats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BmbCard(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This month by category', style: AppText.h3),
            const SizedBox(height: Gap.md),
            if (sortedCats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(Gap.lg),
                child: Center(
                  child: Text(
                    'No expenses logged this month',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              ...sortedCats.map((entry) {
                final ratio = entry.value / maxCatValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              entry.key,
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Paise(entry.value).inr0,
                              style: AppText.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.line,
                          valueColor: const AlwaysStoppedAnimation<Color>(
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
    );
  }

  Widget _buildMarginNoteCard() {
    return BmbCard(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.tandoor,
                ),
                const SizedBox(width: Gap.sm),
                Text('Margin note', style: AppText.h3),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'This is a cash-basis view: settled sales minus purchases and logged expenses in the same month. '
              'It is not an accounting P&L — purchase timing and stock held will distort any single month. '
              'Use it as a directional check, not a statement.',
              style: AppText.bodyMedium.copyWith(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool isSmallMobile) {
    if (isSmallMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gap.sm),
          DropdownButtonFormField<String?>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All categories'),
              ),
              ...kExpenseCategories.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search description, payee, mode...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: Gap.md),
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Filter by category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Gap.md,
                vertical: Gap.sm,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All categories'),
              ),
              ...kExpenseCategories.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<Expense> expenses) {
    return BmbCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.paper),
            columnSpacing: Gap.lg,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Paid to')),
              DataColumn(label: Text('Mode')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('')),
            ],
            rows: expenses.map((e) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      e.date,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(BmbTag.grey(e.cat)),
                  DataCell(Text(e.desc)),
                  DataCell(Text(e.payee.isNotEmpty ? e.payee : '—')),
                  DataCell(Text(e.mode)),
                  DataCell(
                    Text(
                      e.amt.inr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.chilli,
                      ),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(e.id),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<Expense> expenses) {
    return Column(
      children: expenses.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Gap.sm),
          child: BmbCard(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e.date,
                        style: AppText.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.xs),
                    BmbTag.grey(e.cat),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  e.desc,
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: 4,
                  children: [
                    if (e.payee.isNotEmpty)
                      Text('Paid to: ${e.payee}', style: AppText.caption),
                    Text('Mode: ${e.mode}', style: AppText.caption),
                  ],
                ),
                const Divider(height: Gap.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e.amt.inr,
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.chilli,
                      ),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDelete(e.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmDelete(String expenseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to remove this expense entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.chilli),
            onPressed: () {
              ref.read(bmbStateProvider.notifier).deleteExpense(expenseId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final catController = ValueNotifier<String>(kExpenseCategories.first);
    final modeController = ValueNotifier<String>(kPaymentModes.first);
    final amtController = TextEditingController();
    final descController = TextEditingController();
    final payeeController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );

    showBmbModal(
      context: context,
      title: 'Log Expense',
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: catController,
                  builder: (context, cat, _) => DropdownButtonFormField<String>(
                    initialValue: cat,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: kExpenseCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) catController.value = val;
                    },
                  ),
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: TextField(
                  controller: amtController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'e.g. July shop rent',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: payeeController,
                  decoration: const InputDecoration(
                    labelText: 'Paid to',
                    hintText: 'Person or firm name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: modeController,
                  builder: (context, mode, _) =>
                      DropdownButtonFormField<String>(
                        initialValue: mode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment mode',
                          border: OutlineInputBorder(),
                        ),
                        items: kPaymentModes
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) modeController.value = val;
                        },
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: 'Date (YYYY-MM-DD)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    dateController.text = picked.toIso8601String().substring(
                      0,
                      10,
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              Expanded(
                child: BmbButton.outline(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              AppSpacing.gapWSm,
              Expanded(
                child: BmbButton.primary(
                  label: 'Save expense',
                  onPressed: () {
                    final amt =
                        double.tryParse(amtController.text.trim()) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }
                    final desc = descController.text.trim();
                    if (desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Description is required'),
                        ),
                      );
                      return;
                    }

                    final state = ref.read(bmbStateProvider);
                    final newExpense = Expense(
                      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                      date: dateController.text.trim().isNotEmpty
                          ? dateController.text.trim()
                          : DateTime.now().toIso8601String().substring(0, 10),
                      cat: catController.value,
                      desc: desc,
                      payee: payeeController.text.trim(),
                      mode: modeController.value,
                      amt: Paise.fromRupees(amt),
                      by: state.currentUserId,
                      outlet: state.activeOutletId,
                    );

                    ref.read(bmbStateProvider.notifier).saveExpense(newExpense);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense logged')),
                    );
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
