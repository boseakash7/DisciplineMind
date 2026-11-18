import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

enum MarketGuard {
  static let defaults = UserDefaults(suiteName: "group.com.discipline.mind.guard")!
  static let selectionKey = "zeno.screenTime.selection"
  static let center = DeviceActivityCenter()
  static let protectionActivity = DeviceActivityName("zeno-standalone-protection")
  static let backendAccessActivity = DeviceActivityName("zeno-backend-access")
  // iOS cannot poll foreground applications like Android. Bound a cached
  // server allowance and register restoration before removing the shield.
  static func updateBackendState(_ state: String) -> Bool {
    let normalized = state.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    if normalized == "unlocked" && !defaults.bool(forKey: "guardExplicitProtection") {
      let now = Date()
      let expiresAt = now.addingTimeInterval(16 * 60)
      let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
      do {
        try center.startMonitoring(backendAccessActivity, during: DeviceActivitySchedule(
          intervalStart: Calendar.current.dateComponents(parts, from: now),
          intervalEnd: Calendar.current.dateComponents(parts, from: expiresAt), repeats: false))
      } catch {
        defaults.set(error.localizedDescription, forKey: "guardBackendAccessError")
        return false
      }
      defaults.set(expiresAt.timeIntervalSince1970, forKey: "guardBackendAccessExpiresAt")
    } else {
      defaults.removeObject(forKey: "guardBackendAccessExpiresAt")
      center.stopMonitoring([backendAccessActivity])
    }
    defaults.set(normalized, forKey: "guardBackendState")
    defaults.removeObject(forKey: "guardBackendAccessError")
    restoreSavedProtection()
    return true
  }
  static var isAuthorized: Bool {
    let status = AuthorizationCenter.shared.authorizationStatus
    if #available(iOS 26.4, *), status == .approvedWithDataAccess { return true }
    return status == .approved
  }
  // Named stores are shared by the app, ShieldAction, and monitor processes.
  static let store: ManagedSettingsStore = {
    if #available(iOS 16.0, *) {
      return ManagedSettingsStore(named: .init("zeno-mind-control-guard"))
    }
    return ManagedSettingsStore()
  }()
  static func restoreSavedProtection() {
    guard defaults.bool(forKey: "enabled") else { return }
    // Enabled installations have opted into protection. Older re-enable paths
    // could retain false from unblockAll; repair that inconsistent saved state
    // even when Flutter's bootstrap does not run. Native Skip remains separate.
    if !defaults.bool(forKey: "guardExplicitProtection") {
      defaults.set(true, forKey: "guardExplicitProtection")
      defaults.removeObject(forKey: "guardBackendAccessExpiresAt")
      center.stopMonitoring([backendAccessActivity])
    }
    apply()
  }
  static let skipEvent = DeviceActivityEvent.Name("guard-skip-used")
  private static let skipKey = "guardTemporaryAccess"
  private struct TemporaryAccess: Codable {
    let applications: Set<ApplicationToken>
    let activityName: String
    let expiresAt: Date
  }
  private static var temporaryAccess: TemporaryAccess? {
    guard let data = defaults.data(forKey: skipKey) else { return nil }
    return try? PropertyListDecoder().decode(TemporaryAccess.self, from: data)
  }
  static var selection: FamilyActivitySelection {
    guard let data = defaults.data(forKey: selectionKey),
          let value = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    else { return FamilyActivitySelection() }
    return value
  }
  @discardableResult
  static func apply(authorizedShieldAction: Bool = false) -> Bool {
    let store = self.store
    let authorized = authorizedShieldAction || isAuthorized
    let enabled = defaults.bool(forKey: "enabled")
    let tokens = selection.applicationTokens
    let backendAllowsAccess = !defaults.bool(forKey: "guardExplicitProtection")
      && defaults.string(forKey: "guardBackendState") == "unlocked"
      && defaults.double(forKey: "guardBackendAccessExpiresAt") > Date().timeIntervalSince1970
    let shouldShield = enabled && authorized && !tokens.isEmpty && !backendAllowsAccess
    // Managed Settings persists this restriction while Zeno is suspended or
    // terminated. Keep it applied outside market hours as well.
    var shieldedTokens = tokens
    if let access = temporaryAccess, access.expiresAt > Date() {
      shieldedTokens.subtract(access.applications)
    }
    store.shield.applications = shouldShield ? shieldedTokens : nil
    store.shield.applicationCategories = nil
    if #available(iOS 26.5, *) {
      // An inactive store can retain settings without enforcing them.
      store.isActive = enabled && authorized
    }
    if #available(iOS 16.0, *) {
      // Migrate only the shields owned by this process's legacy default store.
      // Do this after configuring the shared store to avoid an unlock gap.
      let legacy = ManagedSettingsStore()
      legacy.shield.applications = nil
      legacy.shield.applicationCategories = nil
    }
    // No app identifiers or tokens: record only the state needed to diagnose
    // why a real device did or did not receive its shield.
    var diagnostics: [String: Any] = [
      "checkedAt": ISO8601DateFormatter().string(from: Date()),
      "authorized": authorized,
      "enabled": enabled,
      "backendAllowsAccess": backendAllowsAccess,
      "explicitProtection": defaults.bool(forKey: "guardExplicitProtection"),
      "selectedAppCount": tokens.count,
      "configuredShieldAppCount": store.shield.applications?.count ?? 0,
      "scheduleCount": center.activities.count,
      "store": "zeno-mind-control-guard",
      "temporaryAccessActive": temporaryAccess.map { $0.expiresAt > Date() } ?? false,
      "tokenRefreshStatus": defaults.string(forKey: "guardTokenRefreshStatus") ?? "notAttempted"
    ]
    if #available(iOS 26.5, *) {
      diagnostics["storeActive"] = store.isActive
    }
    defaults.set(diagnostics, forKey: "guardDiagnostics")
    // A confirmed server allowance is also a successfully configured policy.
    return enabled && authorized && !tokens.isEmpty &&
      store.shield.applications == (shouldShield ? shieldedTokens : nil)
  }
  static func refreshSelectedApps() -> Bool {
    guard #available(iOS 26.5, *) else { return true }
    var selected = selection
    guard !selected.applicationTokens.isEmpty else { return false }
    var tokens = Array(selected.applicationTokens)
    do {
      try ManagedSettingsStore.refresh(&tokens)
      guard !tokens.isEmpty else {
        defaults.set("empty", forKey: "guardTokenRefreshStatus")
        return false
      }
      selected.applicationTokens = Set(tokens)
      let data = try PropertyListEncoder().encode(selected)
      defaults.set(data, forKey: selectionKey)
      defaults.set("refreshed", forKey: "guardTokenRefreshStatus")
      return true
    } catch {
      defaults.set("failed", forKey: "guardTokenRefreshStatus")
      return false
    }
  }
  // iOS equivalent of Android's performForceUnblock: grant only this broker
  // bounded access, leaving the broker foregrounded and other shields intact.
  static func performForceUnblock(_ application: ApplicationToken) -> Bool {
    defaults.removeObject(forKey: "openGuardChat")
    // iOS may supply a refreshed action token while the picker selection
    // still contains the previous token. With exactly one configured broker,
    // release that saved shield token as well as the action token.
    let selected = selection.applicationTokens
    let targets: Set<ApplicationToken>
    if selected.contains(application) {
      targets = [application]
    } else if selected.count == 1, store.shield.applications == selected {
      targets = selected
    } else {
      defaults.set("actionTokenDoesNotMatchSelection", forKey: "guardSkipError")
      return false
    }
    let configured = allowTemporaryAccess(to: targets, authorizedShieldAction: true)
    let removed = store.shield.applications?.isDisjoint(with: targets) ?? true
    guard configured && removed else {
      endTemporaryAccess()
      defaults.set("skipFailed", forKey: "guardLastButtonAction")
      return false
    }
    defaults.set("skipTemporaryAccess", forKey: "guardLastButtonAction")
    return true
  }

  static func allowTemporaryAccess(to application: ApplicationToken) -> Bool {
    allowTemporaryAccess(to: [application])
  }
  static func allowTemporaryAccess(to applications: Set<ApplicationToken>, authorizedShieldAction: Bool = false) -> Bool {
    guard defaults.bool(forKey: "enabled"),
          (authorizedShieldAction || isAuthorized),
          !applications.isEmpty,
          applications.isSubset(of: selection.applicationTokens) else {
      defaults.set("permissionOrSelectionUnavailable", forKey: "guardSkipError")
      return false
    }
    defaults.removeObject(forKey: "guardSkipError")
    endTemporaryAccess()
    let now = Date()
    // One minute of usage, with a 16-minute wall-clock fallback. iOS requires
    // monitoring intervals of at least 15 minutes and controls callback timing.
    let access = TemporaryAccess(applications: applications,
      activityName: "guard-skip-\(UUID().uuidString)",
      expiresAt: now.addingTimeInterval(16 * 60))
    guard let data = try? PropertyListEncoder().encode(access) else { return false }
    defaults.set(data, forKey: skipKey)
    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let schedule = DeviceActivitySchedule(
      intervalStart: calendar.dateComponents(components, from: now),
      intervalEnd: calendar.dateComponents(components, from: access.expiresAt),
      repeats: false)
    let event: DeviceActivityEvent
    if #available(iOS 17.4, *) {
      event = DeviceActivityEvent(applications: applications,
        threshold: DateComponents(minute: 1), includesPastActivity: false)
    } else {
      event = DeviceActivityEvent(applications: applications,
        threshold: DateComponents(minute: 1))
    }
    do {
      // Register restoration before removing the shield. Failed registration
      // must never turn Skip into unlimited access.
      try center.startMonitoring(DeviceActivityName(access.activityName),
        during: schedule, events: [skipEvent: event])
      // The ShieldAction token and saved selection were validated above. The
      // authorization center in an extension need not mirror the app process.
      return apply(authorizedShieldAction: authorizedShieldAction)
    } catch {
      defaults.set("\(String(reflecting: type(of: error))): \(error.localizedDescription)", forKey: "guardSkipError")
      endTemporaryAccess()
      return false
    }
  }
  static func endTemporaryAccess(for activity: DeviceActivityName? = nil) {
    guard let access = temporaryAccess else { return }
    // A late callback from an earlier Skip must not cancel a newer Skip.
    if let activity = activity, activity.rawValue != access.activityName { return }
    defaults.removeObject(forKey: skipKey)
    apply()
    center.stopMonitoring([DeviceActivityName(access.activityName)])
  }
  static func start() -> Bool {
    // Remove schedules installed by older builds. Their end callbacks must
    // no longer leave trading apps unshielded overnight or on weekends.
    let names = (2...6).map { DeviceActivityName("market-\($0)") }
    defaults.set(true, forKey: "enabled")
    center.stopMonitoring(names)
    // Register the monitor independently of temporary Skip sessions. iOS can
    // invoke this extension without launching Zeno or its Flutter engine.
    if !center.activities.contains(protectionActivity) {
      do {
        try center.startMonitoring(protectionActivity, during: DeviceActivitySchedule(
          intervalStart: DateComponents(hour: 0, minute: 0),
          intervalEnd: DateComponents(hour: 23, minute: 59), repeats: true))
        defaults.removeObject(forKey: "guardMonitoringError")
      } catch {
        defaults.set(error.localizedDescription, forKey: "guardMonitoringError")
        apply()
        return false
      }
    }
    return apply()
  }
}
