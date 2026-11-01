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
import '../../menu/controllers/menu_item_controller.dart';
import '../controllers/recipe_cost_controller.dart';
import '../providers/inventory_providers.dart';

/// Module 10 — Recipe Cost Management Screen
/// Endpoints #79 to #86
class RecipeManagementScreen extends ConsumerStatefulWidget {
  const RecipeManagementScreen({super.key});

  @override
  ConsumerState<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends ConsumerState<RecipeManagementScreen> {
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(menuItemControllerProvider.notifier).fetchActive();
      ref.read(activeInventoryProvider.notifier).refresh();
      ref.read(activeRecipeCostProvider.notifier).refresh();
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

  String _resolveMenuItemName(RecipeCost rc, List<MenuItem> menuItems) {
    if (rc.menuItemName.isNotEmpty) return rc.menuItemName;
    final match = menuItems.where((m) => m.id == rc.menuItemId).firstOrNull;
    if (match != null && match.name.isNotEmpty) return match.name;
    return rc.menuItemId.isNotEmpty ? rc.menuItemId : 'Unknown Item';
  }

  String _resolveMaterialName(RecipeCostIngredient ing, List<InventoryItem> invItems) {
    if (ing.inventoryMaterial.isNotEmpty) return ing.inventoryMaterial;
    final match = invItems.where((i) => i.id == ing.inventoryId).firstOrNull;
    if (match != null && match.material.isNotEmpty) return match.material;
    return ing.inventoryId.isNotEmpty ? ing.inventoryId : 'Unknown Material';
  }

  static Widget _buildMarginTag(double grossMargin) {
    final label = '${grossMargin.toStringAsFixed(1)}%';
    if (grossMargin >= 60) {
      return BmbTag.green(label);
    } else if (grossMargin >= 40) {
      return BmbTag.amber(label);
    } else {
      return BmbTag.red(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final canWrite = _canWrite(user?.role);
    final canHardDelete = _canHardDelete(user?.role);
    final isStaff = !canWrite;

    final activeAsync = ref.watch(activeRecipeCostProvider);
    final inactiveAsync = ref.watch(inactiveRecipeCostProvider);
    final recipesAsync = _showInactive ? inactiveAsync : activeAsync;

    final menuItemsAsync = ref.watch(menuItemControllerProvider);
    final menuItems = menuItemsAsync.value ?? [];

    final inventoryAsync = ref.watch(activeInventoryProvider);
    final inventoryItems = inventoryAsync.value ?? [];

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Recipes & Food Cost',
            subtitle: 'Link ingredients to menu items — food cost and profit margins calculated live',
            icon: Icons.restaurant_menu_outlined,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: isStaff
                ? null
                : BmbButton.primary(
                    label: 'New Recipe',
                    size: BmbButtonSize.sm,
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _openRecipeForm(context, null, menuItems, inventoryItems),
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: recipesAsync.when(
                data: (recipes) {
                  // Filter by search query (menu item name or recipeCostNo)
                  final q = _searchQuery.trim().toLowerCase();
                  final filtered = recipes.where((rc) {
                    if (q.isEmpty) return true;
                    final mName = _resolveMenuItemName(rc, menuItems).toLowerCase();
                    final rcNo = rc.recipeCostNo.toLowerCase();
                    return mName.contains(q) || rcNo.contains(q);
                  }).toList();

                  // Sort newest / highest costNo first
                  filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI summary cards & search bar
                      _buildFiltersAndKpis(context, recipes, menuItems),
                      AppSpacing.gapHLg,

                      // Recipes listing
                      if (recipes.isEmpty && !_showInactive)
                        const BmbEmptyState(
                          title: 'No recipes yet',
                          description: 'Add a recipe to see food cost',
                        )
                      else if (filtered.isEmpty)
                        const BmbEmptyState(
                          title: 'No matching recipes found',
                          description: 'Try adjusting your search criteria.',
                        )
                      else if (!isStaff)
                        BmbCard(
                          child: SizedBox(
                            height: 600,
                            child: LifecycleListView<RecipeCost>(
                              title: 'Recipes',
                              items: filtered.map((rc) {
                                final mName = _resolveMenuItemName(rc, menuItems);
                                return LifecycleItem(
                                  data: rc,
                                  title: '${rc.recipeCostNo.isNotEmpty ? "${rc.recipeCostNo} — " : ""}$mName',
                                  subtitle:
                                      '${rc.ingredients.length} ingredients | Cost: ₹${rc.totalPrice.toStringAsFixed(2)} | Sell: ₹${rc.sellingPrice.toStringAsFixed(2)} | Margin: ${rc.grossMargin.toStringAsFixed(1)}%',
                                  isActive: rc.isActive,
                                );
                              }).toList(),
                              showInactive: _showInactive,
                              onToggleView: () => setState(() => _showInactive = !_showInactive),
                              onCreate: () => _openRecipeForm(context, null, menuItems, inventoryItems),
                              onEdit: (rc) => _openRecipeDetailOrEdit(context, rc, menuItems, inventoryItems, canWrite),
                              onDeactivate: _deactivateRecipe,
                              onRestore: _restoreRecipe,
                              onHardDelete: _hardDeleteRecipe,
                              canHardDelete: canHardDelete,
                            ),
                          ),
                        )
                      else
                        _buildStaffView(context, filtered, menuItems, inventoryItems),
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
                        Text('Error loading recipe costs: $e', style: AppText.body),
                        const SizedBox(height: Gap.md),
                        BmbButton.outline(
                          label: 'Retry',
                          onPressed: () {
                            ref.read(activeRecipeCostProvider.notifier).refresh();
                            ref.read(inactiveRecipeCostProvider.notifier).refresh();
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

  Widget _buildFiltersAndKpis(
    BuildContext context,
    List<RecipeCost> recipes,
    List<MenuItem> menuItems,
  ) {
    int totalDefined = recipes.length;
    double avgMargin = 0;
    double avgCost = 0;

    if (totalDefined > 0) {
      double sumMargin = 0;
      double sumCost = 0;
      for (final r in recipes) {
        sumMargin += r.grossMargin;
        sumCost += r.totalPrice;
      }
      avgMargin = sumMargin / totalDefined;
      avgCost = sumCost / totalDefined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            BmbKpiTile(
              label: 'Recipes Defined',
              value: '$totalDefined',
              hint: menuItems.isNotEmpty ? 'of ${menuItems.length} menu items' : null,
              icon: const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.tandoor),
              iconBg: AppColors.tandoorSoft,
              iconFg: AppColors.tandoor,
            ),
            BmbKpiTile(
              label: 'Avg Gross Margin',
              value: '${avgMargin.toStringAsFixed(1)}%',
              icon: const Icon(Icons.trending_up, size: 20, color: AppColors.leaf),
              iconBg: AppColors.leafSoft,
              iconFg: AppColors.leaf,
            ),
            BmbKpiTile(
              label: 'Avg Cost / Portion',
              value: '₹${avgCost.toStringAsFixed(2)}',
              icon: const Icon(Icons.currency_rupee, size: 20, color: AppColors.amber),
              iconBg: AppColors.amberSoft,
              iconFg: AppColors.amber,
            ),
          ],
        ),
        AppSpacing.gapHLg,
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by menu item or recipe code (e.g. RC-001)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffView(
    BuildContext context,
    List<RecipeCost> filtered,
    List<MenuItem> menuItems,
    List<InventoryItem> inventoryItems,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final rc = filtered[index];
        final mName = _resolveMenuItemName(rc, menuItems);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs),
          title: Text(
            '${rc.recipeCostNo.isNotEmpty ? "${rc.recipeCostNo} — " : ""}$mName',
            style: AppText.bodyStrong,
          ),
          subtitle: Text(
            '${rc.ingredients.length} ingredients | Cost: ₹${rc.totalPrice.toStringAsFixed(2)} | Sell: ₹${rc.sellingPrice.toStringAsFixed(2)} | Margin: ${rc.grossMargin.toStringAsFixed(1)}%',
            style: AppText.caption,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _openRecipeDetailModal(context, rc, menuItems, inventoryItems, false),
        );
      },
    );
  }

  void _openRecipeDetailOrEdit(
    BuildContext context,
    RecipeCost rc,
    List<MenuItem> menuItems,
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
                      rc.recipeCostNo.isNotEmpty ? rc.recipeCostNo : 'Recipe Details',
                      style: AppText.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                Text(
                  _resolveMenuItemName(rc, menuItems),
                  style: AppText.bodyStrong.copyWith(color: AppColors.tandoor),
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: BmbButton.outline(
                        label: 'View Ingredients (#82)',
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openRecipeDetailModal(context, rc, menuItems, inventoryItems, canWrite);
                        },
                      ),
                    ),
                    if (canWrite) ...[
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: BmbButton.primary(
                          label: 'Edit Recipe (#83)',
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _openRecipeForm(context, rc, menuItems, inventoryItems);
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

  void _openRecipeDetailModal(
    BuildContext context,
    RecipeCost rc,
    List<MenuItem> menuItems,
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
        final mName = _resolveMenuItemName(rc, menuItems);

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
                          Text(rc.recipeCostNo.isNotEmpty ? rc.recipeCostNo : 'Recipe Details', style: AppText.h3),
                          Text(mName, style: AppText.bodyStrong.copyWith(color: AppColors.tandoor)),
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
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Selling Price', style: AppText.caption),
                            const SizedBox(height: 4),
                            Text('₹${rc.sellingPrice.toStringAsFixed(2)}', style: AppText.bodyStrong),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Total Cost', style: AppText.caption),
                            const SizedBox(height: 4),
                            Text('₹${rc.totalPrice.toStringAsFixed(2)}', style: AppText.bodyStrong),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Gross Margin', style: AppText.caption),
                            const SizedBox(height: 4),
                            _buildMarginTag(rc.grossMargin),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text('Ingredients (${rc.ingredients.length})', style: AppText.bodyStrong),
                  const Divider(),
                  if (rc.ingredients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      child: Text('No ingredients configured.', style: AppText.caption),
                    )
                  else
                    ...rc.ingredients.map((ing) {
                      final matName = _resolveMaterialName(ing, inventoryItems);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(matName, style: AppText.bodyStrong),
                        subtitle: Text(
                          'Portion: ${ing.unitValue} ${ing.unit} @ ₹${ing.rate.toStringAsFixed(2)} / ${ing.unit}',
                          style: AppText.caption,
                        ),
                        trailing: Text(
                          '₹${ing.lineCost.toStringAsFixed(2)}',
                          style: AppText.bodyStrong,
                        ),
                      );
                    }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Food Cost', style: AppText.bodyStrong),
                      Text('₹${rc.totalPrice.toStringAsFixed(2)}', style: AppText.h3.copyWith(color: AppColors.tandoor)),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    'Costs use the rate saved with this recipe. Edit and save to refresh.',
                    style: AppText.caption.copyWith(color: AppColors.muted, fontStyle: FontStyle.italic),
                  ),
                  if (rc.createdAt != null) ...[
                    const SizedBox(height: Gap.sm),
                    Text(
                      'Created: ${rc.createdAt?.toLocal().toString().split('.')[0] ?? ''}',
                      style: AppText.caption,
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

  void _openRecipeForm(
    BuildContext context,
    RecipeCost? existing,
    List<MenuItem> menuItems,
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
        return _RecipeCostForm(
          existing: existing,
          menuItems: menuItems,
          inventoryItems: inventoryItems,
        );
      },
    );
  }

  Future<void> _deactivateRecipe(RecipeCost rc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Recipe'),
        content: Text('Are you sure you want to deactivate recipe "${rc.recipeCostNo}"?'),
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

    final err = await ref.read(activeRecipeCostProvider.notifier).deactivateRecipeCost(rc.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe cost deleted successfully'), backgroundColor: AppColors.leaf),
      );
    }
  }

  Future<void> _restoreRecipe(RecipeCost rc) async {
    final err = await ref.read(inactiveRecipeCostProvider.notifier).restoreRecipeCost(rc.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe cost restored successfully'), backgroundColor: AppColors.leaf),
      );
    }
  }

  Future<void> _hardDeleteRecipe(RecipeCost rc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Recipe'),
        content: Text(
          'Are you sure you want to PERMANENTLY delete recipe "${rc.recipeCostNo}"? This action cannot be undone.',
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

    final err = await ref.read(inactiveRecipeCostProvider.notifier).hardDeleteRecipeCost(rc.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.chilli));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe cost permanently deleted'), backgroundColor: AppColors.leaf),
      );
    }
  }
}

/// Create (#80) & Edit (#83) Recipe Cost Form
class _RecipeCostForm extends ConsumerStatefulWidget {
  final RecipeCost? existing;
  final List<MenuItem> menuItems;
  final List<InventoryItem> inventoryItems;

  const _RecipeCostForm({
    this.existing,
    required this.menuItems,
    required this.inventoryItems,
  });

  @override
  ConsumerState<_RecipeCostForm> createState() => _RecipeCostFormState();
}

class _RecipeCostFormState extends ConsumerState<_RecipeCostForm> {
  String? _selectedMenuItemId;
  final TextEditingController _sellingPriceController = TextEditingController();
  final List<_IngredientRowData> _ingredientRows = [];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final ex = widget.existing!;
      _selectedMenuItemId = ex.menuItemId;
      _sellingPriceController.text = ex.sellingPrice.toStringAsFixed(2);
      for (final ing in ex.ingredients) {
        _ingredientRows.add(_IngredientRowData(
          inventoryId: ing.inventoryId,
          unit: ing.unit,
          rate: ing.rate,
          unitValue: ing.unitValue,
        ));
      }
    } else {
      _addLine();
    }
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _ingredientRows.add(_IngredientRowData(
        inventoryId: null,
        unit: '',
        rate: 0.0,
        unitValue: 1.0,
      ));
    });
  }

  void _removeLine(int index) {
    setState(() {
      final removed = _ingredientRows.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalPrice {
    double t = 0;
    for (final r in _ingredientRows) {
      if (r.inventoryId != null && r.unitValue > 0) {
        t += r.rate * r.unitValue;
      }
    }
    return t;
  }

  double get _sellingPrice {
    return double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
  }

  double get _grossMargin {
    final sp = _sellingPrice;
    final tp = _totalPrice;
    if (sp <= 0) return 0.0;
    return ((sp - tp) / sp) * 100.0;
  }

  void _onMenuItemSelected(String? menuItemId) {
    setState(() {
      _selectedMenuItemId = menuItemId;
      if (menuItemId != null && widget.existing == null) {
        final match = widget.menuItems.where((m) => m.id == menuItemId).firstOrNull;
        if (match != null) {
          // Pre-fill sellingPrice from menu item's price
          _sellingPriceController.text = match.price.toRupees.toStringAsFixed(2);
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);

    if (_selectedMenuItemId == null || _selectedMenuItemId!.isEmpty) {
      setState(() => _errorMessage = 'Please select a menu item');
      return;
    }

    final sp = double.tryParse(_sellingPriceController.text.trim());
    if (sp == null || sp < 0) {
      setState(() => _errorMessage = 'Please enter a valid selling price (>= 0)');
      return;
    }

    final validRows = _ingredientRows.where((r) => r.inventoryId != null && r.unitValue > 0).toList();
    if (validRows.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one ingredient with portion > 0');
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.existing != null;
    String? err;

    if (!isEdit) {
      // #80 POST create
      final body = {
        'menuItemId': _selectedMenuItemId,
        'sellingPrice': sp,
        'ingredients': validRows.map((r) => {
          'inventoryId': r.inventoryId,
          'unit': r.unit,
          'rate': r.rate,
          'unitValue': r.unitValue,
        }).toList(),
      };
      err = await ref.read(activeRecipeCostProvider.notifier).createRecipeCost(body);
    } else {
      // #83 PUT update - send only changed fields or full ingredients array if ingredients changed
      final body = <String, dynamic>{
        'sellingPrice': sp,
        'ingredients': validRows.map((r) => {
          'inventoryId': r.inventoryId,
          'unit': r.unit,
          'rate': r.rate,
          'unitValue': r.unitValue,
        }).toList(),
      };
      err = await ref.read(activeRecipeCostProvider.notifier).updateRecipeCost(widget.existing!.id, body);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (err != null) {
      setState(() => _errorMessage = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Recipe cost updated successfully' : 'Recipe cost created successfully'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: Gap.lg,
        right: Gap.lg,
        top: Gap.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Recipe (${widget.existing!.recipeCostNo})' : 'New Recipe Cost',
                  style: AppText.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: Gap.md),
                padding: const EdgeInsets.all(Gap.sm),
                decoration: BoxDecoration(
                  color: AppColors.chilliSoft,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.chilli, size: 18),
                    const SizedBox(width: Gap.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppText.caption.copyWith(color: AppColors.chilli, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu Item Picker
                    Text('Menu Item *', style: AppText.bodyStrong),
                    const SizedBox(height: Gap.xs),
                    if (isEdit)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          widget.existing?.menuItemName.isNotEmpty == true
                              ? widget.existing!.menuItemName
                              : (widget.menuItems.where((m) => m.id == _selectedMenuItemId).firstOrNull?.name ??
                                  _selectedMenuItemId ??
                                  ''),
                          style: AppText.bodyStrong,
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedMenuItemId,
                        hint: const Text('Select a menu item'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                        ),
                        items: widget.menuItems.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text('${m.name} (₹${m.price.toRupees.toStringAsFixed(0)})'),
                          );
                        }).toList(),
                        onChanged: _onMenuItemSelected,
                      ),
                    const SizedBox(height: Gap.md),

                    // Selling Price Field
                    Text('Selling Price (₹) *', style: AppText.bodyStrong),
                    const SizedBox(height: Gap.xs),
                    TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
                      ),
                    ),
                    const SizedBox(height: Gap.lg),

                    // Live Cost & Margin Preview Card
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
                              Text('Total Food Cost', style: AppText.caption),
                              const SizedBox(height: 4),
                              Text('₹${_totalPrice.toStringAsFixed(2)}', style: AppText.bodyStrong),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Selling Price', style: AppText.caption),
                              const SizedBox(height: 4),
                              Text('₹${_sellingPrice.toStringAsFixed(2)}', style: AppText.bodyStrong),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Gross Margin', style: AppText.caption),
                              const SizedBox(height: 4),
                              _RecipeManagementScreenState._buildMarginTag(_grossMargin),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.lg),

                    // Ingredients List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ingredients (${_ingredientRows.length}) *', style: AppText.bodyStrong),
                        BmbButton.outline(
                          label: 'Add Ingredient',
                          size: BmbButtonSize.sm,
                          icon: const Icon(Icons.add, size: 14),
                          onPressed: _addLine,
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),

                    ..._ingredientRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: Gap.sm),
                        padding: const EdgeInsets.all(Gap.sm),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: row.inventoryId,
                                    isExpanded: true,
                                    hint: const Text('Raw Material'),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                                    ),
                                    items: widget.inventoryItems.map((inv) {
                                      return DropdownMenuItem<String>(
                                        value: inv.id,
                                        child: Text(
                                          '${inv.material} (${inv.unit ?? ""})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        row.inventoryId = val;
                                        final match = widget.inventoryItems.where((i) => i.id == val).firstOrNull;
                                        if (match != null) {
                                          row.unit = match.unit ?? '';
                                          row.rate = match.rate;
                                          row.rateController.text = match.rate.toStringAsFixed(2);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_ingredientRows.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.chilli, size: 20),
                                    onPressed: () => _removeLine(idx),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Unit (Read-only as required)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      borderRadius: BorderRadius.circular(AppRadii.input),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Text(
                                      row.unit.isNotEmpty ? 'Unit: ${row.unit}' : 'Unit: —',
                                      style: AppText.caption,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Portion / unitValue
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: row.portionController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Portion',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        row.unitValue = double.tryParse(val.trim()) ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Rate (prefilled, editable)
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: row.rateController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Rate (₹)',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        row.rate = double.tryParse(val.trim()) ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Line total
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${(row.rate * row.unitValue).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: AppText.bodyStrong,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BmbButton.outline(
                  label: 'Cancel',
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                ),
                const SizedBox(width: Gap.sm),
                BmbButton.primary(
                  label: isEdit ? 'Save Changes' : 'Create Recipe',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRowData {
  String? inventoryId;
  String unit;
  double rate;
  double unitValue;
  final TextEditingController rateController;
  final TextEditingController portionController;

  _IngredientRowData({
    required this.inventoryId,
    required this.unit,
    required this.rate,
    required this.unitValue,
  })  : rateController = TextEditingController(text: rate > 0 ? rate.toStringAsFixed(2) : ''),
        portionController = TextEditingController(text: unitValue > 0 ? unitValue.toString() : '1');

  void dispose() {
    rateController.dispose();
    portionController.dispose();
  }
}
