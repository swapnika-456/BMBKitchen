import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/models/recipe_cost.dart';
import 'package:bmb_kitchen/features/supply_chain/controllers/recipe_cost_controller.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/recipe_management_screen.dart';

void main() {
  group('Module 10 Recipe Cost Model & Formula Tests', () {
    test('Formula confirmation: rate * unitValue and grossMargin percentage', () {
      // 1 ingredient: rate 40, unitValue 0.25 -> 10. sellingPrice 100 -> grossMargin 90%
      const ing1 = RecipeCostIngredient(
        id: 'ing1',
        inventoryId: 'inv1',
        inventoryMaterial: 'Flour',
        unit: 'kg',
        rate: 40.0,
        unitValue: 0.25,
      );
      expect(ing1.lineCost, 10.0);

      // 2 ingredients: rate 60, unitValue 0.5 -> 30. Total cost = 10 + 30 = 40.
      const ing2 = RecipeCostIngredient(
        id: 'ing2',
        inventoryId: 'inv2',
        inventoryMaterial: 'Sugar',
        unit: 'kg',
        rate: 60.0,
        unitValue: 0.5,
      );
      expect(ing2.lineCost, 30.0);

      const sellingPrice = 100.0;
      final totalCost = ing1.lineCost + ing2.lineCost;
      expect(totalCost, 40.0);

      final computedMargin = ((sellingPrice - totalCost) / sellingPrice) * 100.0;
      expect(computedMargin, 60.0); // Exactly 60%
    });

    test('RecipeCost parses populated response correctly (#79, #81, #82)', () {
      final json = {
        '_id': 'rc_123',
        'organizationId': 'org_123',
        'recipeCostNo': 'RC-001',
        'menuItemId': {
          '_id': 'm_dish_1',
          'name': 'Paneer Butter Masala',
        },
        'ingredients': [
          {
            '_id': 'ing_row_1',
            'inventoryId': {
              '_id': 'inv_paneer',
              'material': 'Paneer',
              'rate': 250.0,
              'unit': 'kg',
            },
            'unit': 'kg',
            'rate': 250.0,
            'unitValue': 0.2,
          },
        ],
        'totalPrice': 50.0,
        'grossMargin': 75.0,
        'sellingPrice': 200.0,
        'isActive': true,
        'createdAt': '2026-10-21T04:46:54.120Z',
      };

      final rc = RecipeCost.fromJson(json);
      expect(rc.id, 'rc_123');
      expect(rc.recipeCostNo, 'RC-001');
      expect(rc.menuItemId, 'm_dish_1');
      expect(rc.menuItemName, 'Paneer Butter Masala');
      expect(rc.ingredients.length, 1);
      expect(rc.ingredients[0].inventoryId, 'inv_paneer');
      expect(rc.ingredients[0].inventoryMaterial, 'Paneer');
      expect(rc.ingredients[0].unit, 'kg');
      expect(rc.ingredients[0].rate, 250.0);
      expect(rc.ingredients[0].unitValue, 0.2);
      expect(rc.ingredients[0].lineCost, 50.0);
      expect(rc.totalPrice, 50.0);
      expect(rc.sellingPrice, 200.0);
      expect(rc.grossMargin, 75.0);
      expect(rc.isActive, true);
    });

    test('RecipeCost parses plain ID response correctly (#80, #83)', () {
      final json = {
        '_id': 'rc_456',
        'organizationId': 'org_123',
        'recipeCostNo': 'RC-002',
        'menuItemId': 'm_dish_2',
        'ingredients': [
          {
            '_id': 'ing_row_2',
            'inventoryId': 'inv_chicken',
            'unit': 'kg',
            'rate': 180.0,
            'unitValue': 0.3,
          },
        ],
        'totalPrice': 54.0,
        'grossMargin': 73.0,
        'sellingPrice': 200.0,
        'isActive': true,
      };

      final rc = RecipeCost.fromJson(json);
      expect(rc.id, 'rc_456');
      expect(rc.menuItemId, 'm_dish_2');
      expect(rc.menuItemName, ''); // Unpopulated
      expect(rc.ingredients[0].inventoryId, 'inv_chicken');
      expect(rc.ingredients[0].inventoryMaterial, ''); // Unpopulated
      expect(rc.ingredients[0].rate, 180.0);
      expect(rc.ingredients[0].unitValue, 0.3);
      expect(rc.totalPrice, 54.0);
    });

    test('toCreateJson never contains totalPrice or grossMargin', () {
      const rc = RecipeCost(
        id: 'rc_1',
        organizationId: 'org_1',
        recipeCostNo: 'RC-001',
        menuItemId: 'm1',
        ingredients: [
          RecipeCostIngredient(
            id: 'ing1',
            inventoryId: 'inv1',
            unit: 'kg',
            rate: 50.0,
            unitValue: 1.0,
          ),
        ],
        totalPrice: 50.0,
        grossMargin: 50.0,
        sellingPrice: 100.0,
        isActive: true,
      );

      final payload = rc.toCreateJson();
      expect(payload.containsKey('totalPrice'), isFalse);
      expect(payload.containsKey('grossMargin'), isFalse);
      expect(payload['menuItemId'], 'm1');
      expect(payload['sellingPrice'], 100.0);
      expect(payload['ingredients'], isA<List>());
    });

    test('recipeCostByMenuItemProvider properly keys active recipes by menuItemId', () async {
      const rc1 = RecipeCost(
        id: 'rc_1',
        organizationId: 'org_1',
        recipeCostNo: 'RC-001',
        menuItemId: 'item_A',
        ingredients: [],
        totalPrice: 40.0,
        grossMargin: 60.0,
        sellingPrice: 100.0,
        isActive: true,
      );
      const rc2 = RecipeCost(
        id: 'rc_2',
        organizationId: 'org_1',
        recipeCostNo: 'RC-002',
        menuItemId: 'item_B',
        ingredients: [],
        totalPrice: 50.0,
        grossMargin: 50.0,
        sellingPrice: 100.0,
        isActive: true,
      );

      final container = ProviderContainer(
        overrides: [
          activeRecipeCostProvider.overrideWith(() => _MockActiveRecipeCostNotifier([rc1, rc2])),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeRecipeCostProvider.future);

      final map = container.read(recipeCostByMenuItemProvider);
      expect(map.containsKey('item_A'), isTrue);
      expect(map['item_A']?.totalPrice, 40.0);
      expect(map.containsKey('item_B'), isTrue);
      expect(map['item_B']?.grossMargin, 50.0);
      expect(map.containsKey('item_C'), isFalse);
    });
  });

  group('Recipe Management Screen Responsive & Overflow Tests', () {
    Widget createTestApp({required Size screenSize, double textScale = 1.0}) {
      const rc = RecipeCost(
        id: 'rc_1',
        organizationId: 'org_1',
        recipeCostNo: 'RC-001',
        menuItemId: 'm1',
        menuItemName: 'Butter Chicken Special with Gravy',
        ingredients: [
          RecipeCostIngredient(
            id: 'i1',
            inventoryId: 'inv1',
            inventoryMaterial: 'Chicken Breast',
            unit: 'kg',
            rate: 200.0,
            unitValue: 0.25,
          ),
        ],
        totalPrice: 50.0,
        grossMargin: 80.0,
        sellingPrice: 250.0,
        isActive: true,
      );

      return ProviderScope(
        overrides: [
          activeRecipeCostProvider.overrideWith(() => _MockActiveRecipeCostNotifier([rc])),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: RecipeManagementScreen(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders cleanly in mobile portrait (360x800)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(createTestApp(screenSize: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Recipes & Food Cost'), findsOneWidget);
      expect(find.text('Recipes Defined'), findsOneWidget);
      expect(find.text('Avg Gross Margin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in mobile landscape (800x360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      await tester.pumpWidget(createTestApp(screenSize: const Size(800, 360)));
      await tester.pumpAndSettle();

      expect(find.text('Recipes & Food Cost'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.5x large accessibility fonts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestApp(screenSize: const Size(400, 800), textScale: 1.5));
      await tester.pumpAndSettle();

      expect(find.text('Recipes & Food Cost'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockActiveRecipeCostNotifier extends ActiveRecipeCostNotifier {
  final List<RecipeCost> initial;
  _MockActiveRecipeCostNotifier(this.initial);

  @override
  Future<List<RecipeCost>> build() async => initial;
}
