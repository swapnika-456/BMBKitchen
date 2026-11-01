import 'package:flutter/material.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/food_type_dot.dart';
import '../../../models/menu_item.dart';

/// Modal sheet for selecting item variants, add-ons, and special kitchen instructions.
class ItemOptionsSheet extends StatefulWidget {
  final MenuItem item;
  final Function(MenuVariant? variant, List<MenuAddon> addons, String note)
  onConfirm;

  const ItemOptionsSheet({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  @override
  State<ItemOptionsSheet> createState() => _ItemOptionsSheetState();
}

class _ItemOptionsSheetState extends State<ItemOptionsSheet> {
  MenuVariant? _selectedVariant;
  final Set<MenuAddon> _selectedAddons = {};
  final TextEditingController _noteController = TextEditingController();

  final List<String> _quickNotes = const [
    'Less spicy',
    'Extra spicy',
    'No onion/garlic',
    'Jain prep',
    'Extra crispy',
    'Pack separately',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item.variants.isNotEmpty) {
      _selectedVariant = widget.item.variants.first;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Paise get _currentUnitPrice {
    return widget.item.calculateUnitPrice(
      variant: _selectedVariant,
      selectedAddons: _selectedAddons.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s20,
        right: AppSpacing.s20,
        top: AppSpacing.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapH16,

          // Header with item name, food type dot & base price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FoodTypeDot(type: widget.item.type, size: 16),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: AppText.h2),
                    AppSpacing.gapH4,
                    Text(widget.item.cat, style: AppText.caption),
                  ],
                ),
              ),
              Text(
                _currentUnitPrice.inr0,
                style: AppText.h2.copyWith(
                  color: AppColors.tandoor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.line),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Variant selection
                  if (widget.item.variants.isNotEmpty) ...[
                    Text('PORTION / VARIANT', style: AppText.sectionLabel),
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: widget.item.variants.map((v) {
                        final isSelected = _selectedVariant?.name == v.name;
                        final deltaSign = v.priceDelta.value > 0
                            ? '+ '
                            : (v.priceDelta.value < 0 ? '- ' : '');
                        final deltaStr = v.priceDelta.value != 0
                            ? ' ($deltaSign${v.priceDelta.abs().inr0})'
                            : '';

                        return ChoiceChip(
                          label: Text('${v.name}$deltaStr'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedVariant = v);
                            }
                          },
                          selectedColor: AppColors.tandoorSoft,
                          backgroundColor: AppColors.paper,
                          labelStyle: AppText.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.tandoor
                                : AppColors.ink,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.pillRadius,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.tandoor
                                  : AppColors.line,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    AppSpacing.gapH20,
                  ],

                  // 2. Add-ons selection
                  if (widget.item.addons.isNotEmpty) ...[
                    Text('ADD-ONS & EXTRAS', style: AppText.sectionLabel),
                    AppSpacing.gapH8,
                    ...widget.item.addons.map((addon) {
                      final isChecked = _selectedAddons.any(
                        (a) => a.name == addon.name,
                      );
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedAddons.removeWhere(
                                (a) => a.name == addon.name,
                              );
                            } else {
                              _selectedAddons.add(addon);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.tandoorSoft.withValues(alpha: 0.5)
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            border: Border.all(
                              color: isChecked
                                  ? AppColors.tandoor
                                  : AppColors.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: isChecked
                                    ? AppColors.tandoor
                                    : AppColors.muted,
                              ),
                              AppSpacing.gapW12,
                              Expanded(
                                child: Text(
                                  addon.name,
                                  style: AppText.bodyMedium.copyWith(
                                    fontWeight: isChecked
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                '+ ${addon.price.inr0}',
                                style: AppText.priceBold.copyWith(
                                  fontSize: 14,
                                  color: isChecked
                                      ? AppColors.tandoor
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    AppSpacing.gapH16,
                  ],

                  // 3. Special Instructions / Cooking Notes
                  Text(
                    'SPECIAL COOKING INSTRUCTIONS',
                    style: AppText.sectionLabel,
                  ),
                  AppSpacing.gapH8,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickNotes.map((q) {
                      final isActive = _noteController.text.contains(q);
                      return ActionChip(
                        label: Text(q),
                        labelStyle: AppText.caption.copyWith(
                          color: isActive ? AppColors.tandoor : AppColors.ink,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        backgroundColor: isActive
                            ? AppColors.tandoorSoft
                            : AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.pillRadius,
                          side: BorderSide(
                            color: isActive
                                ? AppColors.tandoor
                                : AppColors.line,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            if (isActive) {
                              _noteController.text = _noteController.text
                                  .replaceAll(q, '')
                                  .replaceAll('  ', ' ')
                                  .trim();
                            } else {
                              final cur = _noteController.text.trim();
                              _noteController.text = cur.isEmpty
                                  ? q
                                  : '$cur, $q';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.gapH8,
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Extra spicy, less oil, pack pickle',
                      hintStyle: AppText.body.copyWith(color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.paper,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(
                          color: AppColors.tandoor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH20,

          // Confirmation button
          Row(
            children: [
              Expanded(
                child: BmbButton.primary(
                  label: 'Add to Order · ${_currentUnitPrice.inr0}',
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  onPressed: () {
                    widget.onConfirm(
                      _selectedVariant,
                      _selectedAddons.toList(),
                      _noteController.text.trim(),
                    );
                    Navigator.of(context).pop();
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
