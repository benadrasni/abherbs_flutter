import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var metaAdsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UIApplication.shared.isStatusBarHidden = false

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "sk.ab.herbs/meta_ads",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setAdvertiserTracking" else {
        result(FlutterMethodNotImplemented)
        return
      }
      setMetaAdvertiserTracking(call.arguments as? Bool ?? false)
      result(nil)
    }
    metaAdsChannel = channel
  }
}

/// Audience Network reads this on iOS 16. The adapter is linked by
/// gma_mediation_meta, so the class is present without a direct import.
private func setMetaAdvertiserTracking(_ enabled: Bool) {
  guard let settings = NSClassFromString("FBAdSettings") else { return }
  let selector = NSSelectorFromString("setAdvertiserTrackingEnabled:")
  guard let method = class_getClassMethod(settings, selector) else { return }
  typealias Setter = @convention(c) (AnyClass, Selector, Bool) -> Void
  let setter = unsafeBitCast(method_getImplementation(method), to: Setter.self)
  setter(settings, selector, enabled)
}
