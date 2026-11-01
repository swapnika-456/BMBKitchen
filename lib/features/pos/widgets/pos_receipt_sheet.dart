import 'package:flutter/material.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../models/order.dart';
import '../../../models/restaurant_setup.dart';

class PosReceiptSheet extends StatelessWidget {
  final Order order;
  final RestaurantSetup setup;
  final OrderTotals totals;
  final Paise change;
  final VoidCallback onClose;

  const PosReceiptSheet({
    super.key,
    required this.order,
    required this.setup,
    required this.totals,
    this.change = const Paise(0),
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.fromMillisecondsSinceEpoch(
      order.closedAtMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.leaf,
                    size: 24,
                  ),
                  AppSpacing.gapW8,
                  Text(
                    'Bill Settled Successfully',
                    style: AppText.h3.copyWith(color: AppColors.leaf),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          AppSpacing.gapH12,

          // Printable Thermal Receipt Card
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: BmbCard(
                backgroundColor: AppColors.paper,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Header
                    Text(
                      setup.brand.toUpperCase(),
                      style: AppText.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      setup.legal,
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      setup.address,
                      style: AppText.caption,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Phone: ${setup.phone}',
                      style: AppText.caption,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapH8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GSTIN: ${setup.gstin}',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(' · '),
                        Text(
                          'FSSAI: ${setup.fssai}',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 20,
                      color: AppColors.line,
                      thickness: 1,
                    ),

                    // Bill Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill No: ${order.billNo ?? "INV-001"}',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(dateStr, style: AppText.caption),
                      ],
                    ),
                    AppSpacing.gapH4,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Type: ${order.type.label}',
                          style: AppText.caption,
                        ),
                        if (order.tableId != null)
                          Text(
                            'Table: ${order.tableId}',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else if (order.token != null)
                          Text(
                            'Token: #${order.token}',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    if (order.customerName.isNotEmpty) ...[
                      AppSpacing.gapH4,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer: ${order.customerName}',
                            style: AppText.caption,
                          ),
                          Text(order.customerPhone, style: AppText.caption),
                        ],
                      ),
                    ],
                    const Divider(
                      height: 20,
                      color: AppColors.line,
                      thickness: 1,
                    ),

                    // Itemized Table
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text('ITEM', style: AppText.sectionLabel),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'QTY',
                            style: AppText.sectionLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'AMOUNT',
                            style: AppText.sectionLabel,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12, color: AppColors.line),

                    ...order.items.map((line) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style: AppText.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (line.variant != null ||
                                      line.addons.isNotEmpty)
                                    Text(
                                      [
                                        if (line.variant != null) line.variant,
                                        ...line.addons,
                                      ].join(', '),
                                      style: AppText.caption.copyWith(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                line.qty.toString(),
                                style: AppText.numMd.copyWith(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                line.lineTotal.inr0,
                                style: AppText.numMd.copyWith(fontSize: 13),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(
                      height: 20,
                      color: AppColors.line,
                      thickness: 1,
                    ),

                    // Calculations
                    _calcRow('Subtotal', totals.subtotal.inr0),
                    if (totals.discount > const Paise(0))
                      _calcRow(
                        'Discount',
                        '- ${totals.discount.inr0}',
                        isDiscount: true,
                      ),
                    if (totals.serviceCharge > const Paise(0))
                      _calcRow(
                        'Service Charge (5%)',
                        totals.serviceCharge.inr0,
                      ),
                    _calcRow('CGST (2.5%)', totals.cgst.inr0),
                    _calcRow('SGST (2.5%)', totals.sgst.inr0),
                    if (totals.loyaltyRedeemed > const Paise(0))
                      _calcRow(
                        'Loyalty Redeemed',
                        '- ${totals.loyaltyRedeemed.inr0}',
                        isDiscount: true,
                      ),
                    if (totals.roundAdjustment.value != 0)
                      _calcRow(
                        'Round Off',
                        '${totals.roundAdjustment.value > 0 ? "+" : ""}${totals.roundAdjustment.inr}',
                      ),
                    const Divider(
                      height: 16,
                      color: AppColors.line,
                      thickness: 1.5,
                    ),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GRAND TOTAL',
                          style: AppText.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          totals.total.inr0,
                          style: AppText.h2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.tandoor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.line),

                    // Payment Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PAID VIA', style: AppText.sectionLabel),
                        Text(
                          order.payments
                              .map((p) => '${p.mode.label}: ${p.amount.inr0}')
                              .join(', '),
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (change > const Paise(0)) ...[
                      AppSpacing.gapH4,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CHANGE RETURNED', style: AppText.sectionLabel),
                          Text(
                            change.inr0,
                            style: AppText.caption.copyWith(
                              color: AppColors.leaf,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    AppSpacing.gapH16,

                    // Footer
                    Text(
                      setup.footer,
                      style: AppText.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapH20,

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: BmbButton.outline(
                  label: 'Print Bill',
                  icon: const Icon(Icons.print_outlined, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Simulating ESC/POS print to Main Bill Printer...',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: BmbButton.primary(
                  label: 'Next Order',
                  icon: const Icon(Icons.check, size: 18),
                  onPressed: onClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.caption.copyWith(
              color: isDiscount ? AppColors.leaf : AppColors.ink,
            ),
          ),
          Text(
            value,
            style: AppText.numMd.copyWith(
              fontSize: 12,
              color: isDiscount ? AppColors.leaf : AppColors.ink,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
