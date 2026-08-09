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
                stepView(for: step, advance: advance)
            } paywall: { dismissPaywall in
                PaywallView {
                    dismissPaywall()
                    onFinishedOnboarding()
                }
            }
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
