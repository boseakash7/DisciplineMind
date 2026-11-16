import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    ShieldConfiguration(
      backgroundBlurStyle: .systemMaterial,
      backgroundColor: UIColor(red: 0.96, green: 0.95, blue: 1.0, alpha: 1.0),
      icon: UIImage(systemName: "brain.head.profile"),
      title: ShieldConfiguration.Label(
        text: "MIND CONTROL GUARD",
        color: UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1.0)
      ),
      subtitle: ShieldConfiguration.Label(
        text: "is Active\nStay with the Analyst’s plan, not the next candle. Mind Control Guard helps you follow your process and avoid impulsive decisions.",
        color: UIColor(red: 0.30, green: 0.30, blue: 0.36, alpha: 1.0)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: "I WILL CONTROL",
        color: .white
      ),
      primaryButtonBackgroundColor: UIColor(red: 0.35, green: 0.34, blue: 0.94, alpha: 1.0),
      secondaryButtonLabel: ShieldConfiguration.Label(
        text: "SKIP",
        color: UIColor(red: 0.35, green: 0.34, blue: 0.94, alpha: 1.0)
      )
    )
  }

  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
    configuration(shielding: application)
  }
}
