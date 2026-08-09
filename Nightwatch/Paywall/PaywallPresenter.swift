import SuperwallKit

/// Presents the remotely managed paywall over the native hard-paywall gate.
///
/// The native `PaywallView` remains underneath, so an unavailable campaign,
/// network failure, or a user closing the remote surface can never unlock the
/// product. No feature closure is supplied to Superwall: RevenueCat entitlement
/// state remains the only route through `RootView`.
@MainActor
enum PaywallPresenter {
    static func presentOnboardingPaywall() {
        guard PurchaseConfiguration.isConfigured else { return }
        Superwall.shared.register(placement: "onboarding_completed")
    }
}
