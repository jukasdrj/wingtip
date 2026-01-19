import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appGroupId = "group.com.ooheynerds.wingtip"
  private let widgetDataKey = "widget_data"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup widget method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "com.ooheynerds.wingtip/widget",
        binaryMessenger: controller.binaryMessenger
      )

      widgetChannel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else {
          result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate unavailable", details: nil))
          return
        }

        switch call.method {
        case "updateWidgetData":
          if let args = call.arguments as? [String: Any],
             let dataString = args["data"] as? String {
            self.updateWidgetData(dataString)
            result(nil)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          }

        case "reloadWidgets":
          self.reloadWidgets()
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Update widget data in App Group shared UserDefaults
  private func updateWidgetData(_ jsonData: String) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("[AppDelegate] Failed to access App Group UserDefaults")
      return
    }

    userDefaults.set(jsonData, forKey: widgetDataKey)
    userDefaults.synchronize()
    print("[AppDelegate] Widget data updated")
  }

  /// Reload all widgets
  private func reloadWidgets() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
      print("[AppDelegate] Widgets reloaded")
    }
  }

  /// Handle URL scheme for deep linking from widget
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Handle wingtip:// URL scheme
    if url.scheme == "wingtip" {
      // Route to library view
      // This will be handled by Flutter's router
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
