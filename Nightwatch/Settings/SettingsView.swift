import SwiftUI
import FactoryKit

/// Required Settings screen per STANDARDS.md §2: restore purchases, manage
/// subscription (routed through the exit/retention flow, never a direct
/// deep link), contact support, privacy policy, terms of use.
struct SettingsView: View {
    let appState: AppState

    var body: some View {
        FactorySettingsView(config: settingsConfig) {
            ManageSubscriptionFlow(appState: appState)
        }
    }

    private var settingsConfig: SettingsConfig {
        SettingsConfig(
            onRestorePurchases: {
                // Phase 5: wire real RevenueCat restore-purchases call.
            },
            onContactSupport: {
                guard let url = URL(string: "mailto:augustin.dev@tutamail.com") else { return }
                UIApplication.shared.open(url)
            },
            privacyPolicyTitle: String(localized: "settings.privacyPolicy.title"),
            privacyPolicyMarkdown: LegalDocuments.privacyPolicyMarkdown,
            termsTitle: String(localized: "settings.terms.title"),
            termsMarkdown: LegalDocuments.termsMarkdown
        )
    }
}
