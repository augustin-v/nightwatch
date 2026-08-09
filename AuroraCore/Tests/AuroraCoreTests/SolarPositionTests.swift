import XCTest
@testable import AuroraCore

final class SolarPositionTests: XCTestCase {
    // Tromsø, Norway.
    let tromsoLat = 69.6489
    let tromsoLon = 18.9551

    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        c.timeZone = TimeZone(identifier: "UTC")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!
    }

    func testTromsoLateJuneNeverReachesAstronomicalTwilight() {
        let reference = date(2026, 6, 21, 12, 0) // local solar noon anchor, search covers the following night
        let result = SolarPosition.twilightWindow(
            for: .astronomical,
            searchingFrom: reference,
            latitude: tromsoLat,
            longitude: tromsoLon
        )
        XCTAssertEqual(result, .neverReached)
    }

    func testTromsoLateJuneAlsoNeverReachesNauticalTwilight() {
        // Polar day is deep enough in late June that even nautical twilight
        // is not reached — the sun stays above -12° all "night".
        let reference = date(2026, 6, 21, 12, 0)
        let result = SolarPosition.twilightWindow(
            for: .nautical,
            searchingFrom: reference,
            latitude: tromsoLat,
            longitude: tromsoLon
        )
        XCTAssertEqual(result, .neverReached)
    }

    func testTromsoDecemberIsDarkForMostOfTheDay() {
        // Tromsø sits in the polar-night zone at the December solstice: the
        // sun never rises above the horizon, but it does climb to a shallow
        // ~-3° at local solar noon — above the astronomical threshold — so
        // this is a long `.window`, not `.alwaysBelow`. Cross-checked
        // against the independent `astral` library: astronomical dusk
        // ~15:56:20Z, dawn ~05:28:36Z the next day (a ~13.5-hour dark span).
        let reference = date(2026, 12, 21, 12, 0)
        let result = SolarPosition.twilightWindow(
            for: .astronomical,
            searchingFrom: reference,
            latitude: tromsoLat,
            longitude: tromsoLon
        )
        guard case let .window(start, end) = result else {
            XCTFail("expected a window (polar night still has a brief midday twilight glow), got \(result)")
            return
        }
        let expectedStart = date(2026, 12, 21, 15, 56).addingTimeInterval(20)
        let expectedEnd = date(2026, 12, 22, 5, 28).addingTimeInterval(36)
        XCTAssertLessThanOrEqual(abs(start.timeIntervalSince(expectedStart)) / 60, 2)
        XCTAssertLessThanOrEqual(abs(end.timeIntervalSince(expectedEnd)) / 60, 2)
    }

    func testDeepPolarNightIsAlwaysBelowAstronomicalThreshold() {
        // Far enough into polar night that the sun never gets back above
        // -18° even at local solar noon: 85°S at the (southern-hemisphere)
        // winter solstice. Independently confirmed with `astral`, which
        // raises a domain error for this case (the sun never crosses -18°
        // at all), i.e. the same "always dark" condition.
        let reference = date(2026, 6, 21, 12, 0)
        let result = SolarPosition.twilightWindow(
            for: .astronomical,
            searchingFrom: reference,
            latitude: -85,
            longitude: 0
        )
        XCTAssertEqual(result, .alwaysBelow)
    }

    func testMidLatitudeCityHasOrdinaryDuskAndDawnWindow() {
        // London, summer solstice: astronomical twilight is reached briefly.
        let londonLat = 51.5074
        let londonLon = -0.1278
        let reference = date(2026, 6, 21, 12, 0)
        let result = SolarPosition.twilightWindow(
            for: .civil,
            searchingFrom: reference,
            latitude: londonLat,
            longitude: londonLon
        )
        guard case let .window(start, end) = result else {
            XCTFail("expected a window, got \(result)")
            return
        }
        XCTAssertLessThan(start, end)
    }

    func testTwilightSanityAgainstKnownValuesMidLatitude() {
        // New York City, 2026-01-15. Civil dusk (sun crosses -6°), computed
        // independently via the `astral` reference library for this
        // date/location, falls at 2026-01-15T22:23:51Z. Allow ±2 minutes
        // per the stated accuracy target, with a little slack for the two
        // low-precision solar series (this package's and astral's) to
        // disagree at the margin.
        let nycLat = 40.7128
        let nycLon = -74.0060
        let reference = date(2026, 1, 15, 12, 0)
        let result = SolarPosition.twilightWindow(
            for: .civil,
            searchingFrom: reference,
            latitude: nycLat,
            longitude: nycLon
        )
        guard case let .window(start, _) = result else {
            XCTFail("expected a window, got \(result)")
            return
        }
        let expected = date(2026, 1, 15, 22, 23).addingTimeInterval(51)
        let deltaMinutes = abs(start.timeIntervalSince(expected)) / 60
        XCTAssertLessThanOrEqual(deltaMinutes, 2, "civil dusk should be within ~2 minutes of the reference value, got \(deltaMinutes) min off")
    }

    func testDarknessFractionRampsBetweenNauticalAndAstronomical() {
        XCTAssertEqual(SolarPosition.darknessFraction(altitude: 0), 0)
        XCTAssertEqual(SolarPosition.darknessFraction(altitude: -12), 0)
        XCTAssertEqual(SolarPosition.darknessFraction(altitude: -18), 1)
        XCTAssertEqual(SolarPosition.darknessFraction(altitude: -30), 1)
        XCTAssertEqual(SolarPosition.darknessFraction(altitude: -15), 0.5, accuracy: 0.001)
    }

    func testAltitudeAtSolarNoonIsRoughlyMaximumForTheDay() {
        // Equator, equinox: sun should be very close to zenith at local
        // solar noon (longitude 0, so solar noon is ~12:00 UTC).
        let noon = date(2026, 3, 20, 12, 0)
        let altAtNoon = SolarPosition.altitude(date: noon, latitude: 0, longitude: 0)
        let altHourBefore = SolarPosition.altitude(date: noon.addingTimeInterval(-3600), latitude: 0, longitude: 0)
        let altHourAfter = SolarPosition.altitude(date: noon.addingTimeInterval(3600), latitude: 0, longitude: 0)
        XCTAssertGreaterThan(altAtNoon, altHourBefore)
        XCTAssertGreaterThan(altAtNoon, altHourAfter)
        XCTAssertGreaterThan(altAtNoon, 85)
    }
}
