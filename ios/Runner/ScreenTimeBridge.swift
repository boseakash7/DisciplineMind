import Flutter
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings

@available(iOS 16.0, *)
final class ScreenTimeBridge: NSObject, FlutterPlugin {
  private var store: ManagedSettingsStore { MarketGuard.store }
  private let savedKey = "zeno.screenTime.selection"
  private var authorizationResults: [FlutterResult] = []
  private var pickerResult: FlutterResult?
  private var pickerController: UIViewController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screen_time", binaryMessenger: registrar.messenger())
    let instance = ScreenTimeBridge()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getGuardUsageStats":
      result(AppUsageTracker.snapshot())
    case "syncGuardState":
      guard let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String,
            let state = args["state"] as? String,
            let tradeId = args["tradeId"] as? String else {
        result(FlutterError(code: "INVALID_GUARD_STATE", message: "Invalid guard state payload", details: nil))
        return
      }
      if MarketGuard.defaults.string(forKey: "guardStateUserId") != userId {
        MarketGuard.endTemporaryAccess()
        _ = MarketGuard.updateBackendState("")
      }
      MarketGuard.defaults.set(userId, forKey: "guardStateUserId")
      MarketGuard.defaults.set(tradeId, forKey: "guardTradeId")
      MarketGuard.defaults.set(Date().timeIntervalSince1970, forKey: "guardStateUpdatedAt")
      if MarketGuard.updateBackendState(state) {
        result(nil)
      } else {
        result(FlutterError(code: "GUARD_ACCESS_SCHEDULE_FAILED", message: "Could not register restoration for server-authorized access.", details: nil))
      }
    case "requestPermission":
      if MarketGuard.isAuthorized { result(true); return }
      authorizationResults.append(result)
      guard authorizationResults.count == 1 else { return }
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          let callbacks = self.authorizationResults
          self.authorizationResults.removeAll()
          callbacks.forEach { $0(MarketGuard.isAuthorized) }
        } catch {
          let callbacks = self.authorizationResults
          self.authorizationResults.removeAll()
          callbacks.forEach { $0(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil)) }
        }
      }
    case "consumeGuardChatRequest":
      let pending = MarketGuard.defaults.bool(forKey: "openGuardChat")
      MarketGuard.defaults.removeObject(forKey: "openGuardChat")
      result(pending)
    case "isAuthorized":
      result(MarketGuard.isAuthorized)
    case "hasSelectedApps":
      result(!loadSelection().applicationTokens.isEmpty)
    case "showAppPicker":
      DispatchQueue.main.async { self.showPicker(result: result) }
    case "restoreRestrictionsAfterSkip":
      MarketGuard.endTemporaryAccess()
      result(MarketGuard.apply())
    case "allowSelectedAppsTemporarily":
      result(MarketGuard.allowTemporaryAccess(to: loadSelection().applicationTokens))
    case "enableRestrictions", "blockSelectedApps", "blockApp":
      MarketGuard.endTemporaryAccess()
      guard MarketGuard.isAuthorized else {
        result(FlutterError(code: "GUARD_NOT_AUTHORIZED", message: "Allow Zeno Screen Time access in Settings.", details: nil))
        return
      }
      let selection = loadSelection()
      guard !selection.applicationTokens.isEmpty else {
        result(FlutterError(code: "GUARD_NO_APPS", message: "Select the trading app in Apple's picker.", details: nil))
        return
      }
      do {
        let data = try PropertyListEncoder().encode(selection)
        MarketGuard.defaults.set(data, forKey: savedKey)
      } catch {
        result(FlutterError(code: "GUARD_SAVE_FAILED", message: error.localizedDescription, details: nil))
        return
      }
      // Re-enabling after unblockAll must restore the same protection policy
      // as saving the picker. Otherwise the retained false priority flag lets
      // a cached server "unlocked" response immediately remove this shield.
      MarketGuard.defaults.set(true, forKey: "guardExplicitProtection")
      _ = MarketGuard.updateBackendState("")
      // Refresh is best effort: keep the existing pre-launch flow usable if
      // iOS cannot refresh a token. Diagnostics retain the failure for repair.
      _ = MarketGuard.refreshSelectedApps()
      let configured = MarketGuard.start()
      NSLog("[MindControlGuard] configured=%@ authorized=%@ selectedApps=%ld", String(configured), String(MarketGuard.isAuthorized), MarketGuard.selection.applicationTokens.count)
      if configured {
        result(true)
      } else {
        result(FlutterError(code: "GUARD_CONFIGURATION_FAILED", message: MarketGuard.defaults.string(forKey: "guardMonitoringError") ?? "iOS did not retain the requested shield configuration.", details: nil))
      }
    case "unblockAll", "unblockApp":
      MarketGuard.defaults.set(false, forKey: "guardExplicitProtection")
      for key in ["guardBackendState", "guardTradeId", "guardStateUpdatedAt", "guardStateUserId", "guardBackendAccessExpiresAt"] {
        MarketGuard.defaults.removeObject(forKey: key)
      }
      MarketGuard.defaults.set(false, forKey: "enabled")
      MarketGuard.endTemporaryAccess()
      MarketGuard.center.stopMonitoring()
      store.clearAllSettings()
      ManagedSettingsStore().clearAllSettings()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadSelection() -> FamilyActivitySelection {
    guard let data = (MarketGuard.defaults.data(forKey: savedKey) ?? UserDefaults.standard.data(forKey: savedKey)),
          let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
      return FamilyActivitySelection()
    }
    return selection
  }

  @MainActor private func showPicker(result: @escaping FlutterResult) {
    guard pickerResult == nil else { result(FlutterError(code: "PICKER_BUSY", message: "Picker already open", details: nil)); return }
    guard MarketGuard.isAuthorized else { result(false); return }
    guard let root = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "NO_VIEW", message: "No active iOS window", details: nil)); return
    }
    pickerResult = result
    // Preserve the approved broker when revisiting Settings. The review step
    // still confirms the exact single app before saving a broker change.
    let picker = ScreenTimePickerView(initial: loadSelection(), onSave: { [weak self] selection in
      guard let self = self else { return }
      guard selection.applicationTokens.count == 1 else { return }
      do {
        let data = try PropertyListEncoder().encode(selection)
        MarketGuard.defaults.set(data, forKey: self.savedKey)
        guard self.loadSelection().applicationTokens == selection.applicationTokens else {
          self.finishPicker(false, error: "Could not read back the saved app selection.")
          return
        }
        // Explicit protection chosen in Settings outranks background server
        // allowances until the user disables protection. Native Skip remains
        // a bounded, separate exemption.
        MarketGuard.defaults.set(true, forKey: "guardExplicitProtection")
        MarketGuard.endTemporaryAccess()
        _ = MarketGuard.updateBackendState("")
        guard MarketGuard.start() else {
          self.finishPicker(false, error: MarketGuard.defaults.string(forKey: "guardMonitoringError") ?? "Could not configure native protection. Please retry.")
          return
        }
        self.finishPicker(true)
      } catch {
        self.finishPicker(false, error: error.localizedDescription)
      }
    }, onCancel: { [weak self] in self?.finishPicker(false) })
    let controller = UIHostingController(rootView: picker)
    // Avoid an interactive dismissal leaving Flutter's picker Future pending.
    controller.isModalInPresentation = true
    pickerController = controller
    (root.presentedViewController ?? root).present(controller, animated: true)
  }

  @MainActor private func finishPicker(_ selected: Bool, error: String? = nil) {
    let callback = pickerResult
    pickerResult = nil
    pickerController?.dismiss(animated: true) {
      if let error = error {
        callback?(FlutterError(code: "GUARD_SAVE_FAILED", message: error, details: nil))
      } else {
        callback?(selected)
      }
    }
    pickerController = nil
  }
}

