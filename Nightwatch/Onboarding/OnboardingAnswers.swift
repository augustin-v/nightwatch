import Foundation

/// Holds the quiz answers needed by the on-device reflection screen (spec
/// §5 screen 7). Nothing here is transmitted anywhere — it lives only for
/// the duration of onboarding.
@Observable
final class OnboardingAnswers {
    var wound: QuizOption?
    var latitudeBand: QuizOption?
    var obstacle: QuizOption?
    var intent: QuizOption?

    var realisticNightsPerYear: Int {
        QuizOptions.realisticNightsPerYear(forLatitudeBandID: latitudeBand?.id ?? "midLatitude")
    }
}
