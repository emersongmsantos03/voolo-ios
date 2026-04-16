import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir = Platform.environment['SCREENSHOTS_DIR']?.trim();
  final targetDir = (outputDir == null || outputDir.isEmpty)
      ? 'build/screenshots'
      : outputDir;

  await integrationDriver(
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      final directory = Directory(targetDir);
      await directory.create(recursive: true);
      final file = File('${directory.path}/$screenshotName.png');
      await file.writeAsBytes(screenshotBytes, flush: true);
      return true;
    },
  );
}
