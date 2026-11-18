
import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private static let accent = UIColor(red: 0.40, green: 0.18, blue: 1.0, alpha: 1)

    // Draw only the supported shield icon; the system owns screen layout.
    private static let circularBrainIcon: UIImage = {
        let size = CGSize(width: 132, height: 132)
        let source = UIImage(named: "brain", in: Bundle(for: ShieldConfigurationExtension.self), compatibleWith: nil)
            ?? UIImage(systemName: "brain", withConfiguration: UIImage.SymbolConfiguration(pointSize: 62, weight: .regular))
        return UIGraphicsImageRenderer(size: size).image { _ in
            let circle = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 128, height: 128))
            UIColor.white.setFill()
            circle.fill()
            UIColor(red: 0.90, green: 0.85, blue: 0.98, alpha: 1).setStroke()
            circle.lineWidth = 2
            circle.stroke()
            if let source = source {
                let tinted = source.withTintColor(accent, renderingMode: .alwaysOriginal)
                let scale = min(66 / source.size.width, 66 / source.size.height)
                let fitted = CGSize(width: source.size.width * scale, height: source.size.height * scale)
                tinted.draw(in: CGRect(x: (size.width - fitted.width) / 2,
                                      y: (size.height - fitted.height) / 2,
                                      width: fitted.width, height: fitted.height))
            }
        }
    }()

    override func configuration(shielding application: Application) -> ShieldConfiguration {

        recordShieldInvocation()

        // Use the app iOS is actually shielding, never our containing app ID.
        // Keep this identity inside the sandboxed configuration extension.
        let bundleIdentifier = application.bundleIdentifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = application.localizedDisplayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let appName = [displayName, bundleIdentifier]
            .compactMap { $0 }.first { !$0.isEmpty } ?? "Trading app"

        let defaults = UserDefaults(
            suiteName: "group.com.discipline.mind.guard"
        )

        let updatedAt = defaults?.double(forKey: "guardStateUpdatedAt") ?? 0
        let fresh = Date().timeIntervalSince1970 - updatedAt < 300

        let hasTrade = fresh &&
            !(defaults?.string(forKey: "guardTradeId") ?? "").isEmpty

        let status = hasTrade
            ? "Trade is active\nfrom the Analyst"
            : "No new signal yet\nfrom the Analyst"

        let purple = Self.accent
        let buttonPurple = UIColor(red: 0.53, green: 0.34, blue: 0.97, alpha: 1)

        let darkText = UIColor(
            red: 0.12,
            green: 0.12,
            blue: 0.16,
            alpha: 1.0
        )

        let secondaryText = UIColor(
            red: 0.30,
            green: 0.30,
            blue: 0.36,
            alpha: 1.0
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .none,
            backgroundColor: .white,
            icon: Self.circularBrainIcon,

            title: ShieldConfiguration.Label(
                text: "MIND CONTROL GUARD\nis Active",
                color: darkText
            ),

            subtitle: ShieldConfiguration.Label(
                text:
                "Powered by zeno AI\n" +
                "\n\(status)\n" +
                "Save yourself\nfrom FOMO.\n" +
                "\nMind control traders\nwait for " +
                "right signal, not the noise.",
                color: secondaryText
            ),

            primaryButtonLabel: ShieldConfiguration.Label(
                text: "I WILL CONTROL",
                color: .white
            ),

            primaryButtonBackgroundColor: buttonPurple,

            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "SKIP →",
                color: purple
            )
        )
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    private func recordShieldInvocation() {
        let defaults = UserDefaults(
            suiteName: "group.com.discipline.mind.guard"
        )

        defaults?.set(
            ISO8601DateFormatter().string(from: Date()),
            forKey: "shieldConfigInvokedAt"
        )

        defaults?.set(
            (defaults?.integer(forKey: "shieldConfigInvocationCount") ?? 0) + 1,
            forKey: "shieldConfigInvocationCount"
        )
    }
}
