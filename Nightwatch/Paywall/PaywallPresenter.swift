import SuperwallKit

/// Presents the remotely managed purchase surface.
///
/// Superwall owns all paywall content and purchase controls. The completion
/// callback only asks the caller to reconcile RevenueCat entitlement state; it
/// never grants access by itself.
@MainActor
enum PaywallPresenter {
    static func presentOnboardingPaywall(onComplete: @escaping @MainActor () -> Void) {
        guard PurchaseConfiguration.isConfigured, !ScreenshotConfiguration.current.isEnabled else {
            onComplete()
            return
        }

        let handler = PaywallPresentationHandler()
        handler.onDismiss { _, _ in
            Task { @MainActor in onComplete() }
        }
        handler.onError { _ in
            Task { @MainActor in onComplete() }
        }
        handler.onSkip { _ in
            Task { @MainActor in onComplete() }
        }

        Superwall.shared.register(
            placement: "onboarding_completed",
            handler: handler
        )
    }
}
