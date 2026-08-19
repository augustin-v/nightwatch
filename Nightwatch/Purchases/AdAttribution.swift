import Foundation
import AdServices
import RevenueCat

/// Joins an Apple Ads tap to the revenue it eventually produces.
///
/// Apple Ads reports spend per keyword. RevenueCat reports revenue per
/// customer. Nothing connects them unless the app itself carries the
/// attribution across, so without this an account can only be optimised on
/// cost per install, which under a hard paywall is the metric most likely to
/// be actively misleading: the cheapest taps are the ones that bounce.
///
/// Two independent paths, deliberately:
///
/// 1. `enableAdServicesAttributionTokenCollection()` hands the raw token to
///    RevenueCat, which resolves it server-side. This is the supported
///    integration and drives RevenueCat's own attribution charts.
/// 2. The token is *also* resolved here and written back as reserved
///    subscriber attributes, because **keyword-level** granularity is the
///    whole point and it must be queryable per customer. Campaign-level data
///    cannot answer "is this keyword worth its bid".
///
/// Attribution is not retroactive. An install bought before this ships is
/// unattributable forever, which is why it wants to land before spend does.
enum AdAttribution {
    /// Set once the outcome is *known*: attributed, or definitively organic.
    /// Never set on a transient failure, or a flaky first launch would discard
    /// the attribution permanently.
    private static let resolvedKey = "hasResolvedAdServicesAttribution"
    /// Bounds the retry-on-next-launch loop for installs that never resolve
    /// (simulator, or a token that keeps erroring).
    private static let attemptsKey = "adServicesAttributionAttempts"
    private static let maxLaunchAttempts = 5

    private static let endpoint = URL(string: "https://api-adservices.apple.com/api/v1/")!
    /// Apple's attribution record can lag the install itself. A 404 means "not
    /// written yet", not "this install was organic", so it is retried rather
    /// than treated as an answer.
    private static let maxRequestAttempts = 4
    private static let retryDelay: Duration = .seconds(5)

    private struct Payload: Decodable, Sendable {
        let attribution: Bool
        let orgId: Int?
        let campaignId: Int?
        let adGroupId: Int?
        let keywordId: Int?
        let adId: Int?
        let countryOrRegion: String?
        let conversionType: String?
    }

    /// Call once, immediately after `Purchases.configure`.
    static func start() {
        // `Purchases.shared` traps when the SDK was never configured, which is
        // the missing-API-key debug path.
        guard Purchases.isConfigured else { return }

        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: resolvedKey) else { return }
        guard defaults.integer(forKey: attemptsKey) < maxLaunchAttempts else { return }
        defaults.set(defaults.integer(forKey: attemptsKey) + 1, forKey: attemptsKey)

        Task { await resolve() }
    }

    private static func resolve() async {
        // Throws on the simulator and on transient network trouble. Both are
        // worth another launch, so neither marks the install resolved.
        guard let token = try? AAAttribution.attributionToken() else { return }

        guard let payload = await fetchPayload(token: token) else { return }

        // A definitive answer, even a negative one: this install did not come
        // from an ad and never will have. Stop asking.
        guard payload.attribution else {
            markResolved()
            return
        }

        apply(payload)
        markResolved()
    }

    private static func fetchPayload(token: String) async -> Payload? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)

        for attempt in 1...maxRequestAttempts {
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse else {
                return nil // Transient. Retried on the next launch.
            }

            switch http.statusCode {
            case 200:
                return try? JSONDecoder().decode(Payload.self, from: data)
            case 404 where attempt < maxRequestAttempts:
                // Record not written yet. Wait and ask again.
                try? await Task.sleep(for: retryDelay)
            default:
                return nil
            }
        }
        return nil
    }

    private static func apply(_ payload: Payload) {
        let attribution = Purchases.shared.attribution

        // Reserved keys, so this lands in RevenueCat's attribution reporting
        // rather than as free-form custom attributes.
        attribution.setMediaSource("apple_search_ads")
        attribution.setCampaign(payload.campaignId.map(String.init))
        attribution.setAdGroup(payload.adGroupId.map(String.init))
        attribution.setAd(payload.adId.map(String.init))
        // Absent for Search Match and broad-match taps, which have no single
        // keyword behind them. That absence is itself a useful signal.
        attribution.setKeyword(payload.keywordId.map(String.init))

        var extras: [String: String] = [:]
        // "Download" vs "Redownload": a redownload is a returning user, and
        // counting it as an acquisition overstates what the keyword bought.
        extras["ad_conversion_type"] = payload.conversionType
        extras["ad_country"] = payload.countryOrRegion
        extras["ad_org_id"] = payload.orgId.map(String.init)
        if !extras.isEmpty {
            attribution.setAttributes(extras)
        }
    }

    private static func markResolved() {
        UserDefaults.standard.set(true, forKey: resolvedKey)
    }
}
