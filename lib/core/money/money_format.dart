import 'paise.dart';

/// Computed financial summary for an order adhering to BMB Kitchen rules.
class OrderTotals {
  final Paise subtotal;
  final Paise discount;
  final Paise serviceCharge;
  final Paise taxable;
  final double taxPct;
  final Paise gst;
  final Paise cgst;
  final Paise sgst;
  final Paise loyaltyRedeemed;
  final Paise gross;
  final Paise total;
  final Paise roundAdjustment;

  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.taxable,
    required this.taxPct,
    required this.gst,
    required this.cgst,
    required this.sgst,
    required this.loyaltyRedeemed,
    required this.gross,
    required this.total,
    required this.roundAdjustment,
  });

  /// Factory implementing the strict BMB Kitchen calculation order:
  /// subtotal → discount → service charge → tax → loyalty redemption → round
  factory OrderTotals.calculate({
    required Paise subtotal,
    required Paise discount,
    required double serviceChargePct,
    required bool applyServiceCharge,
    required double taxPct,
    required Paise loyaltyRedemption,
  }) {
    // 1. Service charge applied on subtotal
    final serviceCharge = applyServiceCharge && serviceChargePct > 0
        ? subtotal * (serviceChargePct / 100.0)
        : const Paise(0);

    // 2. Discount capped at subtotal + service charge
    final effectiveDiscount = discount > (subtotal + serviceCharge)
        ? (subtotal + serviceCharge)
        : discount;

    // 3. Taxable value = subtotal + service charge - discounts
    final taxable = (subtotal + serviceCharge) - effectiveDiscount;

    // 4. GST split equally to CGST and SGST
    final gst = taxable * (taxPct / 100.0);
    final cgst = gst / 2;
    final sgst = gst - cgst; // Ensure no paisa lost to odd numbers

    // 5. Gross
    final gross = taxable + gst;

    // 6. Loyalty redemption capped at gross
    final effectiveLoyalty = loyaltyRedemption > gross
        ? gross
        : loyaltyRedemption;
    final afterLoyalty = gross - effectiveLoyalty;

    // 7. Round to nearest Rupee once, recording adjustment
    final roundResult = afterLoyalty.roundToRupee();

    return OrderTotals(
      subtotal: subtotal,
      discount: effectiveDiscount,
      serviceCharge: serviceCharge,
      taxable: taxable,
      taxPct: taxPct,
      gst: gst,
      cgst: cgst,
      sgst: sgst,
      loyaltyRedeemed: effectiveLoyalty,
      gross: gross,
      total: roundResult.rounded,
      roundAdjustment: roundResult.adjustment,
    );
  }

  static const zero = OrderTotals(
    subtotal: Paise(0),
    discount: Paise(0),
    serviceCharge: Paise(0),
    taxable: Paise(0),
    taxPct: 5.0,
    gst: Paise(0),
    cgst: Paise(0),
    sgst: Paise(0),
    loyaltyRedeemed: Paise(0),
    gross: Paise(0),
    total: Paise(0),
    roundAdjustment: Paise(0),
  );
}
