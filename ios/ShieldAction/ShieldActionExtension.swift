import ManagedSettings
import Foundation

final class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    respond(to: action, application: application, completionHandler: completionHandler)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    respond(to: action, application: nil, completionHandler: completionHandler)
  }

  private func respond(
    to action: ShieldAction,
    application: ApplicationToken?,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      AppUsageTracker.record("iWillControl")
      MarketGuard.defaults.set("iWillControl", forKey: "guardLastButtonAction")
      if #available(iOS 26.5, *) {
        MarketGuard.defaults.set(true, forKey: "openGuardChat")
        completionHandler(.openParentalControlsApp)
      } else {
        completionHandler(.close)
      }
    case .secondaryButtonPressed:
      if let application = application,
         MarketGuard.performForceUnblock(application) {
        AppUsageTracker.record("skipGranted")
        completionHandler(.none)
      } else {
        AppUsageTracker.record("skipFailed")
        completionHandler(.defer)
      }
    default:
      completionHandler(.none)
    }
  }
}
