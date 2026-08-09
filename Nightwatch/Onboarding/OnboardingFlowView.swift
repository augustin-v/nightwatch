import SwiftUI
import FactoryKit

/// Coordinates the 11-screen onboarding sequence (spec §5, minus the cut
/// social-proof screen) via FactoryKit's `OnboardingContainerView`, then
/// hands off to the paywall. Screen structure and sequencing are real;
/// only the underlying forecast data is stubbed until Phase 3b.
struct OnboardingFlowView: View {
    @State private var answers = OnboardingAnswers()
    @State private var locationRequester = LocationPermissionRequester()
    let onFinishedOnboarding: () -> Void

    var body: some View {
        NightSurface(intensity: 1.0) {
            OnboardingContainerView(firstStep: AppOnboardingStep.hook) { step, advance in
                // Every screen reports its own view and completion, so a drop
                // between any two of the eleven shows up as a specific screen
                // rather than one unexplained gap between "started" and
                // "completed".
                stepView(for: step, advance: instrumented(step, advance))
                    .task(id: step) { Analytics.onboardingScreenViewed(step) }
            } paywall: { dismissPaywall in
                // A hand-off, not a dismissal: `onContinue` fires only once a
                // purchase or restore has actually granted the entitlement,
                // so onboarding cannot be completed past the paywall for free.
                PaywallView(source: .onboarding) {
                    Analytics.onboardingCompleted()
                    dismissPaywall()
                    onFinishedOnboarding()
                }
            }
        }
        .task { Analytics.onboardingStarted() }
    }

    /// Wraps a step's advance so completion is logged where the user actually
    /// leaves the screen, including the two screens that first raise a system
    /// permission prompt.
    private func instrumented(
        _ step: AppOnboardingStep,
        _ advance: @escaping () -> Void
    ) -> () -> Void {
        {
            if let answerID = answers.answerID(for: step) {
                Analytics.onboardingAnswered(step, answerID: answerID)
            }
            Analytics.onboardingScreenCompleted(step)
            advance()
        }
    }

    @ViewBuilder
    private func stepView(for step: AppOnboardingStep, advance: @escaping () -> Void) -> some View {
        switch step {
        case .hook:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.hook.title"),
                subtitle: String(localized: "onboarding.hook.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: advance
            )
        case .problemSharpened:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.problem.title"),
                subtitle: String(localized: "onboarding.problem.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: advance
            )
        case .quizWound:
            SingleChoiceQuizStepView(
                title: String(localized: "onboarding.quiz.wound.question"),
                options: QuizOptions.wound,
                selection: $answers.wound,
                onContinue: advance
            )
        case .quizLatitudeBand:
            SingleChoiceQuizStepView(
                title: String(localized: "onboarding.quiz.latitude.question"),
                options: QuizOptions.latitudeBand,
                selection: $answers.latitudeBand,
                onContinue: advance
            )
        case .quizObstacle:
            SingleChoiceQuizStepView(
                title: String(localized: "onboarding.quiz.obstacle.question"),
                options: QuizOptions.obstacle,
                selection: $answers.obstacle,
                onContinue: advance
            )
        case .quizIntent:
            SingleChoiceQuizStepView(
                title: String(localized: "onboarding.quiz.intent.question"),
                options: QuizOptions.intent,
                selection: $answers.intent,
                onContinue: advance
            )
        case .reflection:
            ReflectionStepView(realisticNightsPerYear: answers.realisticNightsPerYear, onContinue: advance)
        case .solution:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.solution.title"),
                subtitle: String(localized: "onboarding.solution.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: advance
            )
        case .alertsPromise:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.alerts.title"),
                subtitle: String(localized: "onboarding.alerts.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: {
                    PermissionRequesters.requestNotifications()
                    advance()
                }
            )
        case .nightVision:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.nightVision.title"),
                subtitle: String(localized: "onboarding.nightVision.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: advance
            )
        case .locationPermission:
            OnboardingScreenScaffold(
                title: String(localized: "onboarding.location.title"),
                subtitle: String(localized: "onboarding.location.subtitle"),
                continueTitle: String(localized: "onboarding.continue"),
                onContinue: {
                    locationRequester.requestWhenInUse()
                    advance()
                }
            )
        }
    }
}
