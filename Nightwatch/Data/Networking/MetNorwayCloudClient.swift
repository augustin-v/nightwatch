import Foundation
import AuroraCore

/// Fetches and caches hourly cloud cover from MET Norway's Locationforecast
/// 2.0 `compact` endpoint.
///
/// Live shape re-verified 2026-08-09 directly against
/// `api.met.no/weatherapi/locationforecast/2.0/compact?lat=...&lon=...`
/// (the previous worker could not reach this host and built the fixture from
/// documentation only): the response is
/// `{ "properties": { "timeseries": [ { "time", "data": { "instant": {
/// "details": { "cloud_area_fraction" } } } } ] } }`, exactly what
/// `AuroraCore.CloudForecast.decode` already expects. No decoder change was
/// needed.
///
/// Two MET Norway terms-of-use obligations enforced here, not left to the
/// caller:
/// 1. An identifying `User-Agent`. A generic/placeholder-looking UA (tried
///    during verification as `"NightwatchApp-Verification/1.0
///    test@example.com"`) was rejected with `403 Forbidden`; a UA naming the
///    real app and a real contact point (tried as `"Nightwatch iOS app
///    contact@nightwatchapp.example"`) was accepted with `200`. The exact
///    contact string is a product detail (real support email/URL), so
///    `userAgent` is injectable here with a placeholder default — the
///    mastermind should supply the real one before shipping.
/// 2. `Expires` / `If-Modified-Since` caching, honoured as an obligation, not
///    an optimisation: this client will not re-fetch before the server's
///    stated `Expires` time, and when it does re-fetch it sends
///    `If-Modified-Since` (and `If-None-Match` if an `ETag` was seen) so a
///    `304 Not Modified` is possible.
public actor MetNorwayCloudClient {
    private let httpClient: HTTPClient
    /// Placeholder — replace with the shipping app's real identifying
    /// User-Agent (name + contact/URL) before release. See type doc.
    private let userAgent: String
    /// Overridable for tests so cache files land in a throwaway directory
    /// instead of the real Application Support folder.
    private let cacheDirectory: URL?

    public init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        userAgent: String = "Nightwatch/1.0 (iOS aurora-forecast app; contact via App Store listing)",
        cacheDirectory: URL? = nil
    ) {
        self.httpClient = httpClient
        self.userAgent = userAgent
        self.cacheDirectory = cacheDirectory
    }

    private func url(for coordinate: GeoCoordinate) -> URL {
        let rounded = coordinate.roundedToTenth
        var components = URLComponents(string: "https://api.met.no/weatherapi/locationforecast/2.0/compact")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.1f", rounded.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.1f", rounded.longitude))
        ]
        return components.url!
    }

    /// Cache key: MET forecasts are per-location, and this app only ever
    /// needs "the current place being viewed" cached at a time per rounded
    /// coordinate, so the rounded coordinate is embedded in the cache key.
    private func cacheKey(for coordinate: GeoCoordinate) -> String {
        let r = coordinate.roundedToTenth
        return "met_cloud_forecast_\(r.latitude)_\(r.longitude)"
    }

    private func cache(for coordinate: GeoCoordinate) -> DiskCache<Data> {
        DiskCache(filename: cacheKey(for: coordinate), directory: cacheDirectory)
    }

    public func cachedForecast(at coordinate: GeoCoordinate, now: Date = Date()) async -> (forecast: CloudForecast, freshness: DataFreshness)? {
        guard let envelope = await cache(for: coordinate).load() else { return nil }
        guard let forecast = try? CloudForecast.decode(from: envelope.value) else { return nil }
        return (forecast, envelope.freshness(now: now))
    }

    /// Fetches a new forecast if the cached one has expired per the
    /// server's `Expires` header (or there is none yet); otherwise decodes
    /// and returns the cached one untouched — this is the `Expires`
    /// obligation. When a fetch is due, `If-Modified-Since`/`If-None-Match`
    /// are sent from the last response so an unchanged forecast can come
    /// back as a cheap `304` — this is the `If-Modified-Since` obligation.
    @discardableResult
    public func refreshIfNeeded(at coordinate: GeoCoordinate, now: Date = Date()) async throws -> (forecast: CloudForecast, freshness: DataFreshness) {
        let diskCache = cache(for: coordinate)
        let existing = await diskCache.load()

        if let existing, let expiresAt = existing.expiresAt, now < expiresAt {
            let forecast = try CloudForecast.decode(from: existing.value)
            return (forecast, existing.freshness(now: now))
        }

        var request = URLRequest(url: url(for: coordinate))
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let lastModified = existing?.lastModifiedHeader {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        if let etag = existing?.etagHeader {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await httpClient.fetch(request)

        if response.statusCode == 304, let existing {
            // Not modified: keep the existing body, but refresh the
            // validity window from this response's headers so we don't
            // hammer the server again a second later.
            let newExpires = HTTPDate.parse(response.value(forHTTPHeaderField: "Expires")) ?? existing.expiresAt
            let refreshed = CacheEnvelope(
                value: existing.value,
                fetchedAt: existing.fetchedAt,
                expiresAt: newExpires,
                lastModifiedHeader: existing.lastModifiedHeader,
                etagHeader: existing.etagHeader
            )
            await diskCache.save(refreshed)
            let forecast = try CloudForecast.decode(from: existing.value)
            return (forecast, refreshed.freshness(now: now))
        }

        guard (200..<300).contains(response.statusCode) else {
            // A failed refresh falls back to whatever is cached, marked
            // stale, rather than losing the last-known forecast.
            if let existing, let forecast = try? CloudForecast.decode(from: existing.value) {
                return (forecast, .stale(asOf: existing.fetchedAt))
            }
            throw HTTPClientError.httpStatus(response.statusCode)
        }

        let forecast = try CloudForecast.decode(from: data)
        let expiresAt = HTTPDate.parse(response.value(forHTTPHeaderField: "Expires"))
        let lastModified = response.value(forHTTPHeaderField: "Last-Modified")
        let etag = response.value(forHTTPHeaderField: "ETag")
        await diskCache.save(CacheEnvelope(value: data, fetchedAt: now, expiresAt: expiresAt, lastModifiedHeader: lastModified, etagHeader: etag))
        return (forecast, .fresh(asOf: now))
    }
}
