import Foundation
import RevenueCat
import SuperwallKit

/// Everything the app knows about who has paid.
///
/// RevenueCat owns entitlement truth and receipt validation; Superwall owns
/// paywall presentation and remote configuration. They are wired together
/// rather than run side by side: Superwall never talks to StoreKit itself,
/// it hands every purchase and restore to the `PurchaseController` below,
/// which performs it through RevenueCat and then pushes the resulting
/// entitlement state back into Superwall. One source of truth, two consumers.
@Observable
@MainActor
final class PurchaseStore {
    static let shared = PurchaseStore()

    /// Whether the `pro` entitlement is currently active.
    ///
    /// Seeded from the cached value in `AppState` so a paying user does not
    /// see the remote paywall flash while RevenueCat refreshes on cold launch.
    private(set) var isEntitled: Bool

    private let cache: EntitlementCache

    private init(cache: EntitlementCache = .userDefaults) {
        self.cache = cache
        self.isEntitled = cache.load()
    }

    // MARK: - Launch

    /// Called once at launch, before any UI. Safe to call when the keys are
    /// not yet configured: the app still runs, the paywall simply reports
    /// that purchasing is unavailable rather than crashing.
    static func configureSDKs() {
        guard PurchaseConfiguration.isConfigured else { return }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: PurchaseConfiguration.revenueCatAPIKey)

        Superwall.configure(
            apiKey: PurchaseConfiguration.superwallAPIKey,
            purchaseController: RevenueCatPurchaseController.shared
        )

        AdAttribution.start()
    }

    /// Refreshes the current entitlement. Product presentation belongs to
    /// Superwall, so the app does not maintain a second local product catalog.
    func refresh() async {
        guard PurchaseConfiguration.isConfigured, !ScreenshotConfiguration.current.isEnabled else { return }

        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
    }

    /// Returns whether anything was actually restored, so the caller can tell
    /// the user "you are back in" rather than leaving them staring at the
    /// same paywall wondering whether the button worked.
    @discardableResult
    func restore() async -> Bool {
        guard PurchaseConfiguration.isConfigured else { return false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if isEntitled {
                Analytics.restoreCompleted(result: .entitled)
            } else {
                Analytics.restoreCompleted(result: .nothingToRestore)
            }
            return isEntitled
        } catch {
            Analytics.restoreCompleted(result: .failed)
            return false
        }
    }

    // MARK: - Entitlement state

    private func apply(_ info: RevenueCat.CustomerInfo) {
        let entitled = info.entitlements[PurchaseConfiguration.entitlementID]?.isActive == true
        isEntitled = entitled
        cache.save(entitled)
        RevenueCatPurchaseController.shared.pushToSuperwall(entitled)
    }
}

/// Where the last known entitlement is remembered between launches.
struct EntitlementCache: Sendable {
    var load: @Sendable () -> Bool
    var save: @Sendable (Bool) -> Void

    static let userDefaults = EntitlementCache(
        load: { UserDefaults.standard.bool(forKey: "isPremium") },
        save: { UserDefaults.standard.set($0, forKey: "isPremium") }
    )
}

/// Superwall's bridge to RevenueCat.
///
/// Without this, a purchase made on a Superwall paywall would go straight to
/// StoreKit and RevenueCat would never see it, which is exactly the
/// "disconnected purchase systems" the factory standards forbid.
final class RevenueCatPurchaseController: PurchaseController, @unchecked Sendable {
    static let shared = RevenueCatPurchaseController()

    private init() {}

    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            let rcProducts = await Purchases.shared.products([product.productIdentifier])
            guard let rcProduct = rcProducts.first else { return .failed(PurchaseBridgeError.productNotFound) }
            let result = try await Purchases.shared.purchase(product: rcProduct)
            if result.userCancelled { return .cancelled }
            await refreshEntitlement(result.customerInfo)
            return .purchased
        } catch {
            return .failed(error)
        }
    }

    func restorePurchases() async -> RestorationResult {
        do {
            let info = try await Purchases.shared.restorePurchases()
            await refreshEntitlement(info)
            return .restored
        } catch {
            return .failed(error)
        }
    }

    func pushToSuperwall(_ entitled: Bool) {
        guard PurchaseConfiguration.isConfigured else { return }
        Superwall.shared.subscriptionStatus = entitled
            ? .active([SuperwallKit.Entitlement(id: PurchaseConfiguration.entitlementID)])
            : .inactive
    }

    @MainActor
    private func refreshEntitlement(_ info: RevenueCat.CustomerInfo) async {
        await PurchaseStore.shared.refresh()
        _ = info
    }

    enum PurchaseBridgeError: Error {
        case productNotFound
    }
}
