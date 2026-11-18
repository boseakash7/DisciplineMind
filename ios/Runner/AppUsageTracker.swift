import Foundation

/// Local guard interactions only. iOS does not expose Android UsageStats here.
/// App-wide counters intentionally avoid exporting opaque application tokens.
enum AppUsageTracker {
  static let defaults = UserDefaults(suiteName: "group.com.discipline.mind.guard")!
  private static let queue = DispatchQueue(label: "com.discipline.mind.guard-usage")

  static func record(_ event: String) {
    guard ["skipGranted", "skipFailed", "iWillControl"].contains(event) else { return }
    queue.sync {
      let key = "guardUsage." + event
      defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
      defaults.set(Date().timeIntervalSince1970, forKey: "guardUsage.lastEventAt")
    }
  }

  static func snapshot() -> [String: Any] {
    [
      "platform": "ios",
      "scope": "localGuardInteractions",
      "skipGrantedCount": defaults.integer(forKey: "guardUsage.skipGranted"),
      "skipFailedCount": defaults.integer(forKey: "guardUsage.skipFailed"),
      "iWillControlCount": defaults.integer(forKey: "guardUsage.iWillControl"),
      "lastEventAt": defaults.double(forKey: "guardUsage.lastEventAt"),
      "supportsAppOpenCount": false,
      "supportsForegroundUsageTime": false
    ]
  }
}
