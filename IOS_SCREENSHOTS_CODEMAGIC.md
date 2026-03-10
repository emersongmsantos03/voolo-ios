# iOS Screenshots via Codemagic

## Available workflows
- `ios-screenshots`: automatic screenshot generation (artifact `.png`).
- `ios-app-preview`: builds simulator `.app` so you can use Codemagic **Quick Launch** in browser.

## Workflow
- Use the workflow: `ios-screenshots`
- It runs on an iOS simulator (`iPhone 15 Pro Max`) and saves PNG files in:
  - `build/screenshots/iphone_69`

## What this workflow does
1. Runs `flutter pub get`
2. Boots the iOS simulator
3. Executes integration test:
   - `integration_test/app_store_screenshots_test.dart`
4. Exports screenshots as build artifacts

## Files added for screenshot automation
- `integration_test/app_store_screenshots_test.dart`
- `test_driver/integration_test.dart`

## App Store Connect upload
1. Download artifacts from Codemagic build.
2. Open App Store Connect > Your App > iOS App > App Preview and Screenshots.
3. Upload the generated `.png` files for iPhone.

## Browser testing with App Preview
1. Run workflow `ios-app-preview`.
2. Open build artifacts and click **Quick Launch** next to the generated `.app`.
3. Test and navigate the app in-browser on iOS simulator.
4. Use this mainly for validation/demo; for App Store upload prefer PNGs from `ios-screenshots`.

## Notes
- The app runs with `SCREENSHOT_MODE=true` during screenshot generation.
- This mode avoids Firebase startup dependency and opens real app UI screens for capture.
