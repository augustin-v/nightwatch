import Combine
import SwiftUI
import SuperwallKit

/// The bridge between the native paywall and Superwall's remote one.
///
/// The two are layered rather than exclusive. `PaywallView` is the gate: it is
/// local, localized in all eight languages, and renders with no network, which
/// a hard paywall has to. Superwall is then offered the chance to present over
/// it. If the campaign has no paywall assigned, or the device is offline, or
/// the SDK is not configured, nothing happens and the native screen stays.
/// That ordering is deliberate: a remote-only hard paywall that fails to load
/// is an app that cannot be opened.
@MainActor
enum PaywallPresenter {
    /// Superwall's remote paywall cannot reach the legal documents, which are
    /// bundled markdown rather than hosted pages. Its "Terms" and "Privacy"
    /// taps come back as custom actions and are republished here so the same
    /// native sheets open from either paywall.
    static let legalRequests = PassthroughSubject<LegalDocumentChoice, Never>()

    private static var didRegister = false

    static func registerOnboardingPlacement(onEntitled: @escaping () async -> Void) {
        guard PurchaseConfiguration.isConfigured, !didRegister else { return }
        didRegister = true

        Superwall.shared.delegate = SuperwallBridge.shared

        // The feature block runs when Superwall considers the user entitled,
        // which after a purchase through the RevenueCat purchase controller
        // means the entitlement is already real. Re-reading it rather than
        // trusting the callback keeps RevenueCat the single source of truth.
        Superwall.shared.register(placement: "onboarding_completed") {
            Task { await onEntitled() }
        }
    }
}

/// Receives the paywall's custom actions.
private final class SuperwallBridge: NSObject, SuperwallDelegate, @unchecked Sendable {
    @MainActor static let shared = SuperwallBridge()

    nonisolated func handleCustomPaywallAction(withName name: String) {
        Task { @MainActor in route(name) }
    }

    @MainActor
    private func route(_ name: String) {
        switch name {
        case "terms":
            PaywallPresenter.legalRequests.send(.terms)
        case "privacy":
            PaywallPresenter.legalRequests.send(.privacy)
        default:
            break
        }
    }
}
