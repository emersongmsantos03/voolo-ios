import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jetx/main.dart' as app;
import 'package:jetx/pages/premium/premium_page.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Finder _firstByTexts(List<String> texts) {
  for (final text in texts) {
    final finder = find.text(text);
    if (finder.evaluate().isNotEmpty) return finder.first;
  }
  return find.byWidget(const SizedBox.shrink());
}

Finder _firstByIcon(IconData icon) {
  final finder = find.byIcon(icon);
  if (finder.evaluate().isNotEmpty) return finder.first;
  return find.byWidget(const SizedBox.shrink());
}

Future<void> _openDrawer(WidgetTester tester) async {
  final menuButton = find.byTooltip('Open navigation menu');
  if (menuButton.evaluate().isNotEmpty) {
    await tester.tap(menuButton.first);
    await _settle(tester);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app store screenshots', (tester) async {
    await app.main();
    await _settle(tester);

    await binding.takeScreenshot('01_dashboard');

    final addButton = _firstByIcon(Icons.add);
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton);
      await _settle(tester);
      await binding.takeScreenshot('02_add_expense');

      final cancelButton = _firstByTexts(['Cancelar', 'Cancel']);
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await _settle(tester);
      }
    }

    await _openDrawer(tester);
    final profileItem = _firstByTexts(['Perfil', 'Profile']);
    if (profileItem.evaluate().isNotEmpty) {
      await tester.tap(profileItem);
      await _settle(tester);
      await binding.takeScreenshot('03_profile');
      await tester.pageBack();
      await _settle(tester);
    }

    final calculatorButton = _firstByIcon(Icons.calculate);
    if (calculatorButton.evaluate().isNotEmpty) {
      await tester.tap(calculatorButton);
      await _settle(tester);
      await binding.takeScreenshot('04_calculator');
      await tester.pageBack();
      await _settle(tester);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: PremiumPage(initialPlan: 'yearly'),
      ),
    );
    await _settle(tester);
    await binding.takeScreenshot('05_premium');
  });
}
