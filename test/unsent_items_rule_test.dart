import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/core/money/paise.dart';
import 'package:bmb_kitchen/models/models.dart';

void main() {
  group('POS Unsent Items Blocking Rule', () {
    test('order hasUnsentItems is true when pending items exist', () {
      const line = OrderLine(
        sig: 'm1|||',
        itemId: 'm1',
        name: 'Paneer Tikka',
        qty: 1,
        unitPrice: Paise(22000),
      );

      final orderWithPending = Order(
        id: 'O1',
        no: 1,
        type: OrderType.dinein,
        tableId: 'T1',
        outlet: 'o1',
        items: const [],
        pending: const [line], // Item not yet sent to kitchen
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        staffId: 's1',
      );

      expect(orderWithPending.hasUnsentItems, isTrue);

      // Once sent to kitchen, line moves to items with kotNo assigned
      final sentLine = line.copyWith(kotNo: 1);
      final orderAllSent = orderWithPending.copyWith(
        items: [sentLine],
        pending: const [],
      );

      expect(orderAllSent.hasUnsentItems, isFalse);
      expect(orderAllSent.items.first.isSent, isTrue);
    });
  });
}
