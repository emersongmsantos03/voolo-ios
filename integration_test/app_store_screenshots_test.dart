import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jetx/main.dart' as app;
import 'package:jetx/routes/app_routes.dart';

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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app store screenshots', (tester) async {
    app.main();
    await _settle(tester);

    await binding.takeScreenshot('01_login');

    final registerCta =
        _firstByTexts(['Cadastre-se', 'Criar conta', 'Cadastrar', 'Register']);
    if (registerCta.evaluate().isNotEmpty) {
      await tester.tap(registerCta);
      await _settle(tester);
      await binding.takeScreenshot('02_register');
      final back = _firstByTexts(['Back', 'Voltar']);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await _settle(tester);
      }
    } else {
      await binding.takeScreenshot('02_login_fallback');
    }

    final forgotPassword = _firstByTexts([
      'Esqueci minha senha',
      'Recuperar senha',
      'Forgot password',
    ]);
    if (forgotPassword.evaluate().isNotEmpty) {
      await tester.tap(forgotPassword);
      await _settle(tester);
      await binding.takeScreenshot('03_forgot_password');
    } else {
      await binding.takeScreenshot('03_login_alt');
    }

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(
      AppRoutes.premium,
      arguments: {'plan': 'yearly'},
    );
    await _settle(tester);
    await binding.takeScreenshot('04_premium_paywall');
  });
}
