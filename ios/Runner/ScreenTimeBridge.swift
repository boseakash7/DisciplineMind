import Flutter
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings

@available(iOS 16.0, *)
final class ScreenTimeBridge: NSObject, FlutterPlugin {
  private let store = ManagedSettingsStore()
  private let savedKey = "zeno.screenTime.selection"
  private var pickerResult: FlutterResult?
  private var pickerController: UIViewController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screen_time", binaryMessenger: registrar.messenger())
    let instance = ScreenTimeBridge()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } catch { result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil)) }
      }
    case "isAuthorized":
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    case "hasSelectedApps":
      result(!loadSelection().applicationTokens.isEmpty || !loadSelection().categoryTokens.isEmpty)
    case "showAppPicker":
      DispatchQueue.main.async { self.showPicker(result: result) }
    case "enableRestrictions", "blockSelectedApps", "blockApp":
      guard AuthorizationCenter.shared.authorizationStatus == .approved else {
        result(false)
        return
      }
      let selection = loadSelection()
      guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
        result(false)
        return
      }
      store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
      store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
      result(true)
    case "unblockAll", "unblockApp":
      store.clearAllSettings()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadSelection() -> FamilyActivitySelection {
    guard let data = UserDefaults.standard.data(forKey: savedKey),
          let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
      return FamilyActivitySelection()
    }
    return selection
  }

  @MainActor private func showPicker(result: @escaping FlutterResult) {
    guard pickerResult == nil else { result(FlutterError(code: "PICKER_BUSY", message: "Picker already open", details: nil)); return }
    guard AuthorizationCenter.shared.authorizationStatus == .approved else { result(false); return }
    guard let root = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "NO_VIEW", message: "No active iOS window", details: nil)); return
    }
    pickerResult = result
    let picker = ScreenTimePickerView(initial: loadSelection(), onSave: { [weak self] selection in
      guard let self = self else { return }
      if let data = try? PropertyListEncoder().encode(selection) { UserDefaults.standard.set(data, forKey: self.savedKey) }
      self.finishPicker(!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty)
    }, onCancel: { [weak self] in self?.finishPicker(false) })
    let controller = UIHostingController(rootView: picker)
    pickerController = controller
    (root.presentedViewController ?? root).present(controller, animated: true)
  }

  @MainActor private func finishPicker(_ selected: Bool) {
    let callback = pickerResult
    pickerResult = nil
    pickerController?.dismiss(animated: true) { callback?(selected) }
    pickerController = nil
  }
}

@available(iOS 16.0, *)
private struct ScreenTimePickerView: View {
  @State var selection: FamilyActivitySelection
  let onSave: (FamilyActivitySelection) -> Void
  let onCancel: () -> Void
  init(initial: FamilyActivitySelection, onSave: @escaping (FamilyActivitySelection) -> Void, onCancel: @escaping () -> Void) {
    _selection = State(initialValue: initial)
    self.onSave = onSave
    self.onCancel = onCancel
  }
  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Select Apps")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
          ToolbarItem(placement: .confirmationAction) { Button("Done") { onSave(selection) } }
        }
    }
  }
}
