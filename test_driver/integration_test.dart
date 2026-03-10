import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final screenshotDir = Platform.environment['SCREENSHOTS_DIR']?.trim().isNotEmpty == true
      ? Platform.environment['SCREENSHOTS_DIR']!.trim()
      : 'build/screenshots';

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$screenshotDir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
