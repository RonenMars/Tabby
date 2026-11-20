import UIKit
import Flutter
import AVFAudio

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    } catch {
      NSLog("Unable to configure Tabby audio session: %@", error.localizedDescription)
    }
    dummyMethodToEnforceBundling();
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // With the UIScene life cycle, the FlutterViewController only exists once the scene
  // connects, and FlutterAppDelegate reaches its engine through `window`. A launch URL
  // also arrives with the scene instead of in launchOptions, so forward it to plugins here.
  func sceneWillConnect(window: UIWindow?, launchURL: URL?) {
    self.window = window
    GeneratedPluginRegistrant.register(with: self)
    var launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]
    if let launchURL = launchURL {
      launchOptions[.url] = launchURL
    }
    _ = super.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
  }
    
  public func dummyMethodToEnforceBundling() {
      dummy_method_to_enforce_bundling();
    session_get_rgba(nil, 0);
  }
}
