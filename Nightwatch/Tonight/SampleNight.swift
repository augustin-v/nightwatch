import Foundation
import AuroraCore

/// Hardcoded sample data for the Tonight screen's scaffold. Real fetching
/// (OVATION, Kp forecast, MET Norway cloud cover, on-device sun/moon
/// geometry) is Phase 3b — this only proves the verdict-card layout
/// against a realistic, internally-consistent shape of data by running
/// the real (already-tested) `VisibilityEngine` over static sample inputs
/// for a fixed observer near Tromsø, Norway.
enum SampleNight {
    static let observerLatitude = 69.6492
    static let observerLongitude = 18.9553

    static var verdict: NightVerdict {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 18
        components.minute = 0
        let start = calendar.date(from: components) ?? Date()

        let hours: [HourlyVisibilityInput] = (0..<8).map { offset in
            let date = calendar.date(byAdding: .hour, value: offset, to: start) ?? start
            // A gently rising-then-falling storm/clear-sky window, hand-picked
            // so the sample renders a "Worth watching" verdict with clouds
            // as a visible but non-fatal factor and a real best window.
            let shape: [Double] = [10, 25, 45, 60, 55, 40, 20, 10]
            let cloud: [Double] = [70, 55, 35, 20, 25, 40, 60, 75]
            let idx = min(offset, shape.count - 1)
            return HourlyVisibilityInput(
                date: date,
                ovationProbability: shape[idx],
                forecastKp: 4,
                cloudFraction: cloud[idx],
                solarAltitude: -14,
                moonIllumination: 0.2,
                moonAltitude: 10
            )
        }

        return VisibilityEngine.nightVerdict(
            hours: hours,
            observerLatitude: observerLatitude,
            observerLongitude: observerLongitude
        )
    }
}
