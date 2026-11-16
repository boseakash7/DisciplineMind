import ManagedSettings

final class ShieldActionExtension: ShieldActionDelegate {
  private let store = ManagedSettingsStore()

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
      if #available(iOS 26.5, *) {
        completionHandler(.openParentalControlsApp)
      } else {
        completionHandler(.close)
      }
    case .secondaryButtonPressed:
      if let application = application {
        var shieldedApplications = store.shield.applications ?? []
        shieldedApplications.remove(application)
        // Keep an explicit (possibly empty) app set so Zeno can distinguish
        // this one-session Skip from a guard that was turned off entirely.
        store.shield.applications = shieldedApplications
      } else {
        store.shield.applicationCategories = nil
      }
      // `.defer` redraws the shield and delays the decision. Since Skip has
      // already removed this app from the shield, let iOS continue into it.
      completionHandler(.none)
    default:
      completionHandler(.none)
    }
  }
}
