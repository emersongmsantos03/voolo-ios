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
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
