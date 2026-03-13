import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var isPreviewStableMode: Bool {
    let value = Bundle.main.object(forInfoDictionaryKey: "PREVIEW_STABLE_MODE")
    return (value as? NSNumber)?.boolValue == true || (value as? Bool) == true
  }

  private func configureBootstrapChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "voolo/bootstrap",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(false)
        return
      }

      switch call.method {
      case "isPreviewStableMode":
        result(self.isPreviewStableMode)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinishLaunching = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    if !isPreviewStableMode {
      GeneratedPluginRegistrant.register(with: self)
    }
    configureBootstrapChannel()
    return didFinishLaunching
  }
}
