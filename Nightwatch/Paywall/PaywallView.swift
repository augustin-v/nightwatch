import SwiftUI
import FactoryKit

/// Stub paywall UI per STANDARDS.md §4 and 03_scaffold.md step 8: two
/// tiers, annual pre-selected, weekly present but not selected, no
/// monthly tier. Prices below are placeholder display copy only — real
/// App Store Connect products are created in Phase 4, and live
/// presentation moves to Superwall in Phase 5.
struct PaywallView: View {
    let onContinue: () -> Void

    var body: some View {
        // The paywall is a conversion surface, so it gets the identity too —
        // a white sheet after ten dark screens reads as a different app.
        NightSurface(intensity: 0.7) {
            paywall
        }
    }

    private var paywall: some View {
        FactoryPaywallView(
            headline: String(localized: "paywall.headline"),
            subheadline: String(localized: "paywall.subheadline"),
            annualCopy: PaywallPlanCopy(
                title: String(localized: "paywall.annual.title"),
                priceLabel: String(localized: "paywall.annual.priceLabel"),
                badge: String(localized: "paywall.annual.badge")
            ),
            weeklyCopy: PaywallPlanCopy(
                title: String(localized: "paywall.weekly.title"),
                priceLabel: String(localized: "paywall.weekly.priceLabel")
            ),
            shellCopy: PaywallShellCopy(
                continueButton: String(localized: "paywall.continue"),
                restorePurchases: String(localized: "paywall.restorePurchases")
            ),
            onContinue: { _ in
                // Phase 5 wires the real purchase call (Superwall/RevenueCat).
                onContinue()
            },
            onRestorePurchases: {
                // Phase 5 wires real restore-purchases logic.
            }
        )
    }
}
