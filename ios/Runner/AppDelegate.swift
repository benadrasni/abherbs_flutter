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

    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
    // The plugin keeps a token it already stored. This covers the case
    // where it has not handed the token to Firebase yet.
    assignApnsToken(deviceToken)
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

/// iPad scene delegate. iPadOS 26 can turn the device without resizing the
/// scene, which leaves the portrait layout drawn sideways. Ask the scene to
/// adopt the device orientation. The phone stays portrait.
@objc(GuideSceneDelegate)
class GuideSceneDelegate: FlutterSceneDelegate {
  private static var observingOrientation = false

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if !Self.observingOrientation {
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
      Self.observingOrientation = true
    }
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name.UIDeviceOrientationDidChange,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(guideDeviceOrientationDidChange),
      name: Notification.Name.UIDeviceOrientationDidChange,
      object: nil
    )
    guideAlignInterface(of: scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    guideAlignInterface(of: scene)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name.UIDeviceOrientationDidChange,
      object: nil
    )
    super.sceneDidDisconnect(scene)
  }

  @available(iOS 27.0, *)
  override func supportedInterfaceOrientations(for windowScene: UIWindowScene) -> UIInterfaceOrientationMask {
    UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
  }

  @objc private func guideDeviceOrientationDidChange() {
    for scene in UIApplication.shared.connectedScenes {
      guideAlignInterface(of: scene)
    }
  }

  private func guideAlignInterface(of scene: UIScene) {
    guard UIDevice.current.userInterfaceIdiom == .pad,
          let windowScene = scene as? UIWindowScene,
          let desired = guideDesiredInterfaceOrientation()
    else {
      return
    }
    let current: UIInterfaceOrientation
    if #available(iOS 26.0, *) {
      current = windowScene.effectiveGeometry.interfaceOrientation
    } else {
      current = windowScene.interfaceOrientation
    }
    guard current != desired else { return }
    let preferences = UIWindowScene.GeometryPreferences.iOS()
    preferences.interfaceOrientations = UIInterfaceOrientationMask(rawValue: 1 << desired.rawValue)
    windowScene.requestGeometryUpdate(preferences) { error in
      NSLog("GuideSceneDelegate geometry update failed: %@", error.localizedDescription)
    }
  }

  /// Device landscape is the opposite interface orientation.
  private func guideDesiredInterfaceOrientation() -> UIInterfaceOrientation? {
    switch UIDevice.current.orientation {
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    default:
      return nil
    }
  }
}

/// Hands the APNs token to Firebase with the profile's environment.
/// `FIRMessaging` is linked by firebase_messaging. The default app is
/// missing until Dart finishes `Firebase.initializeApp`.
private func assignApnsToken(_ deviceToken: Data) {
  guard let appClass = NSClassFromString("FIRApp") else { return }
  let defaultApp = NSSelectorFromString("defaultApp")
  guard let appMethod = class_getClassMethod(appClass, defaultApp),
        let configured = unsafeBitCast(
          method_getImplementation(appMethod),
          to: (@convention(c) (AnyClass, Selector) -> AnyObject?).self
        )(appClass, defaultApp)
  else {
    return
  }
  _ = configured
  guard let messagingClass = NSClassFromString("FIRMessaging") else { return }
  let shared = NSSelectorFromString("messaging")
  guard let messagingMethod = class_getClassMethod(messagingClass, shared),
        let messaging = unsafeBitCast(
          method_getImplementation(messagingMethod),
          to: (@convention(c) (AnyClass, Selector) -> NSObject?).self
        )(messagingClass, shared)
  else {
    return
  }
  messaging.setValue(deviceToken, forKey: "APNSToken")
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
