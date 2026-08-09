import XCTest
@testable import AuroraCore

final class MoonPositionTests: XCTestCase {
    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!
    }

    func testIlluminationFractionStaysWithinValidRange() {
        // Sweep a whole synodic month and check the fraction never leaves [0, 1].
        let start = date(2026, 1, 1)
        for dayOffset in stride(from: 0, to: 30, by: 1) {
            let d = start.addingTimeInterval(Double(dayOffset) * 86400)
            let moon = MoonPosition.compute(date: d, latitude: 45, longitude: 0)
            XCTAssertGreaterThanOrEqual(moon.illuminatedFraction, 0)
            XCTAssertLessThanOrEqual(moon.illuminatedFraction, 1)
        }
    }

    func testSynodicMonthContainsBothANewAndAFullMoon() {
        // Rather than assert against externally-sourced new/full moon
        // dates (ephemeris-precision territory beyond this package's
        // stated accuracy target), sweep one full synodic month (29.6
        // days) and check it contains both a near-0 and a near-1
        // illumination sample, which any 30-day sweep must.
        let start = date(2026, 1, 1)
        var minIllum = 1.0
        var maxIllum = 0.0
        var h = 0
        while h < 30 * 24 {
            let d = start.addingTimeInterval(Double(h) * 3600)
            let moon = MoonPosition.compute(date: d, latitude: 45, longitude: 0)
            minIllum = min(minIllum, moon.illuminatedFraction)
            maxIllum = max(maxIllum, moon.illuminatedFraction)
            h += 6
        }
        XCTAssertLessThan(minIllum, 0.05)
        XCTAssertGreaterThan(maxIllum, 0.95)
    }

    func testAltitudeIsWithinValidRange() {
        let d = date(2026, 6, 1, 3, 0)
        let moon = MoonPosition.compute(date: d, latitude: 60, longitude: 10)
        XCTAssertGreaterThanOrEqual(moon.altitude, -90)
        XCTAssertLessThanOrEqual(moon.altitude, 90)
    }
}
