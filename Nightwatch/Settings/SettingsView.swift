import SwiftUI
import FactoryKit

/// Required Settings screen per STANDARDS.md §2: restore purchases, manage
/// subscription (routed through the exit/retention flow, never a direct
/// deep link), contact support, privacy policy, terms of use.
struct SettingsView: View {
    var body: some View {
        FactorySettingsView(config: settingsConfig) {
            ManageSubscriptionFlow()
        }
    }

    private var settingsConfig: SettingsConfig {
        SettingsConfig(
            onRestorePurchases: {
                Task { await PurchaseStore.shared.restore() }
            },
            onContactSupport: {
                guard let url = URL(string: "mailto:augustin.dev@tutamail.com") else { return }
                UIApplication.shared.open(url)
            },
            restorePurchasesTitle: String(localized: "settings.restorePurchases"),
            manageSubscriptionTitle: String(localized: "settings.manageSubscription"),
            contactSupportTitle: String(localized: "settings.contactSupport"),
            navigationTitle: String(localized: "settings.title"),
            privacyPolicyTitle: String(localized: "settings.privacyPolicy.title"),
            privacyPolicyMarkdown: LegalDocuments.privacyPolicyMarkdown,
            termsTitle: String(localized: "settings.terms.title"),
            termsMarkdown: LegalDocuments.termsMarkdown
        )
    }
}
