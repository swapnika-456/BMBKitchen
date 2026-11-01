import 'dart:io' as java_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
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
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/bmb_text_field.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../core/widgets/food_type_dot.dart';
import '../../../core/widgets/bmb_confirm_dialog.dart';
import '../../../mock/mock_state.dart';
import '../../../models/models.dart';
import '../../../models/menu_category.dart';
import '../controllers/menu_category_controller.dart';
import '../controllers/menu_item_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/api/menu_category_api_service.dart';
import '../../../services/api/menu_item_api_service.dart';
import '../../supply_chain/controllers/recipe_cost_controller.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  bool _showInactive = false;

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bmbState = ref.watch(bmbStateProvider);
    final roleName = bmbState.currentUserRole.name.toLowerCase();
    final canManageItems = ['owner', 'admin', 'cto'].contains(roleName);
    final canManageCategories = [
      'owner',
      'admin',
      'cto',
      'staff',
    ].contains(roleName);

    final futureCategories = _showInactive
        ? ref.read(menuCategoryControllerProvider.notifier).fetchInactive()
        : ref.read(menuCategoryControllerProvider.notifier).fetchActive();

    final futureItems = _showInactive
        ? ref.read(menuItemControllerProvider.notifier).fetchInactive()
        : ref.read(menuItemControllerProvider.notifier).fetchActive();

    return Material(
      color: AppColors.paper,
      child: FutureBuilder(
        future: Future.wait([futureCategories, futureItems]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;

          final categories = snapshot.hasData
              ? (snapshot.data![0] as List<MenuCategory>)
              : <MenuCategory>[];
          final items = snapshot.hasData
              ? (snapshot.data![1] as List<MenuItem>)
              : <MenuItem>[];

          final subtitle = isLoading
              ? 'Loading...'
              : '${items.length} items across ${categories.length} categories';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalPadding(context),
                  vertical: Gap.xl,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Gap.md,
                  runSpacing: Gap.md,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.leafSoft,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                          ),
                          child: const Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.leaf,
                            size: 24,
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Menu Management', style: AppText.h2),
                            Text(subtitle, style: AppText.caption),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Show inactive'),
                          selected: _showInactive,
                          onSelected: (val) {
                            setState(() => _showInactive = val);
                          },
                          backgroundColor: AppColors.card,
                          selectedColor: AppColors.tandoorSoft,
                          checkmarkColor: AppColors.tandoor,
                          labelStyle: TextStyle(
                            color: _showInactive
                                ? AppColors.tandoor
                                : AppColors.ink,
                          ),
                        ),
                        if (canManageCategories)
                          BmbSecondaryButton(
                            label: '+ Category',
                            onPressed: () => _showCategoryModal(null),
                          ),
                        if (canManageItems)
                          BmbPrimaryButton(
                            label: '+ Menu item',
                            onPressed: () => _showEditItemModal(
                              context,
                              ref,
                              null,
                              canManageCategories,
                              categories,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: _buildBody(
                  isLoading,
                  hasError,
                  snapshot.error,
                  categories,
                  items,
                  canManageCategories,
                  canManageItems,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    bool isLoading,
    bool hasError,
    Object? error,
    List<MenuCategory> categories,
    List<MenuItem> items,
    bool canManageCategories,
    bool canManageItems,
  ) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontalPadding(context),
        ),
        child: Column(
          children: List.generate(
            3,
            (i) => const Padding(
              padding: EdgeInsets.only(bottom: Gap.lg),
              child: BmbSkeleton(width: double.infinity, height: 120),
            ),
          ),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.chilli),
            AppSpacing.gapHMd,
            Text('Failed to load menu data', style: AppText.h3),
            AppSpacing.gapHSm,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error?.toString() ?? 'Couldn\'t load categories and items.',
                style: AppText.caption.copyWith(color: AppColors.chilli),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.gapHLg,
            BmbSecondaryButton(label: 'Retry', onPressed: _refreshData),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return BmbEmptyState(
        title: 'No categories yet',
        description: 'Add your first category to start building your menu.',
        actionLabel: canManageCategories ? 'Add Category' : null,
        onAction: canManageCategories ? () => _showCategoryModal(null) : null,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: Gap.lg,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        // The API returns the id in cat.id, but items from mock_state might have used cat.name.
        // Assuming Module 5 API links MenuItem to MenuCategory using 'cat' or 'categoryId' field.
        // We will check if item.cat matches cat.id or cat.name.
        final catItems = items
            .where((i) => i.cat == cat.id || i.cat == cat.name)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cat.name.toUpperCase()} · ${catItems.length}',
                    style: AppText.label.copyWith(color: AppColors.muted),
                  ),
                  if (canManageCategories)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.muted,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showCategoryModal(cat);
                        } else if (val == 'deactivate') {
                          _deactivateCategory(cat);
                        } else if (val == 'recover') {
                          _recoverCategory(cat);
                        } else if (val == 'delete') {
                          _hardDeleteCategory(cat);
                        }
                      },
                      itemBuilder: (context) {
                        if (!_showInactive) {
                          return [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit category'),
                            ),
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Text('Deactivate category'),
                            ),
                          ];
                        } else {
                          return [
                            const PopupMenuItem(
                              value: 'recover',
                              child: Text('Recover category'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete permanently',
                                style: TextStyle(color: AppColors.chilli),
                              ),
                            ),
                          ];
                        }
                      },
                    ),
                ],
              ),
              AppSpacing.gapHSm,
              // Items Grid
              if (catItems.isEmpty)
                BmbCard(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Center(
                    child: Text(
                      'No items in this category',
                      style: AppText.caption,
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    if (constraints.maxWidth > 600) crossAxisCount = 3;
                    if (constraints.maxWidth > 900) crossAxisCount = 4;

                    final spacing = Gap.md;
                    final width =
                        (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                        crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: catItems.map((item) {
                        return SizedBox(
                          width: width,
                          child: _buildItemCard(
                            item,
                            canManageItems,
                            canManageCategories,
                            categories,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(
    MenuItem item,
    bool canManageItems,
    bool canManageCategories,
    List<MenuCategory> categories,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.line),
      ),
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image placeholder
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.inputFill,
              child: item.images.isNotEmpty
                  ? Image.network(
                      item.images.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.broken_image,
                        color: AppColors.muted,
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No images yet',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: FoodTypeDot(type: item.type),
                    ),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH4,
                Text(item.price.inr, style: AppText.body),
                AppSpacing.gapH4,
                _buildRecipeCostInfo(item.id),
                if (item.variants.isNotEmpty) ...[
                  AppSpacing.gapH4,
                  Text(
                    item.variants.map((v) => v.name).join(' / '),
                    style: AppText.caption.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.addons.isNotEmpty) ...[
                  AppSpacing.gapH4,
                  BmbTag.grey('+${item.addons.length} Add-ons'),
                ],
                AppSpacing.gapHMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: item.isActive
                            ? const BmbTag.green('Available')
                            : const BmbTag.grey('Inactive'),
                      ),
                    ),
                    if (_showInactive && canManageItems) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.restore,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        onPressed: () => _recoverItem(item),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.chilli,
                        ),
                        onPressed: () => _hardDeleteItem(item),
                      ),
                    ] else if (canManageItems)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        onPressed: () => _showEditItemModal(
                          context,
                          ref,
                          item,
                          canManageCategories,
                          categories,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCostInfo(String itemId) {
    final recipeCosts = ref.watch(recipeCostByMenuItemProvider);
    final rc = recipeCosts[itemId];
    if (rc != null) {
      Widget tag;
      final label = '${rc.grossMargin.toStringAsFixed(1)}%';
      if (rc.grossMargin >= 60) {
        tag = BmbTag.green(label);
      } else if (rc.grossMargin >= 40) {
        tag = BmbTag.amber(label);
      } else {
        tag = BmbTag.red(label);
      }
      return Wrap(
        spacing: Gap.xs,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Cost ₹${rc.totalPrice.toStringAsFixed(2)}',
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          tag,
        ],
      );
    } else {
      return const BmbTag.grey('No recipe');
    }
  }

  // --- Category Actions ---

  void _showCategoryModal(MenuCategory? category) {
    String name = category?.name ?? '';
    String desc = category?.description ?? '';
    String? error;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.horizontalPadding(ctx),
                right: AppSpacing.horizontalPadding(ctx),
                top: Gap.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category == null ? 'Add Category' : 'Edit Category',
                    style: AppText.h3,
                  ),
                  AppSpacing.gapHLg,
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Starters, Tandoor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.tandoor),
                      ),
                    ),
                    onChanged: (v) => name = v,
                  ),
                  AppSpacing.gapHMd,
                  TextFormField(
                    initialValue: desc,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.tandoor),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (v) => desc = v,
                  ),
                  if (error != null) ...[
                    AppSpacing.gapHSm,
                    Text(
                      error!,
                      style: AppText.caption.copyWith(color: AppColors.chilli),
                    ),
                  ],
                  AppSpacing.gapHLg,
                  SizedBox(
                    width: double.infinity,
                    child: BmbPrimaryButton(
                      label: isSaving
                          ? 'Saving...'
                          : (category == null ? 'Create' : 'Save'),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final trimmedName = name.trim();
                              if (trimmedName.isEmpty) {
                                setModalState(
                                  () => error = 'Name cannot be empty',
                                );
                                return;
                              }

                              setModalState(() {
                                error = null;
                                isSaving = true;
                              });

                              final notifier = ref.read(
                                menuCategoryControllerProvider.notifier,
                              );
                              String? resultError;
                              final sm = ScaffoldMessenger.of(context);
                              if (category == null) {
                                resultError = await notifier.createCategory(
                                  name: trimmedName,
                                  description: desc.trim().isEmpty
                                      ? null
                                      : desc.trim(),
                                );
                              } else {
                                resultError = await notifier.updateCategory(
                                  category.id,
                                  name: trimmedName,
                                  description: desc.trim().isEmpty
                                      ? null
                                      : desc.trim(),
                                );
                              }

                              if (mounted) {
                                setModalState(() => isSaving = false);
                                if (resultError != null) {
                                  setModalState(() => error = resultError);
                                } else {
                                  Navigator.pop(ctx);
                                  _refreshData();
                                  sm.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        category == null
                                            ? 'Category created'
                                            : 'Category updated',
                                      ),
                                      backgroundColor: AppColors.leaf,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  AppSpacing.gapHXxl,
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deactivateCategory(MenuCategory cat) async {
    final notifier = ref.read(menuCategoryControllerProvider.notifier);
    final err = await notifier.deactivateCategory(cat.id);
    if (err != null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
        );
    } else {
      _refreshData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deactivated'),
            backgroundColor: AppColors.leaf,
          ),
        );
    }
  }

  void _recoverCategory(MenuCategory cat) async {
    final notifier = ref.read(menuCategoryControllerProvider.notifier);
    final err = await notifier.recoverCategory(cat.id);
    if (err != null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
        );
    } else {
      _refreshData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category recovered'),
            backgroundColor: AppColors.leaf,
          ),
        );
    }
  }

  void _hardDeleteCategory(MenuCategory cat) async {
    final confirmed = await BmbConfirmDialog.show(
      context: context,
      title: 'Delete Category Permanently',
      message:
          'Are you sure you want to delete ${cat.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      final notifier = ref.read(menuCategoryControllerProvider.notifier);
      final err = await notifier.hardDeleteCategory(cat.id);
      if (err != null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
          );
      } else {
        _refreshData();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted'),
              backgroundColor: AppColors.leaf,
            ),
          );
      }
    }
  }

  // --- Item Actions ---

  void _showEditItemModal(
    BuildContext context,
    WidgetRef ref,
    MenuItem? initialItem,
    bool canManageCategories,
    List<MenuCategory> categories,
  ) {
    MenuItem? item = initialItem;
    bool isEditing = item != null;

    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: isEditing ? item!.price.inRupees.toString() : '',
    );
    final prepTimeController = TextEditingController(
      text: isEditing ? item!.prepMin.toString() : '',
    );

    String selectedCategory = item?.cat ?? '';
    FoodType selectedType = item?.type ?? FoodType.veg;

    // Copy variants & addons so we don't mutate state directly until save
    List<({String name, double priceDelta})> variants =
        item?.variants
            .map((v) => (name: v.name, priceDelta: v.priceDelta.toRupees))
            .toList() ??
        [];

    List<({String name, double price})> addons =
        item?.addons
            .map((a) => (name: a.name, price: a.price.toRupees))
            .toList() ??
        [];

    List<MenuItemImage> currentImages = List.from(item?.images ?? []);

    String? error;
    bool isSaving = false;
    bool isUploadingImage = false;
    List<XFile> pendingCreationImages = [];
    final ImagePicker _picker = ImagePicker();

    showBmbModal(
      context: context,
      title: isEditing ? 'Edit Menu Item' : 'New Menu Item',
      maxWidth: 580,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          return LayoutBuilder(
            builder: (layoutContext, constraints) {
              final isNarrow = constraints.maxWidth < 450;

              if (selectedCategory.isEmpty && categories.isNotEmpty) {
                selectedCategory =
                    categories.first.id; // Use ID or name depending on API
              }

              final categoryField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: AppText.label),
                  AppSpacing.gapH4,
                  if (categories.isEmpty)
                    const Text('No categories available')
                  else
                    DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == selectedCategory)
                          ? selectedCategory
                          : categories.first.id,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedCategory = val);
                      },
                    ),
                ],
              );

              final priceField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base Price', style: AppText.label),
                  AppSpacing.gapH4,
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ],
              );

              final foodTypeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Food Type', style: AppText.label),
                  AppSpacing.gapH4,
                  SegmentedButton<FoodType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: FoodType.veg,
                        label: Text('Veg'),
                        icon: FoodTypeDot(type: FoodType.veg),
                      ),
                      ButtonSegment(
                        value: FoodType.nonveg,
                        label: Text('Non-Veg'),
                        icon: FoodTypeDot(type: FoodType.nonveg),
                      ),
                      ButtonSegment(
                        value: FoodType.egg,
                        label: Text('Egg'),
                        icon: FoodTypeDot(type: FoodType.egg),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) =>
                        setModalState(() => selectedType = set.first),
                  ),
                ],
              );

              final prepTimeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prep Time (mins)', style: AppText.label),
                  AppSpacing.gapH4,
                  TextFormField(
                    controller: prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 15',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ],
              );

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item Name', style: AppText.label),
                    AppSpacing.gapH4,
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Paneer Tikka',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                    AppSpacing.gapHLg,

                    if (isNarrow) ...[
                      categoryField,
                      AppSpacing.gapHLg,
                      priceField,
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: categoryField),
                          AppSpacing.gapWMd,
                          Expanded(child: priceField),
                        ],
                      ),
                    ],
                    AppSpacing.gapHLg,
                    if (isNarrow) ...[
                      foodTypeField,
                      AppSpacing.gapHLg,
                      prepTimeField,
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: foodTypeField),
                          AppSpacing.gapWMd,
                          Expanded(child: prepTimeField),
                        ],
                      ),
                    ],
                    AppSpacing.gapHXl,

                    // Variants section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Variants (Delta vs base)',
                            style: AppText.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Gap.xs),
                        BmbTextButton(
                          label: 'Add Variant',
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            setModalState(() {
                              variants.add((name: '', priceDelta: 0.0));
                            });
                          },
                        ),
                      ],
                    ),
                    for (int i = 0; i < variants.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: variants[i].name,
                                decoration: const InputDecoration(
                                  hintText: 'Variant name (e.g. Full)',
                                  isDense: true,
                                ),
                                onChanged: (v) => variants[i] = (
                                  name: v,
                                  priceDelta: variants[i].priceDelta,
                                ),
                              ),
                            ),
                            AppSpacing.gapWSm,
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: variants[i].priceDelta
                                    .toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '+ ₹',
                                  isDense: true,
                                ),
                                onChanged: (v) => variants[i] = (
                                  name: variants[i].name,
                                  priceDelta: double.tryParse(v) ?? 0.0,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.chilli,
                                size: 20,
                              ),
                              onPressed: () {
                                setModalState(() => variants.removeAt(i));
                              },
                            ),
                          ],
                        ),
                      ),
                    AppSpacing.gapHLg,
                    Text('Images (Max 5)', style: AppText.label),
                    AppSpacing.gapH4,
                    if (isUploadingImage)
                      const Padding(
                        padding: EdgeInsets.all(Gap.md),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.sm,
                        children: [
                          for (final img in currentImages)
                            Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.card,
                                    ),
                                    border: Border.all(color: AppColors.line),
                                    image: DecorationImage(
                                      image: NetworkImage(img.url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () async {
                                      final confirm = await BmbConfirmDialog.show(
                                        context: context,
                                        title: 'Remove image?',
                                        message:
                                            'Are you sure you want to remove this image?',
                                        confirmLabel: 'Remove',
                                        isDestructive: true,
                                      );
                                      if (confirm == true) {
                                        setModalState(
                                          () => isUploadingImage = true,
                                        );
                                        final res = await ref
                                            .read(menuItemApiProvider)
                                            .deleteImage(
                                              ref
                                                  .read(authControllerProvider)
                                                  .value!
                                                  .organizationId,
                                              item!.id,
                                              img.id,
                                            );
                                        if (res.success) {
                                          setModalState(() {
                                            currentImages.remove(img);
                                          });
                                          _refreshData();
                                        } else {
                                          if (mounted)
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(res.message),
                                                backgroundColor:
                                                    AppColors.chilli,
                                              ),
                                            );
                                        }
                                        setModalState(
                                          () => isUploadingImage = false,
                                        );
                                      }
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.chilli,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          for (int i = 0; i < pendingCreationImages.length; i++)
                            Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.card,
                                    ),
                                    border: Border.all(color: AppColors.line),
                                    image: DecorationImage(
                                      image: FileImage(
                                        java_io.File(
                                          pendingCreationImages[i].path,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        pendingCreationImages.removeAt(i);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.chilli,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (currentImages.length +
                                  pendingCreationImages.length <
                              5)
                            InkWell(
                              onTap: () async {
                                final files = await _picker.pickMultiImage();
                                if (files.isNotEmpty) {
                                  final allowed =
                                      5 -
                                      (currentImages.length +
                                          pendingCreationImages.length);
                                  final toUpload = files.take(allowed).toList();
                                  if (files.length > allowed && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Only 5 images allowed per item.',
                                        ),
                                        backgroundColor: AppColors.amber,
                                      ),
                                    );
                                  }
                                  if (!isEditing) {
                                    setModalState(() {
                                      pendingCreationImages.addAll(toUpload);
                                    });
                                  } else {
                                    setModalState(
                                      () => isUploadingImage = true,
                                    );
                                    final mpfList = <MultipartFile>[];
                                    for (final f in toUpload) {
                                      mpfList.add(
                                        await MultipartFile.fromFile(f.path),
                                      );
                                    }
                                    final res = await ref
                                        .read(menuItemApiProvider)
                                        .uploadImage(
                                          ref
                                              .read(authControllerProvider)
                                              .value!
                                              .organizationId,
                                          item!.id,
                                          mpfList,
                                        );
                                    if (!res.success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(res.message),
                                          backgroundColor: AppColors.chilli,
                                        ),
                                      );
                                    }
                                    if (mounted) {
                                      final items = await ref
                                          .read(
                                            menuItemControllerProvider.notifier,
                                          )
                                          .fetchActive();
                                      final updatedItem = items.firstWhere(
                                        (e) => e.id == item!.id,
                                        orElse: () => item!,
                                      );
                                      setModalState(() {
                                        currentImages = List.from(
                                          updatedItem.images,
                                        );
                                      });
                                      _refreshData();
                                    }
                                    setModalState(
                                      () => isUploadingImage = false,
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.card,
                                  ),
                                  border: Border.all(color: AppColors.line),
                                  color: AppColors.inputFill,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),

                    AppSpacing.gapHLg,

                    // Addons section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Add-ons (Optional extras)',
                            style: AppText.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Gap.xs),
                        BmbTextButton(
                          label: 'Add Add-on',
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            setModalState(() {
                              addons.add((name: '', price: 0.0));
                            });
                          },
                        ),
                      ],
                    ),
                    for (int i = 0; i < addons.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: addons[i].name,
                                decoration: const InputDecoration(
                                  hintText: 'Add-on name (e.g. Raita)',
                                  isDense: true,
                                ),
                                onChanged: (v) => addons[i] = (
                                  name: v,
                                  price: addons[i].price,
                                ),
                              ),
                            ),
                            AppSpacing.gapWSm,
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: addons[i].price.toStringAsFixed(
                                  0,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '₹',
                                  isDense: true,
                                ),
                                onChanged: (v) => addons[i] = (
                                  name: addons[i].name,
                                  price: double.tryParse(v) ?? 0.0,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.chilli,
                                size: 20,
                              ),
                              onPressed: () {
                                setModalState(() => addons.removeAt(i));
                              },
                            ),
                          ],
                        ),
                      ),

                    if (isEditing) ...[
                      AppSpacing.gapHLg,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                item!.isActive ? Icons.block : Icons.restore,
                                size: 16,
                                color: item!.isActive
                                    ? AppColors.chilli
                                    : AppColors.tandoor,
                              ),
                              label: Text(
                                item!.isActive
                                    ? 'Deactivate Item'
                                    : 'Recover Item',
                                style: TextStyle(
                                  color: item!.isActive
                                      ? AppColors.chilli
                                      : AppColors.tandoor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: item!.isActive
                                      ? AppColors.chilli
                                      : AppColors.tandoor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: Gap.md,
                                ),
                              ),
                              onPressed: () async {
                                final notifier = ref.read(
                                  menuItemControllerProvider.notifier,
                                );
                                final err = item!.isActive
                                    ? await notifier.deactivateItem(item!.id)
                                    : await notifier.recoverItem(item!.id);
                                if (mounted) {
                                  if (err != null) {
                                    setModalState(() => error = err);
                                  } else {
                                    Navigator.of(layoutContext).pop();
                                    _refreshData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          item!.isActive
                                              ? 'Item deactivated'
                                              : 'Item recovered',
                                        ),
                                        backgroundColor: AppColors.leaf,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (error != null) ...[
                      AppSpacing.gapHLg,
                      Text(
                        error!,
                        style: AppText.caption.copyWith(
                          color: AppColors.chilli,
                        ),
                      ),
                    ],

                    AppSpacing.gapHXxl,

                    Row(
                      children: [
                        Expanded(
                          child: BmbSecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(layoutContext).pop(),
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Expanded(
                          child: BmbPrimaryButton(
                            label: isSaving
                                ? 'Saving...'
                                : (isEditing ? 'Save Changes' : 'Create Item'),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final price =
                                        double.tryParse(priceController.text) ??
                                        0.0;
                                    final prepTime =
                                        int.tryParse(prepTimeController.text) ??
                                        12;

                                    if (name.isEmpty ||
                                        price <= 0 ||
                                        selectedCategory.isEmpty) {
                                      setModalState(
                                        () => error =
                                            'Please fill out name, category and a valid price',
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      error = null;
                                      isSaving = true;
                                    });

                                    final data = <String, dynamic>{
                                      'name': name,
                                      'categoryId': selectedCategory,
                                      'category': selectedCategory,
                                      'cat': selectedCategory,
                                      'basePrice': price,
                                      'price': price,
                                      'foodType': selectedType == FoodType.veg
                                          ? 'Veg'
                                          : (selectedType == FoodType.nonveg
                                                ? 'Non-veg'
                                                : 'Egg'),
                                      'prepTime': prepTime,
                                    };

                                    final vList = variants
                                        .where((v) => v.name.trim().isNotEmpty)
                                        .map(
                                          (v) => {
                                            'name': v.name.trim(),
                                            'priceDelta': v.priceDelta,
                                            'price': v.priceDelta,
                                          },
                                        )
                                        .toList();
                                    if (vList.isNotEmpty) {
                                      data['variants'] = vList;
                                    }

                                    final aList = addons
                                        .where((a) => a.name.trim().isNotEmpty)
                                        .map(
                                          (a) => {
                                            'name': a.name.trim(),
                                            'price': a.price,
                                          },
                                        )
                                        .toList();
                                    if (aList.isNotEmpty) {
                                      data['addOns'] = aList;
                                    }

                                    final notifier = ref.read(
                                      menuItemControllerProvider.notifier,
                                    );
                                    if (isEditing) {
                                      final resultError = await notifier
                                          .updateItem(item!.id, data);
                                      if (mounted) {
                                        setModalState(() => isSaving = false);
                                        if (resultError != null) {
                                          setModalState(
                                            () => error = resultError,
                                          );
                                        } else {
                                          Navigator.of(layoutContext).pop();
                                          _refreshData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Item updated'),
                                              backgroundColor: AppColors.leaf,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      final mpfList = <MultipartFile>[];
                                      for (final f in pendingCreationImages) {
                                        mpfList.add(
                                          await MultipartFile.fromFile(f.path),
                                        );
                                      }
                                      final res = await notifier
                                          .createItemReturnObj(
                                            data,
                                            files: mpfList.isNotEmpty
                                                ? mpfList
                                                : null,
                                          );
                                      if (mounted) {
                                        setModalState(() => isSaving = false);
                                        if (res.error != null) {
                                          bool itemSaved = false;
                                          try {
                                            await ref.read(menuItemControllerProvider.notifier).fetchActive();
                                            _refreshData();
                                            final currentItems = ref.read(menuItemControllerProvider).value ?? [];
                                            itemSaved = currentItems.any((i) => i.name.toLowerCase() == name.toLowerCase());
                                          } catch (_) {}
                                          
                                          if (itemSaved) {
                                            Navigator.of(layoutContext).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Item saved, but the image couldn't be uploaded. You can add it later from the edit form."),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          } else {
                                            setModalState(
                                              () => error = res.error,
                                            );
                                          }
                                        } else {
                                          Navigator.of(layoutContext).pop();
                                          _refreshData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Item created successfully.',
                                              ),
                                              backgroundColor: AppColors.leaf,
                                            ),
                                          );
                                        }
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
            },
          );
        },
      ),
    );
  }

  void _recoverItem(MenuItem item) async {
    final notifier = ref.read(menuItemControllerProvider.notifier);
    final err = await notifier.recoverItem(item.id);
    if (err != null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
        );
    } else {
      _refreshData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item recovered'),
            backgroundColor: AppColors.leaf,
          ),
        );
    }
  }

  void _hardDeleteItem(MenuItem item) async {
    final confirmed = await BmbConfirmDialog.show(
      context: context,
      title: 'Delete Menu Item Permanently',
      message:
          'Are you sure you want to delete ${item.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      final notifier = ref.read(menuItemControllerProvider.notifier);
      final err = await notifier.hardDeleteItem(item.id);
      if (err != null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.chilli),
          );
      } else {
        _refreshData();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted'),
              backgroundColor: AppColors.leaf,
            ),
          );
      }
    }
  }
}
