import Foundation
import AuroraCore

/// Hardcoded sample data for the Tonight screen's scaffold. Real fetching
/// (OVATION, Kp forecast, MET Norway cloud cover, on-device sun/moon
/// geometry) is Phase 3b — this only proves the verdict-card layout
/// against a realistic, internally-consistent shape of data by running
/// the real (already-tested) `VisibilityEngine` over static sample inputs
/// for a fixed observer near Tromsø, Norway.
enum SampleNight {
    /// Place names are proper nouns, not translatable UI copy, so this is
    /// rendered with `Text(verbatim:)` rather than routed through the catalog.
    static let placeName = "Tromsø"

    static let observerLatitude = 69.6492
    static let observerLongitude = 18.9553

    /// The inputs behind `verdict`, exposed so the factor rows can display
    /// real readings (Kp, cloud cover, sun altitude, moon illumination)
    /// rather than internal sub-scores.
    static var inputs: [HourlyVisibilityInput] { Self.build().inputs }

    static var verdict: NightVerdict { Self.build().verdict }

    private static func build() -> (inputs: [HourlyVisibilityInput], verdict: NightVerdict) {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 18
        components.minute = 0
        let start = calendar.date(from: components) ?? Date()

        // A realistic January night in Tromsø: the sun keeps sinking after
        // 18:00 and climbs back at dawn, cloud clears mid-evening then rolls
        // back in, and a thin crescent sets early. Keeping the sample
        // physically coherent matters — a flat solar altitude produced a
        // verdict that contradicted its own best window.
        let hours: [HourlyVisibilityInput] = (0..<8).map { offset in
            let date = calendar.date(byAdding: .hour, value: offset, to: start) ?? start
            let ovation: [Double] = [10, 25, 45, 60, 55, 40, 20, 10]
            let cloud: [Double] = [70, 55, 35, 20, 25, 40, 60, 75]
            let sunAltitude: [Double] = [-8, -13, -17, -20, -21, -19, -15, -10]
            let moonAltitude: [Double] = [14, 8, 2, -5, -12, -18, -22, -24]
            let idx = min(offset, ovation.count - 1)
            return HourlyVisibilityInput(
                date: date,
                ovationProbability: ovation[idx],
                forecastKp: 4,
                cloudFraction: cloud[idx],
                solarAltitude: sunAltitude[idx],
                moonIllumination: 0.18,
                moonAltitude: moonAltitude[idx]
            )
        }

        let verdict = VisibilityEngine.nightVerdict(
            hours: hours,
            observerLatitude: observerLatitude,
            observerLongitude: observerLongitude
        )
        return (hours, verdict)
    }
}
