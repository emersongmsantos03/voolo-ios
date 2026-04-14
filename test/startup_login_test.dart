import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jetx/core/utils/date_utils.dart';
import 'package:jetx/services/local_database_service.dart';
import 'package:jetx/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
    await DateUtilsJetx.init();

    final tmp = await Directory.systemTemp.createTemp('jetx_startup_test_');
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

  test('Fresh install does not auto-open the demo account', () async {
    LocalStorageService.configureCloud(enabled: false);
    await LocalStorageService.init();

    expect(LocalStorageService.getAccounts(), isNotEmpty);
    expect(LocalStorageService.getUserProfile(), isNull);
  });
}
