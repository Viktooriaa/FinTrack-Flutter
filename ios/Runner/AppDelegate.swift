import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    ReceiptCapturePlugin.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "ReceiptCapturePlugin")
    )
  }
}

private final class ReceiptCapturePlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let registrar: FlutterPluginRegistrar
  private var pendingResult: FlutterResult?

  private init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "fintrack/receipt_capture",
      binaryMessenger: registrar.messenger()
    )
    let instance = ReceiptCapturePlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "capture" || call.method == "gallery" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pendingResult == nil else {
      result(FlutterError(code: "busy", message: "A receipt image request is already active.", details: nil))
      return
    }
    let source: UIImagePickerController.SourceType = call.method == "capture" ? .camera : .photoLibrary
    guard UIImagePickerController.isSourceTypeAvailable(source) else {
      result(FlutterError(code: "unavailable", message: "This image source is not available.", details: nil))
      return
    }
    guard let viewController = registrar.viewController() else {
      result(FlutterError(code: "unavailable", message: "The app window is not available.", details: nil))
      return
    }

    let picker = UIImagePickerController()
    picker.sourceType = source
    picker.delegate = self
    pendingResult = result
    viewController.present(picker, animated: true)
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let bytes = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.84)
    picker.dismiss(animated: true) { [weak self] in
      self?.pendingResult?(bytes)
      self?.pendingResult = nil
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) { [weak self] in
      self?.pendingResult?(nil)
      self?.pendingResult = nil
    }
  }
}
