import Foundation
import AuroraCore

/// Fetches and caches the NOAA SWPC OVATION aurora nowcast grid
/// (`ovation_aurora_latest.json`, ~900 KB). The payload is cached as raw
/// bytes rather than a decoded `OvationGrid` so that reading cache metadata
/// (is it stale, when was it fetched) never requires decoding the grid, and
/// so a decode only ever happens when a caller actually asks for the grid —
/// never implicitly on the cold-launch path. `NightForecastService` is the
/// only intended caller in this app; it caches its own small computed
/// verdicts for instant cold launch and only reaches into this client when
/// it is actually recomputing.
public actor OvationNowcastClient {
    /// The nowcast's own update cadence (spec §2): never fetch more often
    /// than this.
    public static let minimumFetchInterval: TimeInterval = 30 * 60

    private let httpClient: HTTPClient
    private let cache: DiskCache<Data>
    private let url = URL(string: "https://services.swpc.noaa.gov/json/ovation_aurora_latest.json")!

    public init(httpClient: HTTPClient = URLSessionHTTPClient(), cache: DiskCache<Data> = DiskCache(filename: "ovation_nowcast")) {
        self.httpClient = httpClient
        self.cache = cache
    }

    /// The last successfully fetched grid, decoded from disk, without
    /// making any network request. Safe to call on the cold-launch path.
    public func cachedGrid(now: Date = Date()) async -> (grid: OvationGrid, freshness: DataFreshness)? {
        guard let envelope = await cache.load() else { return nil }
        guard let grid = try? OvationGrid.decode(from: envelope.value) else { return nil }
        return (grid, envelope.freshness(now: now))
    }

    /// Fetches a new grid only if the cached one is more than
    /// `minimumFetchInterval` old (or there is none yet); otherwise decodes
    /// and returns the cached one.
    @discardableResult
    public func refreshIfNeeded(now: Date = Date()) async throws -> (grid: OvationGrid, freshness: DataFreshness) {
        if let envelope = await cache.load(), now.timeIntervalSince(envelope.fetchedAt) < Self.minimumFetchInterval {
            let grid = try OvationGrid.decode(from: envelope.value)
            return (grid, envelope.freshness(now: now))
        }
        let (data, response) = try await httpClient.fetch(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else { throw HTTPClientError.httpStatus(response.statusCode) }
        let grid = try OvationGrid.decode(from: data)
        await cache.save(CacheEnvelope(value: data, fetchedAt: now, expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        return (grid, .fresh(asOf: now))
    }
}

/// Fetches and caches the NOAA SWPC 3-day planetary Kp forecast. The spec
/// gives an explicit cadence only for OVATION; this feed changes at most
/// every few hours upstream, so a 15-minute client-side floor is a
/// conservative default chosen here (not spec-mandated — flagged in the
/// delegation report).
public actor KpForecastClient {
    public static let minimumFetchInterval: TimeInterval = 15 * 60

    private let httpClient: HTTPClient
    private let cache: DiskCache<Data>
    private let url = URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json")!

    public init(httpClient: HTTPClient = URLSessionHTTPClient(), cache: DiskCache<Data> = DiskCache(filename: "kp_forecast")) {
        self.httpClient = httpClient
        self.cache = cache
    }

    public func cachedForecast(now: Date = Date()) async -> (forecast: KpForecast, freshness: DataFreshness)? {
        guard let envelope = await cache.load() else { return nil }
        guard let forecast = try? KpForecast.decode(from: envelope.value) else { return nil }
        return (forecast, envelope.freshness(now: now))
    }

    @discardableResult
    public func refreshIfNeeded(now: Date = Date()) async throws -> (forecast: KpForecast, freshness: DataFreshness) {
        if let envelope = await cache.load(), now.timeIntervalSince(envelope.fetchedAt) < Self.minimumFetchInterval {
            let forecast = try KpForecast.decode(from: envelope.value)
            return (forecast, envelope.freshness(now: now))
        }
        let (data, response) = try await httpClient.fetch(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else { throw HTTPClientError.httpStatus(response.statusCode) }
        let forecast = try KpForecast.decode(from: data)
        await cache.save(CacheEnvelope(value: data, fetchedAt: now, expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        return (forecast, .fresh(asOf: now))
    }
}

/// Fetches and caches the NOAA SWPC 1-minute current Kp feed, used for the
/// "right now" reading rather than the forward-looking blend.
public actor CurrentKpClient {
    public static let minimumFetchInterval: TimeInterval = 5 * 60

    private let httpClient: HTTPClient
    private let cache: DiskCache<Data>
    private let url = URL(string: "https://services.swpc.noaa.gov/json/planetary_k_index_1m.json")!

    public init(httpClient: HTTPClient = URLSessionHTTPClient(), cache: DiskCache<Data> = DiskCache(filename: "current_kp")) {
        self.httpClient = httpClient
        self.cache = cache
    }

    public func cachedCurrent(now: Date = Date()) async -> (current: CurrentKp, freshness: DataFreshness)? {
        guard let envelope = await cache.load() else { return nil }
        guard let current = try? CurrentKp.decodeLatest(from: envelope.value) else { return nil }
        return (current, envelope.freshness(now: now))
    }

    @discardableResult
    public func refreshIfNeeded(now: Date = Date()) async throws -> (current: CurrentKp, freshness: DataFreshness) {
        if let envelope = await cache.load(), now.timeIntervalSince(envelope.fetchedAt) < Self.minimumFetchInterval {
            let current = try CurrentKp.decodeLatest(from: envelope.value)
            return (current, envelope.freshness(now: now))
        }
        let (data, response) = try await httpClient.fetch(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else { throw HTTPClientError.httpStatus(response.statusCode) }
        let current = try CurrentKp.decodeLatest(from: data)
        await cache.save(CacheEnvelope(value: data, fetchedAt: now, expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        return (current, .fresh(asOf: now))
    }
}
