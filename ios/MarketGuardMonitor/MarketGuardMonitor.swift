import DeviceActivity
import Foundation

final class MarketGuardMonitor: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    recordCallback("intervalDidStart")
    MarketGuard.apply()
  }
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    recordCallback("intervalDidEnd")
    MarketGuard.endTemporaryAccess(for: activity)
    MarketGuard.apply()
  }
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    recordCallback("eventDidReachThreshold")
    if event == MarketGuard.skipEvent {
      MarketGuard.endTemporaryAccess(for: activity)
    }
  }
  private func recordCallback(_ callback: String) {
    MarketGuard.defaults.set(callback, forKey: "guardMonitorLastCallback")
    MarketGuard.defaults.set(Date().timeIntervalSince1970, forKey: "guardMonitorCallbackAt")
  }
}
