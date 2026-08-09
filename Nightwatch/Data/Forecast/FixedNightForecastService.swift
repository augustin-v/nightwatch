import Foundation
import AuroraCore

/// A `NightForecastProviding` conformance that returns fixed, injected data
/// instead of touching the network or disk. For SwiftUI previews and any
/// other place the view layer wants to render against known data — this
/// type carries no logic of its own, just data, so it stays on the correct
/// side of the visual boundary: the mastermind's view code decides how the
/// data looks, this only decides what data a preview sees.
public struct FixedNightForecastService: NightForecastProviding {
    private let reports: [NightForecastReport]

    public init(reports: [NightForecastReport]) {
        self.reports = reports
    }

    public func cachedReports(count: Int, at location: GeoCoordinate) async -> [NightForecastReport]? {
        reports.isEmpty ? nil : Array(reports.prefix(count))
    }

    public func refreshReports(count: Int, at location: GeoCoordinate, now: Date) async -> [NightForecastReport] {
        Array(reports.prefix(count))
    }
}

public extension NightForecastReport {
    /// A synthesized preview fixture, run through the real
    /// `VisibilityEngine` (not a hand-built verdict — `HourlyVisibilityScore`
    /// and `NightVerdict` intentionally have no public initializer outside
    /// AuroraCore, since they're pure computed output) so previews stay
    /// honest about what the engine actually produces. `ovationProbability`
    /// and `cloudFraction` are the two levers most useful for previewing
    /// different bands; a high probability + low cloud fraction lands
    /// around "Strong"/"Rare", a low probability or high cloud fraction
    /// lands around "Slim"/"No chance". Not used by production code paths.
    static func preview(
        nightOf: Date = Date(),
        latitude: Double = 69.6,
        longitude: Double = 19.0,
        ovationProbability: Double = 55,
        forecastKp: Double = 4,
        cloudFraction: Double = 20,
        moonIllumination: Double = 0.2
    ) -> NightForecastReport {
        let hours = (0..<12).map { i -> HourlyVisibilityInput in
            HourlyVisibilityInput(
                date: nightOf.addingTimeInterval(Double(i) * 3600),
                ovationProbability: ovationProbability,
                forecastKp: forecastKp,
                cloudFraction: cloudFraction,
                solarAltitude: -20, // comfortably below astronomical twilight
                moonIllumination: moonIllumination,
                moonAltitude: 10
            )
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: latitude, observerLongitude: longitude)
        return NightForecastReport(nightOf: nightOf, verdict: verdict, readings: hours, activityFreshness: .fresh(asOf: Date()), cloudFreshness: .fresh(asOf: Date()))
    }
}
