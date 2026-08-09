import Foundation

/// Holds the quiz answers needed by the on-device reflection screen (spec
/// §5 screen 7). The answers themselves live only for the duration of
/// onboarding; only the stable option id reaches analytics, never a label and
/// never anything the user typed.
@Observable
final class OnboardingAnswers {
    var wound: QuizOption?
    var latitudeBand: QuizOption?
    var obstacle: QuizOption?
    var intent: QuizOption?

    /// The stable, non-localized option id for a quiz step, or `nil` for the
    /// steps that are not questions.
    func answerID(for step: AppOnboardingStep) -> String? {
        switch step {
        case .quizWound: wound?.id
        case .quizLatitudeBand: latitudeBand?.id
        case .quizObstacle: obstacle?.id
        case .quizIntent: intent?.id
        default: nil
        }
    }

    var realisticNightsPerYear: Int {
        QuizOptions.realisticNightsPerYear(forLatitudeBandID: latitudeBand?.id ?? "midLatitude")
    }
}
