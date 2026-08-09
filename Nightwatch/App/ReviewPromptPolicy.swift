import Foundation

enum ReviewPromptPolicy {
    static let hasRequestedKey = "hasRequestedAppReview"
    private static let successfulForecastCountKey = "successfulForecastCount"
    private static let requiredSuccessfulForecasts = 3

    /// A forecast is the app's AHA moment. Waiting for the third successful
    /// refresh avoids interrupting onboarding, the paywall, cold launch, or a
    /// first glance at the result. The decision persists across relaunches.
    static func recordSuccessfulForecast(defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: hasRequestedKey) else { return false }

        let count = defaults.integer(forKey: successfulForecastCountKey) + 1
        defaults.set(count, forKey: successfulForecastCountKey)
        guard count >= requiredSuccessfulForecasts else { return false }

        defaults.set(true, forKey: hasRequestedKey)
        return true
    }
}
