import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/mock/mock_state.dart';
import 'package:bmb_kitchen/models/models.dart';

void main() {
  group('Menu & Table Management Tests', () {
    test('Toggling menu item availability updates state immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bmbStateProvider.notifier);
      final initialItem = container
          .read(bmbStateProvider)
          .menuItems
          .firstWhere((m) => m.id == 'm1');
      expect(initialItem.avail, isTrue);

      // Toggle off
      notifier.toggleItemAvailability('m1');
      final updatedItem = container
          .read(bmbStateProvider)
          .menuItems
          .firstWhere((m) => m.id == 'm1');
      expect(updatedItem.avail, isFalse);

      // Toggle on
      notifier.toggleItemAvailability('m1');
      final restoredItem = container
          .read(bmbStateProvider)
          .menuItems
          .firstWhere((m) => m.id == 'm1');
      expect(restoredItem.avail, isTrue);
    });

    test('Live food cost and margin calculation from recipe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bmbStateProvider.notifier);
      // Chicken Biryani m10 has recipe: i1 (0.25 kg * 98 = 24.5), i2 (0.18 kg * 245 = 44.1), i5 (0.08 * 38 = 3.04), i4 (0.03 * 142 = 4.26), i10 (0.04 * 72 = 2.88)
      // Total food cost approx ~₹78.78
      final cost = notifier.calculateFoodCost('m10');
      expect(cost, isNotNull);
      expect(cost!.toRupees, greaterThan(70));
      expect(cost.toRupees, lessThan(90));
    });

    test('Starting order for table marks table occupied', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bmbStateProvider.notifier);
      final initialTable = container
          .read(bmbStateProvider)
          .tables
          .firstWhere((t) => t.id == 'T1');
      expect(initialTable.status, TableStatus.available);

      final order = notifier.startNewOrder(
        type: OrderType.dinein,
        tableId: 'T1',
      );
      expect(order.tableId, 'T1');

      final updatedTable = container
          .read(bmbStateProvider)
          .tables
          .firstWhere((t) => t.id == 'T1');
      expect(updatedTable.status, TableStatus.occupied);
      expect(updatedTable.orderId, order.id);
    });

    test('Releasing reservation returns table to available', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bmbStateProvider.notifier);
      final reservedTable = container
          .read(bmbStateProvider)
          .tables
          .firstWhere((t) => t.id == 'T10');
      expect(reservedTable.status, TableStatus.reserved);
      expect(reservedTable.resName, isNotNull);

      notifier.releaseReservation('T10');
      final releasedTable = container
          .read(bmbStateProvider)
          .tables
          .firstWhere((t) => t.id == 'T10');
      expect(releasedTable.status, TableStatus.available);
      expect(releasedTable.resName, isNull);
    });
  });
}
