import Foundation
import AuroraCore

/// The read-model protocol views should depend on, so they can be built and
/// previewed against `FixedNightForecastService` (or a test double) instead
/// of the real actor.
public protocol NightForecastProviding: Sendable {
    func cachedReports(count: Int, at location: GeoCoordinate) async -> [NightForecastReport]?
    func refreshReports(count: Int, at location: GeoCoordinate, now: Date) async -> [NightForecastReport]
}

public extension NightForecastProviding {
    func cachedTonight(at location: GeoCoordinate) async -> NightForecastReport? {
        (await cachedReports(count: 1, at: location))?.first
    }

    func refreshTonight(at location: GeoCoordinate, now: Date = Date()) async -> NightForecastReport {
        (await refreshReports(count: 1, at: location, now: now)).first!
    }
}

/// Composes the NOAA/MET network clients with AuroraCore's pure
/// `SolarPosition`/`MoonPosition`/`VisibilityEngine` into `NightVerdict`s for
/// tonight and the next few nights, at a given location. This is the app's
/// main read model.
///
/// Usage pattern for a cold launch (spec: "opens instantly and still shows a
/// clearly-timestamped last-known verdict with no network"):
/// 1. Call `cachedReports` first and render it immediately (or render an
///    empty/first-run state if it returns `nil`).
/// 2. Call `refreshReports` in the background and update the view when it
///    resolves — each underlying client independently decides whether that
///    triggers a real network fetch or reuses its own still-valid cache, so
///    calling this liberally (foreground open, `BGAppRefreshTask`) is safe.
///
/// An `actor` so it is safe to share one instance across concurrent callers
/// (foreground refresh, background task, widget-style previews) under Swift
/// 6 strict concurrency without external locking.
public actor NightForecastService: NightForecastProviding {
    private let ovationClient: OvationNowcastClient
    private let kpForecastClient: KpForecastClient
    private let currentKpClient: CurrentKpClient
    private let cloudClient: MetNorwayCloudClient
    private let reportCacheDirectory: URL?

    /// How far past the OVATION nowcast's own forecast time an hour can be
    /// and still receive the live probability at that cell, before falling
    /// back to the Kp/geomagnetic-latitude term alone. Not spec-mandated —
    /// the spec only says "pass 0 beyond the nowcast horizon" without
    /// defining that horizon precisely; 30 minutes past the nowcast's own
    /// `forecastTime` (itself ~1h ahead of the observation) is a
    /// conservative reading, flagged in the delegation report.
    private static let ovationHorizonBuffer: TimeInterval = 30 * 60

    public init(
        ovationClient: OvationNowcastClient = OvationNowcastClient(),
        kpForecastClient: KpForecastClient = KpForecastClient(),
        currentKpClient: CurrentKpClient = CurrentKpClient(),
        cloudClient: MetNorwayCloudClient = MetNorwayCloudClient(),
        reportCacheDirectory: URL? = nil
    ) {
        self.ovationClient = ovationClient
        self.kpForecastClient = kpForecastClient
        self.currentKpClient = currentKpClient
        self.cloudClient = cloudClient
        self.reportCacheDirectory = reportCacheDirectory
    }

    // MARK: Cached (cold-launch-safe) path

    public func cachedReports(count: Int, at location: GeoCoordinate) async -> [NightForecastReport]? {
        guard let envelope = await reportCache(for: location).load() else { return nil }
        let reports = envelope.value.map { $0.report }
        guard !reports.isEmpty else { return nil }
        return Array(reports.prefix(count))
    }

    // MARK: Refresh path

    @discardableResult
    public func refreshReports(count: Int, at location: GeoCoordinate, now: Date = Date()) async -> [NightForecastReport] {
        async let ovation = ovationClient.refreshIfNeeded(now: now)
        async let kp = kpForecastClient.refreshIfNeeded(now: now)
        async let current = currentKpClient.refreshIfNeeded(now: now)
        async let cloud = cloudClient.refreshIfNeeded(at: location, now: now)

        let ovationResult = try? await ovation
        let kpResult = try? await kp
        let currentResult = try? await current
        let cloudResult = try? await cloud

        // A failed refresh still has a chance to fall back to whatever was
        // last cached for each input, so the verdict degrades to "stale"
        // rather than "unavailable" whenever any prior data exists at all.
        var ovationFallback = ovationResult
        if ovationFallback == nil, let cached = await ovationClient.cachedGrid(now: now) {
            ovationFallback = (cached.grid, .stale(asOf: cached.freshness.asOf ?? .distantPast))
        }
        var kpFallback = kpResult
        if kpFallback == nil, let cached = await kpForecastClient.cachedForecast(now: now) {
            kpFallback = (cached.forecast, .stale(asOf: cached.freshness.asOf ?? .distantPast))
        }
        var currentFallback = currentResult
        if currentFallback == nil, let cached = await currentKpClient.cachedCurrent(now: now) {
            currentFallback = (cached.current, .stale(asOf: cached.freshness.asOf ?? .distantPast))
        }
        var cloudFallback = cloudResult
        if cloudFallback == nil, let cached = await cloudClient.cachedForecast(at: location, now: now) {
            cloudFallback = (cached.forecast, .stale(asOf: cached.freshness.asOf ?? .distantPast))
        }

        var reports: [NightForecastReport] = []
        var dtos: [NightForecastReportDTO] = []
        reports.reserveCapacity(count)
        dtos.reserveCapacity(count)
        for nightIndex in 0..<max(0, count) {
            let (report, hours) = composeNight(
                nightIndex: nightIndex,
                location: location,
                now: now,
                grid: ovationFallback?.0,
                gridFreshness: ovationFallback?.1 ?? .unavailable,
                kpForecast: kpFallback?.0,
                kpFreshness: kpFallback?.1 ?? .unavailable,
                currentKp: currentFallback?.0,
                cloudForecast: cloudFallback?.0,
                cloudFreshness: cloudFallback?.1 ?? .unavailable
            )
            reports.append(report)
            dtos.append(NightForecastReportDTO(
                nightOf: report.nightOf,
                hours: hours,
                observerLatitude: location.latitude,
                observerLongitude: location.longitude,
                activityFreshness: report.activityFreshness,
                cloudFreshness: report.cloudFreshness
            ))
        }

        await reportCache(for: location).save(CacheEnvelope(value: dtos, fetchedAt: now, expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))

        return reports
    }

    // MARK: Composition

    private func composeNight(
        nightIndex: Int,
        location: GeoCoordinate,
        now: Date,
        grid: OvationGrid?,
        gridFreshness: DataFreshness,
        kpForecast: KpForecast?,
        kpFreshness: DataFreshness,
        currentKp: CurrentKp?,
        cloudForecast: CloudForecast?,
        cloudFreshness: DataFreshness
    ) -> (report: NightForecastReport, hours: [HourlyVisibilityInput]) {
        let nightNoon = Self.localNoon(onOrAfter: now, longitude: location.longitude, dayOffset: nightIndex)

        var hours: [HourlyVisibilityInput] = []
        hours.reserveCapacity(25)
        var cursor = nightNoon
        let end = nightNoon.addingTimeInterval(24 * 3600)
        while cursor <= end {
            let ovationProbability: Double
            if let grid, cursor <= grid.forecastTime.addingTimeInterval(Self.ovationHorizonBuffer) {
                ovationProbability = grid.probability(latitude: location.latitude, longitude: location.longitude)
            } else {
                ovationProbability = 0
            }

            let forecastKp = Self.resolveKp(kpForecast: kpForecast, currentKp: currentKp, at: cursor, now: now)
            let cloudFraction = Self.resolveCloud(cloudForecast: cloudForecast, at: cursor)

            let solarAltitude = SolarPosition.altitude(date: cursor, latitude: location.latitude, longitude: location.longitude)
            let moon = MoonPosition.compute(date: cursor, latitude: location.latitude, longitude: location.longitude)

            hours.append(HourlyVisibilityInput(
                date: cursor,
                ovationProbability: ovationProbability,
                forecastKp: forecastKp,
                cloudFraction: cloudFraction,
                solarAltitude: solarAltitude,
                moonIllumination: moon.illuminatedFraction,
                moonAltitude: moon.altitude
            ))
            cursor = cursor.addingTimeInterval(3600)
        }

        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: location.latitude, observerLongitude: location.longitude)

        let report = NightForecastReport(
            nightOf: nightNoon,
            verdict: verdict,
            activityFreshness: .combined(gridFreshness, kpFreshness),
            cloudFreshness: cloudFreshness
        )
        return (report, hours)
    }

    /// Kp at `date`: interpolated from the forecast when in range, otherwise
    /// the nearest forecast edge, otherwise the live 1-minute reading (only
    /// sensible when `date` is close to `now`), otherwise 0 — a documented
    /// "no data" floor rather than a crash or a fabricated storm.
    private static func resolveKp(kpForecast: KpForecast?, currentKp: CurrentKp?, at date: Date, now: Date) -> Double {
        if let kpForecast, let value = kpForecast.kp(at: date) {
            return value
        }
        if let kpForecast, let first = kpForecast.points.first, let last = kpForecast.points.last {
            return date < first.time ? first.kp : last.kp
        }
        if let currentKp, abs(date.timeIntervalSince(now)) < 3600 {
            return currentKp.kpIndex
        }
        return 0
    }

    /// Cloud cover at `date`: interpolated from the forecast when in range,
    /// otherwise the nearest forecast edge. There is deliberately no "assume
    /// clear" fallback beyond the forecast's own range — this app's whole
    /// premise is not overclaiming clear skies, so an unmeasured hour
    /// inherits the nearest measured hour's reading rather than an
    /// optimistic default.
    private static func resolveCloud(cloudForecast: CloudForecast?, at date: Date) -> Double {
        if let cloudForecast, let value = cloudForecast.cloudAreaFraction(at: date) {
            return value
        }
        if let cloudForecast, let first = cloudForecast.hours.first, let last = cloudForecast.hours.last {
            return date < first.time ? first.cloudAreaFraction : last.cloudAreaFraction
        }
        // No cloud data at all (first launch, offline, MET unreachable):
        // do not claim clear skies with zero basis for it.
        return 100
    }

    /// Approximates the observer's local solar noon on/after `date`, shifted
    /// forward `dayOffset` further days, using a longitude-derived UTC
    /// offset (`longitude / 15°` per hour) rather than a timezone database
    /// lookup — this keeps the whole computation on-device and
    /// network-free, matching the rest of AuroraCore, at the cost of being
    /// off by up to ~1h from a place's *political* timezone (DST, timezone
    /// boundaries that don't track longitude). That's an acceptable
    /// approximation for "which 24h span is tonight", not for wall-clock
    /// display, which the app layer should format from the device's own
    /// `Locale`/`TimeZone` regardless.
    static func localNoon(onOrAfter date: Date, longitude: Double, dayOffset: Int = 0) -> Date {
        let offsetSeconds = Int((longitude / 15.0) * 3600.0)
        let timeZone = TimeZone(secondsFromGMT: offsetSeconds) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        var noon = calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
        if noon < date {
            noon = calendar.date(byAdding: .day, value: 1, to: noon) ?? noon
        }
        if dayOffset != 0 {
            noon = calendar.date(byAdding: .day, value: dayOffset, to: noon) ?? noon
        }
        return noon
    }

    private func reportCache(for location: GeoCoordinate) -> DiskCache<[NightForecastReportDTO]> {
        let key = "night_reports_\(location.roundedToTenth.latitude)_\(location.roundedToTenth.longitude)"
        return DiskCache(filename: key, directory: reportCacheDirectory)
    }
}