@available(iOS 16.0, *)
private struct ScreenTimePickerView: View {
  @State var selection: FamilyActivitySelection
  @State private var reviewingSelection = false
  let onSave: (FamilyActivitySelection) -> Void
  let onCancel: () -> Void
  init(initial: FamilyActivitySelection, onSave: @escaping (FamilyActivitySelection) -> Void, onCancel: @escaping () -> Void) {
    _selection = State(initialValue: initial)
    self.onSave = onSave
    self.onCancel = onCancel
  }
  var body: some View {
    NavigationView {
      Group {
        if reviewingSelection {
          List {
            Section(header: Text("Protect this trading app")) {
              ForEach(Array(selection.applicationTokens), id: \.self) { token in
                Label(token)
              }
            }
            Section {
              Text("Select only the same broker you chose during onboarding. Only this app receives Mind Control Guard.")
              if selection.applicationTokens.count != 1 {
                Text("Choose exactly one trading app.").foregroundColor(.red)
              }
              Button("Enable native guard") { onSave(selection) }
                .disabled(selection.applicationTokens.count != 1)
              Button("Change selected app") { reviewingSelection = false }
            }
          }
        } else {
          FamilyActivityPicker(selection: $selection)
        }
      }
        .navigationTitle("Select Trading App")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
          ToolbarItem(placement: .confirmationAction) {
            if !reviewingSelection {
              Button("Review") { reviewingSelection = true }
                .disabled(selection.applicationTokens.isEmpty)
            }
          }
        }
    }
  }
}
