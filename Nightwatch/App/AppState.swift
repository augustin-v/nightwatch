import Foundation

/// Minimal shared app state for the scaffold. Real entitlement state
/// (RevenueCat) and onboarding-completion persistence choices are refined
/// in later phases; this only carries what the required screens need to
/// exist and be reachable now.
@Observable
final class AppState {
    /// Whether onboarding (through the paywall hand-off) has been completed.
    /// Persisted: replaying eleven screens on every cold launch would be a
    /// shipping bug, not a placeholder.
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }

    private static let onboardingKey = "hasCompletedOnboarding"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        isPremium = UserDefaults.standard.bool(forKey: Self.premiumKey)
    }

    /// Whether the user has an active subscription.
    ///
    /// Phase 5 replaces this with RevenueCat's entitlement state. It is
    /// persisted rather than defaulted so that the premium screens can be
    /// exercised end to end now, and so a purchase made in one session is
    /// still honoured in the next once the real entitlement arrives.
    var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: Self.premiumKey) }
    }

    private static let premiumKey = "isPremium"

    /// Placeholder entitlement tier for the retention-offer eligibility gate
    /// (STANDARDS.md §9): the discount must never show to a user already on
    /// annual. Real state comes from RevenueCat in 05_integrations.md — this
    /// stub defaults to "not on annual" so the offer flow is exercisable in
    /// the scaffold.
    var isOnAnnualPlan = false
}
