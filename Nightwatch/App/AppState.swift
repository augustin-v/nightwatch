import Foundation

/// Shared app state that is deliberately *not* entitlement state.
///
/// Whether the user has paid lives in `PurchaseStore`, backed by RevenueCat,
/// with a cached last-known value for cold launch. Keeping a second
/// `isPremium` flag here is how a paying user ends up locked out by a hard
/// paywall, so this type owns onboarding completion and nothing else.
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
    }
}
