import SwiftUI
import FactoryKit

/// The required exit/retention flow (STANDARDS.md §9): questionnaire, then
/// the retention offer, and only on decline does the user reach Apple's
/// native subscription management. This is the sole destination Settings'
/// "Manage Subscription" row is allowed to route to — never a direct
/// deep link.
struct ManageSubscriptionFlow: View {
    let appState: AppState

    var body: some View {
        CancellationQuestionnaireView { _, _ in
            // Phase 5: log the reason + free-text detail to PostHog.
        } destination: { _, _ in
            RetentionOfferView(
                isEligible: !appState.isOnAnnualPlan,
                offerTitle: String(localized: "retention.offer.title"),
                offerDescription: String(localized: "retention.offer.description"),
                onAcceptOffer: {
                    // Phase 5: apply the retention discount via RevenueCat,
                    // pending owner approval of a specific price (req_07f7177df3).
                },
                onDeclineOpenAppStore: openNativeSubscriptionManagement
            )
        }
    }

    /// Fallback reached only after the user declines the retention offer,
    /// per STANDARDS.md §9 step 3.
    private func openNativeSubscriptionManagement() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}
