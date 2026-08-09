import XCTest
@testable import AuroraCore

final class VisibilityEngineTests: XCTestCase {
    let tromsoLat = 69.6489
    let tromsoLon = 18.9551

    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!
    }

    /// Builds one "night" of hourly inputs from 18:00 to 06:00 (12 hours),
    /// using real on-device solar altitude for the given date/location, and
    /// caller-supplied constants for everything else — this exercises the
    /// actual SolarPosition -> VisibilityEngine integration rather than
    /// hand-picked altitude numbers.
    func nightHours(
        eveningOf day: Date,
        latitude: Double,
        longitude: Double,
        ovationProbability: Double,
        forecastKp: Double,
        cloudFraction: Double,
        moonIllumination: Double = 0,
        moonAltitude: Double = -10
    ) -> [HourlyVisibilityInput] {
        (0..<12).map { offset in
            let t = day.addingTimeInterval(Double(18 + offset) * 3600)
            let altitude = SolarPosition.altitude(date: t, latitude: latitude, longitude: longitude)
            return HourlyVisibilityInput(
                date: t,
                ovationProbability: ovationProbability,
                forecastKp: forecastKp,
                cloudFraction: cloudFraction,
                solarAltitude: altitude,
                moonIllumination: moonIllumination,
                moonAltitude: moonAltitude
            )
        }
    }

    // MARK: Polar day / polar night

    func testTromsoLateJuneIsNeverDarkRegardlessOfHighKp() {
        let hours = nightHours(
            eveningOf: date(2026, 6, 21),
            latitude: tromsoLat,
            longitude: tromsoLon,
            ovationProbability: 95, // strong nowcast
            forecastKp: 8,          // storm-class Kp
            cloudFraction: 0        // perfectly clear
        )
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        XCTAssertEqual(verdict.band, .none)
        XCTAssertEqual(verdict.limitingFactor, .darkness)
        XCTAssertNil(verdict.bestWindow)
        for hour in verdict.hourly {
            XCTAssertEqual(hour.combined, 0, accuracy: 0.001)
        }
    }

    func testTromsoDecemberDarkAllDayPathProducesAViableNight() {
        let hours = nightHours(
            eveningOf: date(2026, 12, 21),
            latitude: tromsoLat,
            longitude: tromsoLon,
            ovationProbability: 60,
            forecastKp: 5,
            cloudFraction: 10
        )
        // Every hour should already be fully dark (astronomical twilight
        // reached) at 69.65°N in December.
        for hour in hours {
            XCTAssertLessThanOrEqual(hour.solarAltitude, -18)
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        XCTAssertGreaterThan(verdict.band, .none)
        XCTAssertNotNil(verdict.bestWindow)
        XCTAssertNotNil(verdict.peak)
        for hour in verdict.hourly {
            XCTAssertEqual(hour.darkness, 100, accuracy: 0.001)
        }
    }

    // MARK: Geomagnetic latitude gate

    func testEquatorWithKp8IsStillNoChanceViaGeomagneticLatitude() {
        let hours = (0..<6).map { i -> HourlyVisibilityInput in
            HourlyVisibilityInput(
                date: date(2026, 3, 1, 20 + i),
                ovationProbability: 0, // isolate the Kp/geomagnetic-latitude term
                forecastKp: 8,
                cloudFraction: 0,
                solarAltitude: -20, // fully dark, taken as a given input
                moonIllumination: 0,
                moonAltitude: -10
            )
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: 0, observerLongitude: 0)
        XCTAssertEqual(verdict.band, .none)
    }

    func test45NorthWithKp8HasNonZeroActivityButKp3IsEffectivelyZero() {
        func hours(kp: Double) -> [HourlyVisibilityInput] {
            (0..<6).map { i in
                HourlyVisibilityInput(
                    date: date(2026, 3, 1, 20 + i),
                    ovationProbability: 0, // isolate the Kp/geomagnetic-latitude term
                    forecastKp: kp,
                    cloudFraction: 0,
                    solarAltitude: -20,
                    moonIllumination: 0,
                    moonAltitude: -10
                )
            }
        }
        let strongVerdict = VisibilityEngine.nightVerdict(hours: hours(kp: 8), observerLatitude: 45, observerLongitude: 0)
        let weakVerdict = VisibilityEngine.nightVerdict(hours: hours(kp: 3), observerLatitude: 45, observerLongitude: 0)

        XCTAssertGreaterThan(strongVerdict.hourly.map(\.activity).max() ?? 0, 0)
        XCTAssertGreaterThan(strongVerdict.hourly.map(\.combined).max() ?? 0, 0)

        XCTAssertLessThan(weakVerdict.hourly.map(\.activity).max() ?? 100, 1)
        XCTAssertEqual(weakVerdict.band, .none)
    }

    // MARK: Hard limiter: clouds

    func testTotalOvercastWithG3StormIsNoChanceAndLimitingFactorIsClouds() {
        // This is the incumbent bug the product exists to fix: a strong
        // (G3-class, Kp ~7) storm must not produce a "go look" verdict when
        // the sky is fully overcast.
        let hours = (0..<6).map { i -> HourlyVisibilityInput in
            HourlyVisibilityInput(
                date: date(2026, 1, 10, 18 + i),
                ovationProbability: 90,
                forecastKp: 7, // G3-class
                cloudFraction: 100, // total overcast
                solarAltitude: -20, // fully dark
                moonIllumination: 0,
                moonAltitude: -10
            )
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        XCTAssertEqual(verdict.band, .none)
        XCTAssertEqual(verdict.limitingFactor, .clouds)
        for hour in verdict.hourly {
            XCTAssertEqual(hour.combined, 0, accuracy: 0.001)
        }
    }

    // MARK: Soft limiter: moon

    func testFullMoonAtHighAltitudeReducesButNeverZeroesTheScore() {
        func hours(moonIllumination: Double, moonAltitude: Double) -> [HourlyVisibilityInput] {
            (0..<6).map { i in
                HourlyVisibilityInput(
                    date: date(2026, 1, 10, 18 + i),
                    ovationProbability: 80,
                    forecastKp: 6,
                    cloudFraction: 0,
                    solarAltitude: -20,
                    moonIllumination: moonIllumination,
                    moonAltitude: moonAltitude
                )
            }
        }
        let noMoon = VisibilityEngine.nightVerdict(hours: hours(moonIllumination: 0, moonAltitude: -10), observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        let fullMoonOverhead = VisibilityEngine.nightVerdict(hours: hours(moonIllumination: 1, moonAltitude: 80), observerLatitude: tromsoLat, observerLongitude: tromsoLon)

        let noMoonPeak = noMoon.hourly.map(\.combined).max() ?? 0
        let fullMoonPeak = fullMoonOverhead.hourly.map(\.combined).max() ?? 0

        XCTAssertGreaterThan(fullMoonPeak, 0, "a full moon must never zero out the score")
        XCTAssertLessThan(fullMoonPeak, noMoonPeak, "a full moon overhead should reduce the score relative to no moon")

        for hour in fullMoonOverhead.hourly {
            XCTAssertGreaterThan(hour.moon, 0)
        }
    }

    // MARK: Southern hemisphere

    func testHobartTasmaniaWithStrongStormReturnsNonZeroScore() {
        // Documented incumbent failure: naive models score southern-
        // hemisphere mid-latitude sites near zero even during strong storms
        // because they only consider geographic, not geomagnetic, latitude.
        let hobartLat = -42.88
        let hobartLon = 147.33
        let hours = (0..<6).map { i -> HourlyVisibilityInput in
            HourlyVisibilityInput(
                date: date(2026, 7, 10, 18 + i), // southern hemisphere winter night
                ovationProbability: 0, // isolate the Kp/geomagnetic-latitude term
                forecastKp: 8, // strong storm
                cloudFraction: 0,
                solarAltitude: -20,
                moonIllumination: 0,
                moonAltitude: -10
            )
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: hobartLat, observerLongitude: hobartLon)
        XCTAssertGreaterThan(verdict.hourly.map(\.combined).max() ?? 0, 0)
        XCTAssertGreaterThan(verdict.band, .none)
    }

    // MARK: Structural / edge cases

    func testEmptyHoursYieldsNoneBandAndNoWindow() {
        let verdict = VisibilityEngine.nightVerdict(hours: [], observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        XCTAssertEqual(verdict.band, .none)
        XCTAssertNil(verdict.bestWindow)
        XCTAssertNil(verdict.peak)
        XCTAssertEqual(verdict.limitingFactor, .none)
    }

    func testBestWindowIsContiguousAroundThePeak() {
        // Build a night where the middle hours are good and the edges are
        // clouded out, and check the window excludes the clouded edges.
        let hours: [HourlyVisibilityInput] = (0..<8).map { i in
            let isGoodHour = (2...5).contains(i)
            return HourlyVisibilityInput(
                date: date(2026, 1, 10, 18 + i),
                ovationProbability: 80,
                forecastKp: 6,
                cloudFraction: isGoodHour ? 5 : 100,
                solarAltitude: -20,
                moonIllumination: 0,
                moonAltitude: -10
            )
        }
        let verdict = VisibilityEngine.nightVerdict(hours: hours, observerLatitude: tromsoLat, observerLongitude: tromsoLon)
        guard let window = verdict.bestWindow else {
            XCTFail("expected a best window")
            return
        }
        XCTAssertEqual(window.lowerBound, hours[2].date)
        XCTAssertEqual(window.upperBound, hours[5].date)
    }
}
