import XCTest
@testable import AuroraCore

final class KpForecastTests: XCTestCase {
    func loadForecastFixture() throws -> KpForecast {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "kp_forecast_sample", withExtension: "json", subdirectory: "Fixtures"))
        return try KpForecast.decode(from: Data(contentsOf: url))
    }

    func loadCurrentFixture() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "kp_1m_sample", withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    func testDecodesForecastPointsSortedByTime() throws {
        let forecast = try loadForecastFixture()
        XCTAssertFalse(forecast.points.isEmpty)
        for i in 1..<forecast.points.count {
            XCTAssertLessThanOrEqual(forecast.points[i - 1].time, forecast.points[i].time)
        }
    }

    func testForecastKpAtExactSampleMatches() throws {
        let forecast = try loadForecastFixture()
        let first = try XCTUnwrap(forecast.points.first)
        XCTAssertEqual(forecast.kp(at: first.time), first.kp)
    }

    func testForecastKpInterpolatesBetweenSamples() throws {
        let forecast = try loadForecastFixture()
        let a = forecast.points[0]
        let b = forecast.points[1]
        let mid = a.time.addingTimeInterval(b.time.timeIntervalSince(a.time) / 2)
        let interpolated = try XCTUnwrap(forecast.kp(at: mid))
        let lo = min(a.kp, b.kp)
        let hi = max(a.kp, b.kp)
        XCTAssertGreaterThanOrEqual(interpolated, lo - 0.001)
        XCTAssertLessThanOrEqual(interpolated, hi + 0.001)
    }

    func testForecastKpReturnsNilOutsideHorizon() throws {
        let forecast = try loadForecastFixture()
        let last = try XCTUnwrap(forecast.points.last)
        XCTAssertNil(forecast.kp(at: last.time.addingTimeInterval(365 * 86400)))
        let first = try XCTUnwrap(forecast.points.first)
        XCTAssertNil(forecast.kp(at: first.time.addingTimeInterval(-365 * 86400)))
    }

    func testCurrentKpDecodesLatestSample() throws {
        let data = try loadCurrentFixture()
        let series = try CurrentKp.decodeSeries(from: data)
        XCTAssertFalse(series.isEmpty)
        let latest = try CurrentKp.decodeLatest(from: data)
        XCTAssertEqual(latest.time, series.last?.time)
        for i in 1..<series.count {
            XCTAssertLessThanOrEqual(series[i - 1].time, series[i].time)
        }
    }

    func testMalformedForecastThrows() {
        let bad = Data("not json".utf8)
        XCTAssertThrowsError(try KpForecast.decode(from: bad))
    }
}
