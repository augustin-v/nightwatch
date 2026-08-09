import Foundation
import FactoryAnalytics

/// The app's single seam onto Factory Analytics.
///
/// Two rules make this file worth existing rather than calling
/// `FactoryAnalytics.capture` from the views directly. First, the event and
/// property vocabulary is closed: the Worker rejects anything outside the
/// checked-in schema, so every call site has to spell its identifiers the same
/// way and a typo should be a compile error, not a silently dropped batch.
/// Second, nothing user-generated may leave the device. Saved place names, the
/// cancellation free-text field and coordinates are all off limits, so the
/// helpers below only ever take values this file can enumerate.
enum Analytics {
    /// The per-app ingest token. This is deliberately checked in: it is a
    /// revocable client credential, not a secret, and anything embedded in a
    /// mobile binary is recoverable anyway. The abuse controls are server side
    /// (closed schema, per-app and per-installation daily caps). The Factory
    /// Analytics `ADMIN_TOKEN` is a different thing entirely and must never
    /// appear in this repository.
    private static let appToken = "prg1JRIwk9wq81gFRupRjFIY71eNlcDjbO0x-NX6Wl4"
    private static let endpoint = URL(string: "https://factory-analytics.avilletardpiano.workers.dev")!

    static func start() {
        FactoryAnalytics.configure(
            .init(appID: "aurora-forecast", endpoint: endpoint, appToken: appToken)
        )
        FactoryAnalytics.capture(.appOpened)
        FactoryAnalytics.capture(.sessionStarted)
    }

    /// Called when the app backgrounds. Queued events are dropped rather than
    /// retried if the flush fails; analytics must never delay or block the
    /// product.
    static func flush() async {
        await FactoryAnalytics.flush()
    }

    // MARK: - Onboarding

    static func onboardingStarted() {
        FactoryAnalytics.capture(.onboardingStarted)
    }

    static func onboardingScreenViewed(_ step: AppOnboardingStep) {
        FactoryAnalytics.capture(.onboardingScreenViewed, properties: [
            .screenID: step.analyticsID,
            .step: String(step.rawValue),
        ])
    }

    static func onboardingScreenCompleted(_ step: AppOnboardingStep) {
        FactoryAnalytics.capture(.onboardingScreenCompleted, properties: [
            .screenID: step.analyticsID,
            .step: String(step.rawValue),
        ])
    }

    /// Quiz answers are logged as the option's stable slug, never its
    /// localized label, so the funnel stays comparable across eight languages.
    static func onboardingAnswered(_ step: AppOnboardingStep, answerID: String) {
        FactoryAnalytics.capture(.onboardingAnswered, properties: [
            .screenID: step.analyticsID,
            .answerID: answerID,
        ])
    }

    static func onboardingCompleted() {
        FactoryAnalytics.capture(.onboardingCompleted)
    }

    // MARK: - Paywall and purchase

    /// `source` distinguishes the paywall shown at the end of onboarding from
    /// the same paywall met on a later cold launch by someone who never paid.
    /// They convert differently and the funnel is misleading if they are one
    /// number.
    enum PaywallSource: String {
        case onboarding
        case relaunch
    }

    enum Plan: String {
        case annual
        case weekly
    }

    static func paywallViewed(source: PaywallSource) {
        FactoryAnalytics.capture(.paywallViewed, properties: [.source: source.rawValue])
    }

    static func purchaseStarted(plan: Plan, source: PaywallSource) {
        FactoryAnalytics.capture(.purchaseStarted, properties: [
            .plan: plan.rawValue,
            .source: source.rawValue,
        ])
    }

    static func purchaseCompleted(plan: Plan, source: PaywallSource) {
        FactoryAnalytics.capture(.purchaseCompleted, properties: [
            .plan: plan.rawValue,
            .source: source.rawValue,
        ])
    }

    /// A cancelled purchase is not a failure worth an `error_code`, but it is
    /// worth counting: it is the difference between a pricing problem and a
    /// broken checkout.
    static func purchaseFailed(plan: Plan, source: PaywallSource, errorCode: String) {
        FactoryAnalytics.capture(.purchaseFailed, properties: [
            .plan: plan.rawValue,
            .source: source.rawValue,
            .errorCode: errorCode,
        ])
    }

    static func restoreCompleted(result: RestoreResult) {
        FactoryAnalytics.capture(.restoreCompleted, properties: [.result: result.rawValue])
    }

    enum RestoreResult: String {
        case entitled
        case nothingToRestore = "nothing_to_restore"
        case failed
    }

    // MARK: - Product usage

    /// The app-specific slugs. `feature_used` with a stable `feature` value is
    /// the canonical way to measure this; per-app event names are not allowed
    /// and would not survive the Worker's schema check.
    enum Feature: String {
        case tonightViewed = "tonight_viewed"
        case nightsAheadViewed = "nights_ahead_viewed"
        case ovalMapViewed = "oval_map_viewed"
        case placesViewed = "places_viewed"
        case placeAdded = "place_added"
        case placeSelected = "place_selected"
        case alertsOpened = "alerts_opened"
        case alertsEnabled = "alerts_enabled"
        case alertsDisabled = "alerts_disabled"
        case alertThresholdChanged = "alert_threshold_changed"
        case quietHoursEnabled = "quiet_hours_enabled"
        case nightVisionToggled = "night_vision_toggled"
    }

    static func featureUsed(_ feature: Feature) {
        FactoryAnalytics.capture(.featureUsed, properties: [.feature: feature.rawValue])
    }

    // MARK: - Cancellation

    /// The questionnaire's free-text field stays on the device. Only the
    /// preset reason code is transmitted, which is the whole point of having
    /// preset reasons.
    static func cancellationStarted() {
        FactoryAnalytics.capture(.retentionStarted)
    }

    static func cancellationReason(_ reasonCode: String) {
        FactoryAnalytics.capture(.retentionReasonSelected, properties: [.reasonCode: reasonCode])
    }
}

extension AppOnboardingStep {
    /// Stable analytics identifiers. These are decoupled from the case names
    /// on purpose: renaming a Swift case should not silently split a funnel
    /// that has months of history behind it.
    var analyticsID: String {
        switch self {
        case .hook: "hook"
        case .problemSharpened: "problem"
        case .quizWound: "quiz_wound"
        case .quizLatitudeBand: "quiz_latitude"
        case .quizObstacle: "quiz_obstacle"
        case .quizIntent: "quiz_intent"
        case .reflection: "reflection"
        case .solution: "solution"
        case .alertsPromise: "alerts_promise"
        case .nightVision: "night_vision"
        case .locationPermission: "location_permission"
        }
    }
}
