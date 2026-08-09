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
        // `copy:` sits between the two closure parameters in FactoryKit 1.1.0,
        // so `onSubmit` is passed labelled and only `destination` trails.
        CancellationQuestionnaireView(
            onSubmit: { _, _ in
                // Phase 5: log the reason + free-text detail to PostHog.
            },
            copy: questionnaireCopy
        ) { _, _ in
            RetentionOfferView(
                isEligible: !appState.isOnAnnualPlan,
                offerTitle: String(localized: "retention.offer.title"),
                offerDescription: String(localized: "retention.offer.description"),
                copy: retentionCopy,
                onAcceptOffer: {
                    // Phase 5: apply the retention discount via RevenueCat,
                    // pending owner approval of a specific price (req_07f7177df3).
                },
                onDeclineOpenAppStore: openNativeSubscriptionManagement
            )
        }
    }

    /// FactoryKit 1.1.0 takes every word from the app, so the questionnaire's
    /// preset reasons — which STANDARDS.md §9 requires — are localizable
    /// rather than baked into the shared package.
    private var questionnaireCopy: CancellationQuestionnaireCopy {
        CancellationQuestionnaireCopy(
            reasonPromptTitle: String(localized: "cancel.reasonPrompt"),
            detailPromptTitle: String(localized: "cancel.detailPrompt"),
            detailPlaceholder: String(localized: "cancel.detailPlaceholder"),
            navigationTitle: String(localized: "cancel.navigationTitle"),
            nextButton: String(localized: "cancel.next"),
            reasonCopy: CancellationReasonCopy(
                tooExpensive: String(localized: "cancel.reason.tooExpensive"),
                didntUseIt: String(localized: "cancel.reason.didntUseIt"),
                foundBetterApp: String(localized: "cancel.reason.foundBetterApp"),
                technicalIssues: String(localized: "cancel.reason.technicalIssues"),
                other: String(localized: "cancel.reason.other")
            )
        )
    }

    private var retentionCopy: RetentionOfferCopy {
        RetentionOfferCopy(
            acceptButton: String(localized: "retention.accept"),
            declineButton: String(localized: "retention.decline"),
            ineligibleTitle: String(localized: "retention.ineligibleTitle")
        )
    }

    /// Fallback reached only after the user declines the retention offer,
    /// per STANDARDS.md §9 step 3.
    private func openNativeSubscriptionManagement() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}
