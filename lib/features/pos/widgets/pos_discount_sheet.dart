import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../mock/mock_state.dart';

class PosDiscountSheet extends ConsumerStatefulWidget {
  final Paise subtotal;
  final double currentDiscVal;
  final String currentDiscType;
  final String currentOfferCode;
  final Function({required double value, required String type})
  onApplyManualDiscount;
  final Function(String code) onApplyOfferCode;
  final VoidCallback onRemoveDiscount;

  const PosDiscountSheet({
    super.key,
    required this.subtotal,
    required this.currentDiscVal,
    required this.currentDiscType,
    required this.currentOfferCode,
    required this.onApplyManualDiscount,
    required this.onApplyOfferCode,
    required this.onRemoveDiscount,
  });

  @override
  ConsumerState<PosDiscountSheet> createState() => _PosDiscountSheetState();
}

class _PosDiscountSheetState extends ConsumerState<PosDiscountSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _valController = TextEditingController();
  String _selectedMode = 'pct'; // "pct" or "amt"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.currentOfferCode.isNotEmpty) {
      _tabController.index = 1;
    } else if (widget.currentDiscVal > 0) {
      _selectedMode = widget.currentDiscType;
      _valController.text = widget.currentDiscVal.toStringAsFixed(
        widget.currentDiscVal.truncateToDouble() == widget.currentDiscVal
            ? 0
            : 2,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bmbState = ref.watch(bmbStateProvider);
    final activeOffers = bmbState.offers.where((o) => o.active).toList();

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.leafSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: AppColors.leaf,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apply Bill Discount', style: AppText.h2),
                      Text(
                        'Manager authorized · Subtotal ${widget.subtotal.inr0}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.currentDiscVal > 0 ||
                  widget.currentOfferCode.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    widget.onRemoveDiscount();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.chilli,
                  ),
                  label: Text(
                    'Remove',
                    style: AppText.caption.copyWith(
                      color: AppColors.chilli,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.line),

          // Tabs: Manual Discount vs Promotional Offers
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.button),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(31, 27, 22, 0.08),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.muted,
              labelStyle: AppText.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Manual (% / ₹)'),
                Tab(text: 'Promo Coupon'),
              ],
            ),
          ),
          AppSpacing.gapH20,

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Manual Discount
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle % vs ₹
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('Percentage (%)'),
                              ),
                              selected: _selectedMode == 'pct',
                              onSelected: (_) =>
                                  setState(() => _selectedMode = 'pct'),
                              selectedColor: AppColors.tandoorSoft,
                              backgroundColor: AppColors.paper,
                              labelStyle: AppText.bodyMedium.copyWith(
                                color: _selectedMode == 'pct'
                                    ? AppColors.tandoor
                                    : AppColors.ink,
                                fontWeight: _selectedMode == 'pct'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.pillRadius,
                                side: BorderSide(
                                  color: _selectedMode == 'pct'
                                      ? AppColors.tandoor
                                      : AppColors.line,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                          AppSpacing.gapW12,
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('Flat Rupees (₹)'),
                              ),
                              selected: _selectedMode == 'amt',
                              onSelected: (_) =>
                                  setState(() => _selectedMode = 'amt'),
                              selectedColor: AppColors.tandoorSoft,
                              backgroundColor: AppColors.paper,
                              labelStyle: AppText.bodyMedium.copyWith(
                                color: _selectedMode == 'amt'
                                    ? AppColors.tandoor
                                    : AppColors.ink,
                                fontWeight: _selectedMode == 'amt'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.pillRadius,
                                side: BorderSide(
                                  color: _selectedMode == 'amt'
                                      ? AppColors.tandoor
                                      : AppColors.line,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,

                      // Quick preset buttons
                      Text('QUICK PRESETS', style: AppText.sectionLabel),
                      AppSpacing.gapH8,
                      Wrap(
                        spacing: 8,
                        children: _selectedMode == 'pct'
                            ? [5, 10, 15, 20, 25].map((p) {
                                return ActionChip(
                                  label: Text('$p%'),
                                  labelStyle: AppText.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  backgroundColor: AppColors.paper,
                                  onPressed: () {
                                    setState(
                                      () => _valController.text = p.toString(),
                                    );
                                  },
                                );
                              }).toList()
                            : [50, 100, 150, 200, 500].map((r) {
                                return ActionChip(
                                  label: Text('₹$r'),
                                  labelStyle: AppText.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  backgroundColor: AppColors.paper,
                                  onPressed: () {
                                    setState(
                                      () => _valController.text = r.toString(),
                                    );
                                  },
                                );
                              }).toList(),
                      ),
                      AppSpacing.gapH16,

                      // Custom Value input
                      TextField(
                        controller: _valController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _selectedMode == 'pct'
                              ? 'Discount Percentage (%)'
                              : 'Discount Amount (₹)',
                          hintText: _selectedMode == 'pct'
                              ? 'e.g. 10'
                              : 'e.g. 150',
                          prefixIcon: Icon(
                            _selectedMode == 'pct'
                                ? Icons.percent
                                : Icons.currency_rupee,
                            size: 20,
                          ),
                        ),
                      ),
                      AppSpacing.gapH24,

                      BmbButton.primary(
                        label: 'Apply Manual Discount',
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        onPressed: () {
                          final parsed =
                              double.tryParse(_valController.text.trim()) ?? 0;
                          if (parsed <= 0) return;
                          widget.onApplyManualDiscount(
                            value: parsed,
                            type: _selectedMode,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // 2. Promotional Offers List
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeOffers.length,
                  itemBuilder: (context, index) {
                    final offer = activeOffers[index];
                    final isEligible = widget.subtotal >= offer.minBill;
                    final isCurrent = widget.currentOfferCode == offer.code;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: isEligible
                            ? () {
                                widget.onApplyOfferCode(offer.code);
                                Navigator.of(context).pop();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Opacity(
                          opacity: isEligible ? 1.0 : 0.5,
                          child: BmbCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: isCurrent
                                ? AppColors.tandoorSoft
                                : AppColors.card,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.tandoor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer_outlined,
                                    color: AppColors.tandoor,
                                    size: 22,
                                  ),
                                ),
                                AppSpacing.gapW12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            offer.code,
                                            style: AppText.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          AppSpacing.gapW8,
                                          BmbTag(
                                            label: offer.type == 'pct'
                                                ? '${offer.value.toInt()}% OFF'
                                                : '₹${offer.value.toInt()} OFF',
                                            variant: BmbTagVariant.green,
                                          ),
                                        ],
                                      ),
                                      AppSpacing.gapH4,
                                      Text(offer.name, style: AppText.caption),
                                      if (offer.minBill > const Paise(0))
                                        Text(
                                          'Min bill: ${offer.minBill.inr0}',
                                          style: AppText.caption.copyWith(
                                            color: AppColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.tandoor,
                                  )
                                else if (isEligible)
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.muted,
                                  )
                                else
                                  Text(
                                    'Min ${offer.minBill.inr0}',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.chilli,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
