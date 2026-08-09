import XCTest
@testable import AuroraCore

final class CloudForecastTests: XCTestCase {
    func loadFixture() throws -> CloudForecast {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "metno_sample", withExtension: "json", subdirectory: "Fixtures"))
        return try CloudForecast.decode(from: Data(contentsOf: url))
    }

    func testDecodesHourlyCloudFractions() throws {
        let forecast = try loadFixture()
        XCTAssertFalse(forecast.hours.isEmpty)
        for hour in forecast.hours {
            XCTAssertGreaterThanOrEqual(hour.cloudAreaFraction, 0)
            XCTAssertLessThanOrEqual(hour.cloudAreaFraction, 100)
        }
    }

    func testExactHourLookupMatches() throws {
        let forecast = try loadFixture()
        let first = try XCTUnwrap(forecast.hours.first)
        XCTAssertEqual(forecast.cloudAreaFraction(at: first.time), first.cloudAreaFraction)
    }

    func testInterpolatesBetweenHours() throws {
        let forecast = try loadFixture()
        let a = forecast.hours[0]
        let b = forecast.hours[1]
        let mid = a.time.addingTimeInterval(b.time.timeIntervalSince(a.time) / 2)
        let value = try XCTUnwrap(forecast.cloudAreaFraction(at: mid))
        let lo = min(a.cloudAreaFraction, b.cloudAreaFraction)
        let hi = max(a.cloudAreaFraction, b.cloudAreaFraction)
        XCTAssertGreaterThanOrEqual(value, lo - 0.001)
        XCTAssertLessThanOrEqual(value, hi + 0.001)
    }

    func testReturnsNilOutsideForecastRange() throws {
        let forecast = try loadFixture()
        let last = try XCTUnwrap(forecast.hours.last)
        XCTAssertNil(forecast.cloudAreaFraction(at: last.time.addingTimeInterval(30 * 86400)))
    }

    func testMalformedPayloadThrows() {
        let bad = Data("{}".utf8)
        XCTAssertThrowsError(try CloudForecast.decode(from: bad))
    }
}
