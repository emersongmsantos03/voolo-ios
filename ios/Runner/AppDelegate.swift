import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var isPreviewStableMode: Bool {
    let value = Bundle.main.object(forInfoDictionaryKey: "PREVIEW_STABLE_MODE")
    return (value as? NSNumber)?.boolValue == true || (value as? Bool) == true
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if isPreviewStableMode {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
