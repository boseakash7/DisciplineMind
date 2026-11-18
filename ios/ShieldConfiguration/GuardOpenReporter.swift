import Foundation

// Best-effort reporting when iOS requests a broker shield. Configuration may be
// cached by iOS, so this is not an Android-style foreground-session observer.
final class GuardOpenReporter {
  static let shared = GuardOpenReporter()
  private let queue = DispatchQueue(label: "com.discipline.mind.guard-reporting")
  private let defaults: UserDefaults
  private let session: URLSession
  private var inFlight = Set<String>()
  private let baseURL = URL(string: "https://api.disciplinedminds.in/api/v2test/")!

  init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.discipline.mind.guard")!,
       session: URLSession = .shared) {
    self.defaults = defaults
    self.session = session
  }

  func report(applicationKey: String) {
    queue.async {
      guard self.defaults.bool(forKey: "enabled"),
            let userId = self.defaults.string(forKey: "guardStateUserId"),
            !userId.isEmpty else { return }
      let key = userId + ":" + applicationKey
      // Shield redraws can repeat the callback. Persist a short cooldown across
      // extension restarts; do not claim this identifies an app-open session.
      let cooldownKey = "guardReportAttempt." + key
      let now = Date().timeIntervalSince1970
      let elapsed = now - self.defaults.double(forKey: cooldownKey)
      guard !self.inFlight.contains(key), elapsed < 0 || elapsed >= 30 else { return }
      self.inFlight.insert(key)
      self.defaults.set(now, forKey: cooldownKey)
      self.record("checkingState")
      self.post("app/state", fields: ["user_id": userId]) { data, response, error in
        self.queue.async {
          guard self.defaults.bool(forKey: "enabled"),
                self.defaults.string(forKey: "guardStateUserId") == userId else {
            self.finish(key, "cancelled")
            return
          }
          guard error == nil, let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode), let data = data,
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                json["status"] as? String == "ok",
                let payload = json["payload"] as? [String: Any],
                let tradeId = Self.lockedTradeId(payload) else {
            self.finish(key, error == nil ? "notReported" : "stateRequestFailed")
            return
          }
          self.notifyForceUnlockAttempt(userId: userId, tradeId: tradeId) { succeeded in
            self.queue.async {
              self.finish(key, succeeded ? "reported" : "forceUnlockRequestFailed")
            }
          }
        }
      }
    }
  }

  // Async equivalent of Android's Boolean-returning HTTP call. Never block
  // the shield's UI thread waiting for a network response.
  func notifyForceUnlockAttempt(userId: String, tradeId: String,
                                completion: @escaping (Bool) -> Void) {
    post("app/force-unlock", fields: ["user_id": userId, "trade_id": tradeId]) { _, response, error in
      if let error = error {
        NSLog("[MindControlGuard] Force-unlock request failed: %@", error.localizedDescription)
        completion(false)
        return
      }
      let status = (response as? HTTPURLResponse)?.statusCode ?? 0
      completion((200..<300).contains(status))
    }
  }

  static func lockedTradeId(_ payload: [String: Any]) -> String? {
    let state = (payload["state"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    // Match Android: any confirmed nonempty state other than unlocked blocks.
    guard !state.isEmpty, state != "unlocked" else { return nil }
    let tradeId: String
    if let value = payload["trade_id"] as? String { tradeId = value }
    else if let value = payload["trade_id"] as? NSNumber { tradeId = value.stringValue }
    else { return nil }
    let trimmed = tradeId.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func post(_ endpoint: String, fields: [String: String],
                    completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
    var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
    request.httpBody = fields.sorted { $0.key < $1.key }.map {
      ($0.key.addingPercentEncoding(withAllowedCharacters: allowed) ?? "") + "=" +
        ($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
    }.joined(separator: "&").data(using: .utf8)
    session.dataTask(with: request, completionHandler: completion).resume()
  }

  private func finish(_ key: String, _ status: String) {
    inFlight.remove(key)
    record(status)
  }

  private func record(_ status: String) {
    defaults.set(status, forKey: "guardOpenReportStatus")
    defaults.set(Date().timeIntervalSince1970, forKey: "guardOpenReportUpdatedAt")
  }
}
