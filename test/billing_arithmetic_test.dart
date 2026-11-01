import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/core/money/money_format.dart';
import 'package:bmb_kitchen/core/money/paise.dart';
import 'package:bmb_kitchen/core/widgets/food_type_dot.dart';
import 'package:bmb_kitchen/models/models.dart';

void main() {
  group('BMB Kitchen Billing Arithmetic Acceptance Test', () {
    test(
      'variant + add-on + percentage discount matches manual calculation to the paisa',
      () {
        // 1. Menu Items setup
        final biryani = MenuItem(
          id: 'm10',
          name: 'Chicken Biryani',
          cat: 'Rice & Noodles',
          price: Paise.fromRupees(280),
          type: FoodType.nonveg,
          variants: [
            MenuVariant(name: 'Half', priceDelta: Paise.fromRupees(-80)),
            MenuVariant(name: 'Full', priceDelta: Paise.fromRupees(0)),
          ],
          addons: [MenuAddon(name: 'Raita', price: Paise.fromRupees(30))],
        );

        final naan = MenuItem(
          id: 'm13',
          name: 'Butter Naan',
          cat: 'Breads',
          price: Paise.fromRupees(55),
          type: FoodType.veg,
        );

        // 2. Line 1: Half Biryani (-₹80) + Raita (+₹30) -> Unit: ₹230, Qty: 2 -> Total: ₹460
        final halfVariant = biryani.variants.firstWhere(
          (v) => v.name == 'Half',
        );
        final raitaAddon = biryani.addons.firstWhere((a) => a.name == 'Raita');
        final line1UnitPrice = biryani.calculateUnitPrice(
          variant: halfVariant,
          selectedAddons: [raitaAddon],
        );
        expect(line1UnitPrice.value, 23000); // exactly ₹230.00

        final line1 = OrderLine(
          sig: OrderLine.generateSig(
            itemId: biryani.id,
            variant: 'Half',
            addons: ['Raita'],
          ),
          itemId: biryani.id,
          name: biryani.name,
          qty: 2,
          variant: 'Half',
          addons: const ['Raita'],
          unitPrice: line1UnitPrice,
        );
        expect(line1.lineTotal.value, 46000); // ₹460.00

        // 3. Line 2: 2 Butter Naan (₹55) -> Total: ₹110
        final line2 = OrderLine(
          sig: OrderLine.generateSig(itemId: naan.id),
          itemId: naan.id,
          name: naan.name,
          qty: 2,
          unitPrice: naan.price,
        );
        expect(line2.lineTotal.value, 11000); // ₹110.00

        // 4. Subtotal: ₹460 + ₹110 = ₹570
        final subtotal = line1.lineTotal + line2.lineTotal;
        expect(subtotal.value, 57000);

        // 5. 10% Discount on ₹570: ₹57.00
        final discount = subtotal * 0.10;
        expect(discount.value, 5700);

        // 6. Taxable Value: ₹570 - ₹57 = ₹513.00
        final totals = OrderTotals.calculate(
          subtotal: subtotal,
          discount: discount,
          serviceChargePct: 0.0,
          applyServiceCharge: false,
          taxPct: 5.0,
          loyaltyRedemption: const Paise(0),
        );

        expect(totals.taxable.value, 51300); // ₹513.00

        // 7. GST: 5% of ₹513.00 = ₹25.65 (2565 paise)
        expect(totals.gst.value, 2565);

        // Split equally to CGST & SGST (no paisa lost)
        expect(totals.cgst.value + totals.sgst.value, 2565);
        expect(totals.cgst.value, 1283); // ₹12.83
        expect(totals.sgst.value, 1282); // ₹12.82

        // 8. Gross: ₹513.00 + ₹25.65 = ₹538.65 (53865 paise)
        expect(totals.gross.value, 53865);

        // 9. Round to nearest Rupee: ₹538.65 -> ₹539.00 (53900 paise)
        expect(totals.total.value, 53900);

        // Rounding adjustment: +₹0.35 (+35 paise)
        expect(totals.roundAdjustment.value, 35);
      },
    );
  });
}
