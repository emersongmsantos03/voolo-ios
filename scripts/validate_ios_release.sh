#!/bin/sh
set -eu

echo "Validating iOS release configuration..."

require_file() {
  if [ ! -f "$1" ]; then
    echo "ERROR: Missing required file: $1"
    exit 1
  fi
}

require_match() {
  pattern="$1"
  file="$2"
  if ! grep -F -- "$pattern" "$file" >/dev/null 2>&1; then
    echo "ERROR: Expected pattern not found in $file"
    echo "Pattern: $pattern"
    exit 1
  fi
}

require_file "ios/Runner/Info.plist"
require_file "ios/Runner/GoogleService-Info.plist"
require_file "ios/Runner/PrivacyInfo.xcprivacy"
require_file "ios/Runner.xcodeproj/project.pbxproj"
require_file "codemagic.yaml"
require_file "integration_test/app_store_screenshots_test.dart"
require_file "test_driver/integration_test.dart"

require_match "<key>NSPhotoLibraryUsageDescription</key>" "ios/Runner/Info.plist"
require_match "<key>NSFaceIDUsageDescription</key>" "ios/Runner/Info.plist"
require_match "<key>ITSAppUsesNonExemptEncryption</key>" "ios/Runner/Info.plist"
require_match "<string>com.googleusercontent.apps.100666481363-r1nvlcji3h8nc72i3abnfjhkmin2s5ed</string>" "ios/Runner/Info.plist"
require_match "<key>BUNDLE_ID</key>" "ios/Runner/GoogleService-Info.plist"
require_match "<string>com.voolo.jetx</string>" "ios/Runner/GoogleService-Info.plist"
require_match "PRODUCT_BUNDLE_IDENTIFIER = com.voolo.jetx;" "ios/Runner.xcodeproj/project.pbxproj"
require_match 'MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";' "ios/Runner.xcodeproj/project.pbxproj"
require_match 'CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";' "ios/Runner.xcodeproj/project.pbxproj"
require_match "PrivacyInfo.xcprivacy" "ios/Runner.xcodeproj/project.pbxproj"
require_match "https://voolo-ad416.web.app/auth/reset" "lib/core/constants/auth_links.dart"
require_match "deleteCurrentAccount" "lib/services/local_storage_service.dart"
require_match "deleteUserAccount" "lib/services/firestore_service.dart"
require_match "integration_test:" "pubspec.yaml"
require_match "FIREBASE_IOS_PLIST_BASE64" "codemagic.yaml"
require_match "integration_test/app_store_screenshots_test.dart" "codemagic.yaml"
require_match "test_driver/integration_test.dart" "codemagic.yaml"

if grep -F "<key>NSCameraUsageDescription</key>" ios/Runner/Info.plist >/dev/null 2>&1; then
  if ! grep -R "ImageSource.camera" lib >/dev/null 2>&1; then
    echo "ERROR: NSCameraUsageDescription is declared, but no camera usage was found in lib/."
    exit 1
  fi
fi

echo "iOS release validation passed."
