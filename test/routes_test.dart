import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/core/utils/date_utils.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/local_database_service.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/state/locale_state.dart';
import 'package:jetx/state/theme_state.dart';

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
    await DateUtilsJetx.init();

    final tmp = await Directory.systemTemp.createTemp('jetx_routes_test_');
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
            return tmp.path;
        }
        return null;
      },
    );

    await LocalDatabaseService.init();
  });

  testWidgets('All named routes resolve (no unknown route page)',
      (WidgetTester tester) async {
    await LocalStorageService.init();

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeState()),
          ChangeNotifierProvider(create: (_) => LocaleState()),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.dashboard,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    const routeNames = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.resetPassword,
      AppRoutes.onboarding,
      AppRoutes.dashboard,
      AppRoutes.addExpense,
      AppRoutes.investmentCalculator,
      AppRoutes.calculator,
      AppRoutes.goals,
      AppRoutes.monthlyReport,
      AppRoutes.missions,
      AppRoutes.transactions,
      AppRoutes.insights,
      AppRoutes.profile,
      AppRoutes.budgets,
      AppRoutes.investmentPlan,
      AppRoutes.debts,
    ];

    final unknownTitles = <String>[
      // pt-BR
      'Rota não encontrada',
      // en
      'Route not found',
      // es
      'Ruta no encontrada',
    ];

    for (final route in routeNames) {
      navKey.currentState!.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (final t in unknownTitles) {
        expect(find.text(t), findsNothing, reason: 'Missing route: $route');
      }

      if (navKey.currentState!.canPop()) {
        navKey.currentState!.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    navKey.currentState!.pushNamed('${AppRoutes.resetPassword}/token-teste');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final t in unknownTitles) {
      expect(find.text(t), findsNothing, reason: 'Missing dynamic route');
    }
  });

  test('AppRoutes constants all have switch cases', () async {
    final file = File('lib/routes/app_routes.dart');
    expect(await file.exists(), isTrue);
    final src = await file.readAsString();

    final constRe = RegExp(r"static const String\s+(\w+)\s*=\s*'([^']+)';");
    final constants = constRe.allMatches(src).map((m) => m.group(1)!).toList();
    expect(constants, isNotEmpty);

    for (final name in constants) {
      expect(
        src.contains('case $name:'),
        isTrue,
        reason:
            'AppRoutes.$name declared but missing in onGenerateRoute switch',
      );
    }
  });
}
