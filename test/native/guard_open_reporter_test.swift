import Foundation

// Run with swiftc ios/ShieldConfiguration/GuardOpenReporter.swift
// test/native/guard_open_reporter_test.swift -o /tmp/guard-reporter-test
final class MockProtocol: URLProtocol {
  static let lock = NSLock()
  static var paths: [String] = []
  static var bodies: [String] = []
  static var state = "locked"
  static let sent = DispatchSemaphore(value: 0)
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    Self.lock.lock()
    Self.paths.append(request.url!.lastPathComponent)
    var bodyData = request.httpBody ?? Data()
    if let stream = request.httpBodyStream {
      stream.open()
      var buffer = [UInt8](repeating: 0, count: 1024)
      while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        if count <= 0 { break }
        bodyData.append(buffer, count: count)
      }
      stream.close()
    }
    Self.bodies.append(String(data: bodyData, encoding: .utf8) ?? "")
    let state = Self.state
    Self.lock.unlock()
    let body = request.url!.lastPathComponent == "state"
      ? "{\"status\":\"ok\",\"payload\":{\"state\":\"\(state)\",\"trade_id\":42}}"
      : "{\"status\":\"ok\"}"
    client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data(body.utf8))
    client?.urlProtocolDidFinishLoading(self)
    Self.sent.signal()
  }
  override func stopLoading() {}
}

@main enum Tests {
  static func main() {
    assert(GuardOpenReporter.lockedTradeId(["state":"locked", "trade_id":42]) == "42")
    assert(GuardOpenReporter.lockedTradeId(["state":" LOCKED ", "trade_id":" 42 "]) == "42")
    assert(GuardOpenReporter.lockedTradeId(["state":"unlocked", "trade_id":42]) == nil)
    assert(GuardOpenReporter.lockedTradeId(["state":"", "trade_id":42]) == nil)
    assert(GuardOpenReporter.lockedTradeId(["state":"locked", "trade_id":NSNull()]) == nil)
    assert(GuardOpenReporter.lockedTradeId(["state":"locked", "trade_id":" "]) == nil)
    let suite = "guard-reporter-test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(true, forKey: "enabled")
    defaults.set("user&1", forKey: "guardStateUserId")
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockProtocol.self]
    let session = URLSession(configuration: configuration)
    defer { session.invalidateAndCancel() }
    let reporter = GuardOpenReporter(defaults: defaults, session: session)
    reporter.report(applicationKey: "kite")
    assert(MockProtocol.sent.wait(timeout: .now() + 3) == .success)
    assert(MockProtocol.sent.wait(timeout: .now() + 3) == .success)
    reporter.report(applicationKey: "kite")
    assert(MockProtocol.sent.wait(timeout: .now() + 0.2) == .timedOut)
    MockProtocol.lock.lock()
    assert(MockProtocol.paths == ["state", "force-unlock"])
    assert(MockProtocol.bodies == ["user_id=user%261", "trade_id=42&user_id=user%261"])
    MockProtocol.state = "unlocked"
    MockProtocol.lock.unlock()
    reporter.report(applicationKey: "another-app")
    assert(MockProtocol.sent.wait(timeout: .now() + 3) == .success)
    assert(MockProtocol.sent.wait(timeout: .now() + 0.2) == .timedOut)
    print("PASS: locked-state parsing, POST sequence/payload, duplicate suppression, unlocked suppression")
  }
}
