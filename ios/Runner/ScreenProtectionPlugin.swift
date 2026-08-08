import Flutter
import UIKit

final class ScreenProtectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?
  private var monitoringCount = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ScreenProtectionPlugin()
    let channel = FlutterMethodChannel(
      name: "com.rshd/screen_protection",
      binaryMessenger: registrar.messenger()
    )
    let events = FlutterEventChannel(
      name: "com.rshd/screen_protection/events",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
    events.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enableSecure":
      startMonitoring()
      result(nil)
    case "disableSecure":
      stopMonitoring()
      result(nil)
    case "isScreenCaptured":
      result(UIScreen.main.isCaptured)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    sendCaptureState()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func startMonitoring() {
    monitoringCount += 1
    guard monitoringCount == 1 else { return }

    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.sendCaptureState()
    }

    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.eventSink?(["type": "screenshot_taken"])
    }

    sendCaptureState()
  }

  private func stopMonitoring() {
    monitoringCount = max(0, monitoringCount - 1)
    guard monitoringCount == 0 else { return }

    if let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
      self.captureObserver = nil
    }
    if let screenshotObserver {
      NotificationCenter.default.removeObserver(screenshotObserver)
      self.screenshotObserver = nil
    }
  }

  private func sendCaptureState() {
    guard eventSink != nil else { return }
    let type = UIScreen.main.isCaptured ? "capture_started" : "capture_ended"
    eventSink?(["type": type])
  }
}
