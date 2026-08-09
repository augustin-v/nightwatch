import FactoryKit

/// The 11-screen onboarding sequence, per aurora-forecast-onboarding-copy.md
/// sections 1–12, minus section 11 (social proof) — cut deliberately per
/// ONBOARDING.md's rule against fabricating proof we don't have at launch.
/// Conforms to FactoryKit's `OnboardingStep` so `OnboardingContainerView`
/// can drive sequencing; screen copy and quiz mechanics live in the app.
enum AppOnboardingStep: Int, FactoryKit.OnboardingStep {
    case hook = 0
    case problemSharpened = 1
    case quizWound = 2
    case quizLatitudeBand = 3
    case quizObstacle = 4
    case quizIntent = 5
    case reflection = 6
    case solution = 7
    case alertsPromise = 8
    case nightVision = 9
    case locationPermission = 10
}
