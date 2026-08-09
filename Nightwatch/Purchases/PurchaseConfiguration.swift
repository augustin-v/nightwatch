import Foundation

/// The purchase stack's public keys, in one place.
///
/// Both values below are **public client credentials**, the kind each vendor
/// documents as safe to embed in an app binary. No secret key, no App Store
/// Connect key and no `.p8` belongs in this repository.
enum PurchaseConfiguration {
    /// Superwall project 28487, iOS app 52866 (`com.augustinv.nightwatch`).
    static let superwallAPIKey = "pk_VGAxSOhBn4gj3H1S9wi-M"

    /// RevenueCat public SDK key. Empty until the RevenueCat project exists;
    /// see `REVENUECAT_SETUP_PROMPT.md`. This is the single swap point: the
    /// rest of the purchase stack is written against the real SDKs and needs
    /// no further changes when the key lands.
    static let revenueCatAPIKey = ""

    /// Must match the Superwall entitlement identifier exactly. If these two
    /// strings ever drift apart, Superwall and RevenueCat will disagree about
    /// who has paid and the hard paywall will lock out paying users.
    static let entitlementID = "pro"

    /// Whether the purchase stack can actually run. When this is false the app
    /// still works and still gates, but the paywall says purchasing is
    /// unavailable instead of pretending to sell something.
    static var isConfigured: Bool {
        !revenueCatAPIKey.isEmpty && !superwallAPIKey.isEmpty
    }
}
