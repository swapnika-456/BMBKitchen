import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/core/money/paise.dart';

void main() {
  group('Paise Integer Arithmetic', () {
    test('creates from rupees accurately', () {
      final p1 = Paise.fromRupees(220);
      expect(p1.value, 22000);
      expect(p1.inRupees, 220);
      expect(p1.toRupees, 220.0);

      final p2 = Paise.fromRupees(220.50);
      expect(p2.value, 22050);
      expect(p2.inRupees, 220);
      expect(p2.toRupees, 220.50);
    });

    test('adds and subtracts without floating point drift', () {
      const p1 = Paise(22050); // ₹220.50
      const p2 = Paise(17950); // ₹179.50
      final sum = p1 + p2;
      expect(sum.value, 40000); // exactly ₹400.00
      expect(sum.toRupees, 400.0);

      final diff = sum - p1;
      expect(diff.value, 17950);
    });

    test('rounds to nearest Rupee and records adjustment', () {
      // 43250 paise = ₹432.50 -> rounds to ₹433.00 (43300 paise) with +50 paise adjustment
      const p = Paise(43250);
      final res = p.roundToRupee();
      expect(res.rounded.value, 43300);
      expect(res.adjustment.value, 50);

      // 43240 paise = ₹432.40 -> rounds to ₹432.00 (43200 paise) with -40 paise adjustment
      const p2 = Paise(43240);
      final res2 = p2.roundToRupee();
      expect(res2.rounded.value, 43200);
      expect(res2.adjustment.value, -40);
    });

    test('formats correctly with Indian numbering system', () {
      final p = Paise.fromRupees(112400.50);
      expect(p.inr, contains('1,12,400.50'));
      expect(p.inr0, contains('1,12,401'));
    });
  });
}
