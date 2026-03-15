// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:jetx/core/utils/date_utils.dart';
import 'package:jetx/pages/dashboard/dashboard_page.dart';
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

    final tmp = await Directory.systemTemp.createTemp('jetx_test_');
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
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

  testWidgets('App starts on dashboard screen', (WidgetTester tester) async {
    await LocalStorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeState()),
          ChangeNotifierProvider(create: (_) => LocaleState()),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
