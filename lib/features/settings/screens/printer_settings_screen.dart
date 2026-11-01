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
import '../../../models/printer.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../menu/controllers/menu_category_controller.dart';
import '../controllers/active_outlet_provider.dart';
import '../controllers/printer_controller.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isStaff = user?.role.toLowerCase() == 'staff';
    final activeOutlet = ref.watch(activeOutletProvider);
    final printerState = ref.watch(printerControllerProvider);
    final notifier = ref.read(printerControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, activeOutlet, isStaff, notifier, printerState),
            // Hardware Gap Notice Banner
            _buildGapNoticeBanner(),
            // Main Body with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.loadPrinters(outletId: activeOutlet?.id),
                child: printerState.isLoading
                    ? _buildSkeletonList()
                    : printerState.errorMessage != null && printerState.activePrinters.isEmpty
                        ? _buildErrorView(printerState.errorMessage!, notifier, activeOutlet?.id)
                        : _buildPrinterList(context, printerState, isStaff, notifier, activeOutlet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    dynamic activeOutlet,
    bool isStaff,
    PrinterController notifier,
    PrinterState printerState,
  ) {
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
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(AppRadii.icon),
                    ),
                    child: const Icon(Icons.print, color: AppColors.blue, size: 20),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Settings (27)',
                          style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          activeOutlet != null
                              ? '${activeOutlet.name} (${activeOutlet.code})'
                              : 'Hardware & Station Routing (#129-#136)',
                          style: AppText.caption.copyWith(color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isStaff && isWide) ...[
                    AppSpacing.gapWMd,
                    BmbPrimaryButton(
                      label: 'Add Printer',
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      onPressed: () => _showAddEditBottomSheet(context, null, activeOutlet),
                    ),
                  ],
                ],
              ),
              if (!isStaff && !isWide) ...[
                AppSpacing.gapHSm,
                BmbPrimaryButton(
                  label: 'Add Printer',
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  onPressed: () => _showAddEditBottomSheet(context, null, activeOutlet),
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
                        printerState.showInactive
                            ? 'Hide Inactive (${printerState.inactivePrinters.length})'
                            : 'Show Inactive (${printerState.inactivePrinters.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: printerState.showInactive ? AppColors.tandoor : AppColors.ink,
                        ),
                      ),
                      selected: printerState.showInactive,
                      selectedColor: AppColors.tandoorSoft,
                      backgroundColor: AppColors.inputFill,
                      side: BorderSide(
                        color: printerState.showInactive ? AppColors.tandoor : AppColors.line,
                      ),
                      onSelected: (_) => notifier.toggleShowInactive(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                      onPressed: () => notifier.loadPrinters(outletId: activeOutlet?.id),
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

  Widget _buildGapNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.amberSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hardware Note: Backend API (#129-#136) handles printer routing configuration only. No test-print or print dispatch endpoint is defined.',
              style: AppText.caption.copyWith(color: AppColors.ink, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
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
            Container(width: 180, height: 18, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(width: 220, height: 14, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 60, height: 24, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Container(width: 60, height: 24, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error, PrinterController notifier, String? outletId) {
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
                Text('Failed to load printers', style: AppText.h3),
                const SizedBox(height: 6),
                Text(
                  error,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => notifier.loadPrinters(outletId: outletId),
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

  Widget _buildPrinterList(
    BuildContext context,
    PrinterState state,
    bool isStaff,
    PrinterController notifier,
    dynamic activeOutlet,
  ) {
    final activePrinters = state.activePrinters;
    final inactivePrinters = state.inactivePrinters;

    if (activePrinters.isEmpty && (!state.showInactive || inactivePrinters.isEmpty)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: BmbEmptyState(
              title: 'No Printers Configured',
              description: isStaff
                  ? 'No printers have been configured for this outlet.'
                  : 'Add thermal printers to route customer bills and kitchen KOT tickets.',
              icon: const Icon(Icons.print_outlined, size: 48, color: AppColors.muted),
              actionLabel: isStaff ? null : 'Add Printer',
              onAction: isStaff
                  ? null
                  : () => _showAddEditBottomSheet(context, null, activeOutlet),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (state.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.tandoorSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.tandoor),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.tandoor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.tandoor),
                  ),
                ),
              ],
            ),
          ),

        // Active Section Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('Active Printers (${activePrinters.length})', style: AppText.bodyStrong),
            if (activeOutlet != null)
              Text(
                'Outlet: ${activeOutlet.name}',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (activePrinters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No active printers for this outlet.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
          )
        else
          ...activePrinters.map((p) => _buildPrinterCard(context, p, isStaff, false, notifier, activeOutlet)),

        // Inactive Section (if showInactive is toggled on)
        if (state.showInactive) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.archive_outlined, size: 18, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Inactive Printers (${inactivePrinters.length})',
                  style: AppText.bodyStrong.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (inactivePrinters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('No inactive printers.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            )
          else
            ...inactivePrinters.map((p) => _buildPrinterCard(context, p, isStaff, true, notifier, activeOutlet)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPrinterCard(
    BuildContext context,
    Printer printer,
    bool isStaff,
    bool isInactive,
    PrinterController notifier,
    dynamic activeOutlet,
  ) {
    final isBill = printer.isBill;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BmbCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isInactive
                        ? AppColors.badgeGrey
                        : (isBill ? AppColors.leafSoft : AppColors.amberSoft),
                    borderRadius: BorderRadius.circular(AppRadii.icon),
                  ),
                  child: Icon(
                    isBill ? Icons.receipt_long : Icons.soup_kitchen,
                    color: isInactive
                        ? AppColors.muted
                        : (isBill ? AppColors.leaf : AppColors.amber),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              printer.name,
                              style: AppText.bodyStrong.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isInactive ? AppColors.muted : AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isInactive)
                            const BmbTag(label: 'Inactive', variant: BmbTagVariant.grey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${printer.printerModel ?? 'Standard Thermal'} · ${printer.conn ?? 'USB'}',
                        style: AppText.caption.copyWith(color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Chips Row: Type, Size, Copies
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                BmbTag(
                  label: printer.type,
                  variant: isBill ? BmbTagVariant.green : BmbTagVariant.amber,
                ),
                BmbTag(label: printer.size, variant: BmbTagVariant.grey),
                BmbTag(
                  label: '${printer.copies} ${printer.copies == 1 ? 'copy' : 'copies'}',
                  variant: BmbTagVariant.grey,
                ),
                if (printer.outletName != null && printer.outletName!.isNotEmpty)
                  BmbTag(label: printer.outletName!, variant: BmbTagVariant.blue),
              ],
            ),

            // Categories chips (if any)
            if (printer.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final cat in printer.categories)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        cat,
                        style: const TextStyle(fontSize: 10, color: AppColors.ink),
                      ),
                    ),
                ],
              ),
            ],

            // Action Buttons for Non-Staff
            if (!isStaff) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (!isInactive) ...[
                    // Edit Button (#133)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showAddEditBottomSheet(context, printer, activeOutlet),
                    ),
                    // Deactivate Button (#134)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.archive_outlined, size: 15),
                      label: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                      onPressed: () => _confirmDeactivate(context, printer, notifier),
                    ),
                  ] else ...[
                    // Restore Button (#135)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.leaf,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.unarchive_outlined, size: 15),
                      label: const Text('Restore', style: TextStyle(fontSize: 12)),
                      onPressed: () => notifier.restorePrinter(printer.id),
                    ),
                    // Delete Permanently Button (#136)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.tandoor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.delete_forever_outlined, size: 15),
                      label: const Text('Delete permanently', style: TextStyle(fontSize: 12)),
                      onPressed: () => _confirmPermanentDelete(context, printer, notifier),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(
    BuildContext context,
    Printer printer,
    PrinterController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Printer'),
        content: Text('Deactivate "${printer.name}"? It will move to Inactive and stop routing print tickets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deactivatePrinter(printer.id);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    Printer printer,
    PrinterController notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Printer Permanently?'),
        content: Text('Are you sure you want to delete "${printer.name}"? This action cannot be undone (#136).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tandoor),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deletePrinter(printer.id);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showAddEditBottomSheet(
    BuildContext context,
    Printer? existing,
    dynamic activeOutlet,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditPrinterSheet(
        existing: existing,
        activeOutlet: activeOutlet,
      ),
    );
  }
}

class _AddEditPrinterSheet extends ConsumerStatefulWidget {
  final Printer? existing;
  final dynamic activeOutlet;

  const _AddEditPrinterSheet({
    this.existing,
    required this.activeOutlet,
  });

  @override
  ConsumerState<_AddEditPrinterSheet> createState() => _AddEditPrinterSheetState();
}

class _AddEditPrinterSheetState extends ConsumerState<_AddEditPrinterSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _modelController;
  late TextEditingController _connController;
  late String _selectedType;
  late String _selectedSize;
  late int _copies;
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _modelController = TextEditingController(text: p?.printerModel ?? '');
    _connController = TextEditingController(text: p?.conn ?? 'USB');
    _selectedType = p?.type ?? 'KOT';
    _selectedSize = p?.size ?? '80mm';
    _copies = p?.copies ?? 1;
    _selectedCategories = List<String>.from(p?.categories ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _connController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoryDropdownProvider);
    final isSaving = ref.watch(printerControllerProvider).isSaving;
    final outlet = widget.activeOutlet;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Default category list if menu categories not yet loaded
    final availableCategories = categoriesAsync.value?.map((c) => c.name).toList() ??
        ['Starters', 'Main Course', 'Rice & Noodles', 'Breads', 'Beverages', 'Desserts', 'Snacks'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existing == null ? 'Add Printer' : 'Edit Printer',
                    style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Outlet Field (Read-only from active outlet)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, size: 18, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Outlet', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                          Text(
                            outlet != null ? '${outlet.name} (${outlet.code})' : 'No Outlet Selected',
                            style: AppText.bodyStrong.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Name Field (Required)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  hintText: 'e.g. Counter Bill Printer, Hot Kitchen KOT',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.print_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Printer name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type Selector: Bill vs KOT
              const Text('Printer Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'KOT', label: Text('KOT (Kitchen)')),
                  ButtonSegment(value: 'Bill', label: Text('Bill (Receipt)')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) {
                  setState(() => _selectedType = val.first);
                },
              ),
              const SizedBox(height: 16),

              // Model Field (Optional)
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Printer Model (optional)',
                  hintText: 'e.g. Epson TM-T82, TVS RP 3200',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices_other),
                ),
              ),
              const SizedBox(height: 16),

              // Connection Field (Hint "USB" or "LAN 192.168.1.44")
              TextFormField(
                controller: _connController,
                decoration: const InputDecoration(
                  labelText: 'Connection',
                  hintText: 'USB or LAN 192.168.1.44',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cable),
                ),
              ),
              const SizedBox(height: 16),

              // Paper Size: 80mm vs 58mm
              const Text('Paper Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '80mm', label: Text('80mm (Standard)')),
                  ButtonSegment(value: '58mm', label: Text('58mm (Compact)')),
                ],
                selected: {_selectedSize},
                onSelectionChanged: (val) {
                  setState(() => _selectedSize = val.first);
                },
              ),
              const SizedBox(height: 16),

              // Copies: 1 to 4
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Print Copies (1-4)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 4, label: Text('4')),
                    ],
                    selected: {_copies},
                    onSelectionChanged: (val) {
                      setState(() => _copies = val.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories multi-select from menu category provider
              const Text('Assigned Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Orders containing these categories will route tickets to this printer station.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: availableCategories.map((catName) {
                  final isSelected = _selectedCategories.contains(catName);
                  return FilterChip(
                    label: Text(catName, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.tandoor : AppColors.ink)),
                    selected: isSelected,
                    selectedColor: AppColors.tandoorSoft,
                    backgroundColor: AppColors.inputFill,
                    side: BorderSide(color: isSelected ? AppColors.tandoor : AppColors.line),
                    onSelected: (checked) {
                      setState(() {
                        if (checked) {
                          _selectedCategories.add(catName);
                        } else {
                          _selectedCategories.remove(catName);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.tandoor),
                      onPressed: isSaving ? null : _saveForm,
                      child: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.existing == null ? 'Create Printer' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final outlet = widget.activeOutlet;
    final outletId = widget.existing?.outletId.isNotEmpty == true
        ? widget.existing!.outletId
        : (outlet?.id ?? '');

    if (outletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active outlet first.')),
      );
      return;
    }

    final notifier = ref.read(printerControllerProvider.notifier);
    bool success;

    if (widget.existing == null) {
      // #129 POST
      success = await notifier.createPrinter(
        outletId: outletId,
        name: _nameController.text.trim(),
        type: _selectedType,
        printerModel: _modelController.text.trim(),
        conn: _connController.text.trim(),
        size: _selectedSize,
        copies: _copies,
        categories: _selectedCategories,
      );
    } else {
      // #133 PATCH
      success = await notifier.updatePrinter(
        printerId: widget.existing!.id,
        outletId: outletId,
        name: _nameController.text.trim(),
        type: _selectedType,
        printerModel: _modelController.text.trim(),
        conn: _connController.text.trim(),
        size: _selectedSize,
        copies: _copies,
        categories: _selectedCategories,
      );
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing == null ? 'Printer created successfully' : 'Printer updated'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }
}
