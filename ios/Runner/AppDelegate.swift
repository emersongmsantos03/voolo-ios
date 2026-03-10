import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if PREVIEW_STABLE
    // App Preview stability mode: avoid registering plugins that can crash in browser simulator sessions.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    #else
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    #endif
  }
}
