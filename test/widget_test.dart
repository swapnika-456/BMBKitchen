import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/main.dart';

void main() {
  testWidgets('BmbKitchenApp boots to Dashboard screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BmbKitchenApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dashboard'), findsWidgets);
  });
}
