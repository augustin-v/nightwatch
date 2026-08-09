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
    /// see the hard paywall flash for the half second RevenueCat needs to
    /// answer on a cold launch.
    private(set) var isEntitled: Bool

    private(set) var annual: Package?
    private(set) var weekly: Package?
    private(set) var isPurchasing = false
    private(set) var isRestoring = false

    /// Set when a purchase or restore fails for a reason the user should see.
    /// A deliberate cancellation is not one of them.
    private(set) var failureMessage: String?

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
    }

    /// Loads the current entitlement and the products to show on the paywall.
    /// Both are best effort: a network failure leaves the cached entitlement
    /// in place and the paywall falls back to its bundled price copy.
    func refresh() async {
        guard PurchaseConfiguration.isConfigured, !ScreenshotConfiguration.current.isEnabled else { return }

        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }

        if let offering = try? await Purchases.shared.offerings().current {
            annual = offering.annual ?? offering.package(identifier: "annual")
            weekly = offering.weekly ?? offering.package(identifier: "weekly")
        }
    }

    // MARK: - Purchase

    func purchase(_ plan: PaywallPlanChoice, source: Analytics.PaywallSource) async {
        guard let package = package(for: plan) else {
            failureMessage = String(localized: "paywall.error.unavailable")
            return
        }

        failureMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        Analytics.purchaseStarted(plan: plan.analyticsPlan, source: source)

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                // Not a failure. Counting it separately is what tells a
                // pricing problem apart from a broken checkout.
                Analytics.purchaseFailed(
                    plan: plan.analyticsPlan,
                    source: source,
                    errorCode: "user_cancelled"
                )
                return
            }
            apply(result.customerInfo)
            if isEntitled {
                Analytics.purchaseCompleted(plan: plan.analyticsPlan, source: source)
            }
        } catch {
            failureMessage = Self.message(for: error)
            Analytics.purchaseFailed(
                plan: plan.analyticsPlan,
                source: source,
                errorCode: Self.code(for: error)
            )
        }
    }

    /// Returns whether anything was actually restored, so the caller can tell
    /// the user "you are back in" rather than leaving them staring at the
    /// same paywall wondering whether the button worked.
    @discardableResult
    func restore() async -> Bool {
        guard PurchaseConfiguration.isConfigured else {
            failureMessage = String(localized: "paywall.error.unavailable")
            return false
        }

        failureMessage = nil
        isRestoring = true
        defer { isRestoring = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if isEntitled {
                Analytics.restoreCompleted(result: .entitled)
            } else {
                Analytics.restoreCompleted(result: .nothingToRestore)
                failureMessage = String(localized: "paywall.error.nothingToRestore")
            }
            return isEntitled
        } catch {
            Analytics.restoreCompleted(result: .failed)
            failureMessage = Self.message(for: error)
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

    private func package(for plan: PaywallPlanChoice) -> Package? {
        switch plan {
        case .annual: annual
        case .weekly: weekly
        }
    }

    // MARK: - Error presentation

    /// Store errors reach the user as one localized sentence. The underlying
    /// code goes to analytics instead, where it is useful and where it cannot
    /// confuse anyone.
    private static func message(for error: Error) -> String {
        if let rcError = error as? RevenueCat.ErrorCode {
            switch rcError {
            case .networkError, .offlineConnectionError:
                return String(localized: "paywall.error.network")
            case .purchaseNotAllowedError, .paymentPendingError:
                return String(localized: "paywall.error.notAllowed")
            default:
                break
            }
        }
        return String(localized: "paywall.error.generic")
    }

    private static func code(for error: Error) -> String {
        if let rcError = error as? RevenueCat.ErrorCode {
            return String(rcError.rawValue)
        }
        return String((error as NSError).code)
    }
}

/// The two tiers, as the app's own type. `FactoryPaywallView`'s `PaywallPlan`
/// is not used because Nightwatch draws its own paywall.
enum PaywallPlanChoice: Hashable {
    case annual
    case weekly

    var analyticsPlan: Analytics.Plan {
        switch self {
        case .annual: .annual
        case .weekly: .weekly
        }
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
