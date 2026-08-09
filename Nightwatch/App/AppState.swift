import Foundation

/// Minimal shared app state for the scaffold. Real entitlement state
/// (RevenueCat) and onboarding-completion persistence choices are refined
/// in later phases; this only carries what the required screens need to
/// exist and be reachable now.
@Observable
final class AppState {
    /// Whether onboarding (through the paywall hand-off) has been completed
    /// at least once this run. Not yet persisted across launches — that is
    /// a Phase 3b concern once the app has real data to show on return.
    var hasCompletedOnboarding = false

    /// Placeholder entitlement tier for the retention-offer eligibility gate
    /// (STANDARDS.md §9): the discount must never show to a user already on
    /// annual. Real state comes from RevenueCat in 05_integrations.md — this
    /// stub defaults to "not on annual" so the offer flow is exercisable in
    /// the scaffold.
    var isOnAnnualPlan = false
}
