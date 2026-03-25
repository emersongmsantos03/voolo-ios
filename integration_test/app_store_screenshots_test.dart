import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jetx/main.dart' as app;
import 'package:jetx/models/user_profile.dart';
import 'package:jetx/pages/premium/premium_page.dart';
import 'package:jetx/services/local_storage_service.dart';

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

Future<void> _seedLoginAccount() async {
  await LocalStorageService.createAccount(
    UserProfile(
      firstName: 'Emerson',
      lastName: 'Moraes',
      email: 'preview@voolo.com.br',
      password: 'Voolo123!',
      profession: 'Analista financeiro',
      monthlyIncome: 7200,
      gender: 'Nao informado',
      objectives: const [
        'objective_save',
        'objective_invest',
        'objective_security',
      ],
      setupCompleted: true,
      isPremium: true,
      isActive: true,
      propertyValue: 320000,
      investBalance: 28000,
    ),
  );
}

Future<void> _loginWithSeededAccount(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'preview@voolo.com.br');
  await tester.enterText(fields.at(1), 'Voolo123!');
  await _settle(tester);

  final loginButton = find.byType(ElevatedButton).first;
  await tester.tap(loginButton);
  await _settle(tester);
  await tester.pumpAndSettle(const Duration(seconds: 3));
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

    await binding.takeScreenshot('01_login');

    await _seedLoginAccount();
    await _loginWithSeededAccount(tester);
    await binding.takeScreenshot('02_dashboard');

    final addButton = _firstByIcon(Icons.add);
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton);
      await _settle(tester);
      await binding.takeScreenshot('03_add_expense');

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
      await binding.takeScreenshot('04_profile');
      await tester.pageBack();
      await _settle(tester);
    }

    final calculatorButton = _firstByIcon(Icons.calculate);
    if (calculatorButton.evaluate().isNotEmpty) {
      await tester.tap(calculatorButton);
      await _settle(tester);
      await binding.takeScreenshot('05_calculator');
      await tester.pageBack();
      await _settle(tester);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: PremiumPage(initialPlan: 'yearly'),
      ),
    );
    await _settle(tester);
    await binding.takeScreenshot('06_premium');
  });
}
