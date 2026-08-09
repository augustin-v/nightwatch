import Foundation
import AuroraCore

/// One night's composed verdict plus the freshness of the inputs that fed
/// it, at a specific location. This is the app's main read model — the type
/// the Tonight and Nights-ahead screens should bind to.
public struct NightForecastReport: Sendable, Equatable {
    /// The local evening this verdict is for (the anchor `VisibilityEngine`
    /// scored around — see `NightForecastService` for how "tonight" and
    /// "the next 3 nights" are anchored).
    public let nightOf: Date
    public let verdict: NightVerdict
    /// The physical inputs the verdict was scored from, kept alongside it so
    /// the UI can show real readings (Kp, cloud cover, sun altitude, moon
    /// illumination) rather than the engine's internal sub-scores.
    public let readings: [HourlyVisibilityInput]
    /// Freshness of the OVATION nowcast + Kp forecast inputs, combined.
    public let activityFreshness: DataFreshness
    /// Freshness of the MET Norway cloud forecast input.
    public let cloudFreshness: DataFreshness

    public init(
        nightOf: Date,
        verdict: NightVerdict,
        readings: [HourlyVisibilityInput] = [],
        activityFreshness: DataFreshness,
        cloudFreshness: DataFreshness
    ) {
        self.nightOf = nightOf
        self.verdict = verdict
        self.readings = readings
        self.activityFreshness = activityFreshness
        self.cloudFreshness = cloudFreshness
    }
}

extension DataFreshness {
    /// The more conservative of two freshness readings: unavailable beats
    /// stale beats fresh, and a `fresh` combination keeps the older
    /// timestamp — the view should never claim to be "as fresh" as its
    /// least-fresh input.
    static func combined(_ a: DataFreshness, _ b: DataFreshness) -> DataFreshness {
        switch (a, b) {
        case (.unavailable, _), (_, .unavailable):
            return .unavailable
        case (.stale(let d1), .stale(let d2)):
            return .stale(asOf: min(d1, d2))
        case (.stale(let d), .fresh):
            return .stale(asOf: d)
        case (.fresh, .stale(let d)):
            return .stale(asOf: d)
        case (.fresh(let d1), .fresh(let d2)):
            return .fresh(asOf: min(d1, d2))
        }
    }
}

// MARK: - Disk persistence

/// Codable mirror of one hour's *inputs* (not the scored output). This is
/// the persistence format's real design decision: `AuroraCore.HourlyVisibilityScore`
/// and `NightVerdict` deliberately expose no public initializer (they are
/// pure computed output, not a construction surface — see
/// `VisibilityEngine`), so caching the finished score for instant cold
/// launch is not possible without widening AuroraCore's API for a reason
/// that isn't a missing domain function. Caching the raw inputs and
/// re-running `VisibilityEngine.nightVerdict` (itself a cheap, synchronous,
/// pure function — no network, no disk) on load is both simpler and keeps
/// the cache trivially consistent with whatever `VisibilityEngine`'s
/// current scoring is, including if AuroraCore's formula changes.
struct HourlyVisibilityInputDTO: Codable, Sendable {
    let date: Date
    let ovationProbability: Double
    let forecastKp: Double
    let cloudFraction: Double
    let solarAltitude: Double
    let moonIllumination: Double
    let moonAltitude: Double

    init(_ input: HourlyVisibilityInput) {
        date = input.date
        ovationProbability = input.ovationProbability
        forecastKp = input.forecastKp
        cloudFraction = input.cloudFraction
        solarAltitude = input.solarAltitude
        moonIllumination = input.moonIllumination
        moonAltitude = input.moonAltitude
    }

    var input: HourlyVisibilityInput {
        HourlyVisibilityInput(
            date: date,
            ovationProbability: ovationProbability,
            forecastKp: forecastKp,
            cloudFraction: cloudFraction,
            solarAltitude: solarAltitude,
            moonIllumination: moonIllumination,
            moonAltitude: moonAltitude
        )
    }
}

struct FreshnessDTO: Codable, Sendable {
    let kind: String // "fresh" | "stale" | "unavailable"
    let asOf: Date?

    init(_ freshness: DataFreshness) {
        switch freshness {
        case .fresh(let d): kind = "fresh"; asOf = d
        case .stale(let d): kind = "stale"; asOf = d
        case .unavailable: kind = "unavailable"; asOf = nil
        }
    }

    var freshness: DataFreshness {
        switch kind {
        case "fresh": return .fresh(asOf: asOf ?? .distantPast)
        case "stale": return .stale(asOf: asOf ?? .distantPast)
        default: return .unavailable
        }
    }
}

/// One cached night: enough to reconstruct a `NightForecastReport` exactly
/// via `VisibilityEngine.nightVerdict` without any network or disk access
/// beyond this one small file.
struct NightForecastReportDTO: Codable, Sendable {
    let nightOf: Date
    let hourlyInputs: [HourlyVisibilityInputDTO]
    let observerLatitude: Double
    let observerLongitude: Double
    let activityFreshness: FreshnessDTO
    let cloudFreshness: FreshnessDTO

    init(nightOf: Date, hours: [HourlyVisibilityInput], observerLatitude: Double, observerLongitude: Double, activityFreshness: DataFreshness, cloudFreshness: DataFreshness) {
        self.nightOf = nightOf
        self.hourlyInputs = hours.map { HourlyVisibilityInputDTO($0) }
        self.observerLatitude = observerLatitude
        self.observerLongitude = observerLongitude
        self.activityFreshness = FreshnessDTO(activityFreshness)
        self.cloudFreshness = FreshnessDTO(cloudFreshness)
    }

    var report: NightForecastReport {
        let verdict = VisibilityEngine.nightVerdict(
            hours: hourlyInputs.map { $0.input },
            observerLatitude: observerLatitude,
            observerLongitude: observerLongitude
        )
        return NightForecastReport(
            nightOf: nightOf,
            verdict: verdict,
            readings: hourlyInputs.map { $0.input },
            activityFreshness: activityFreshness.freshness,
            cloudFreshness: cloudFreshness.freshness
        )
    }
}

public extension NightForecastReport {
    /// The reading for a given scored hour, matched by timestamp.
    func reading(at date: Date) -> HourlyVisibilityInput? {
        readings.first { $0.date == date }
    }
}
