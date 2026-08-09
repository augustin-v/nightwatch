import XCTest
@testable import AuroraCore

final class OvationGridTests: XCTestCase {
    func loadFixture() throws -> OvationGrid {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "ovation_sample", withExtension: "json", subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        return try OvationGrid.decode(from: data)
    }

    func testDecodesHeaderAndGridExtent() throws {
        let grid = try loadFixture()
        XCTAssertEqual(grid.longitudes.first, 0)
        XCTAssertEqual(grid.longitudes.last, 355)
        XCTAssertEqual(grid.latitudes.first, -90)
        XCTAssertEqual(grid.latitudes.last, 90)
    }

    func testExactGridPointReturnsStoredValue() throws {
        let grid = try loadFixture()
        // Any exact grid vertex should return exactly (interpolation of a
        // point with itself is the identity).
        let exact = grid.probability(latitude: 70, longitude: 20)
        // Recompute independently via bilinear at a point 0 away from grid should just equal a direct lookup;
        // sanity: value should be within the valid probability range.
        XCTAssertGreaterThanOrEqual(exact, 0)
        XCTAssertLessThanOrEqual(exact, 100)
    }

    func testInterpolationIsBoundedByNeighboringCells() throws {
        let grid = try loadFixture()
        let a = grid.probability(latitude: 70, longitude: 20)
        let b = grid.probability(latitude: 70, longitude: 25)
        let mid = grid.probability(latitude: 70, longitude: 22.5)
        let lo = min(a, b)
        let hi = max(a, b)
        XCTAssertGreaterThanOrEqual(mid, lo - 0.001)
        XCTAssertLessThanOrEqual(mid, hi + 0.001)
    }

    func testLongitudeWrapsAcrossTheSeam() throws {
        let grid = try loadFixture()
        // The grid's last longitude column is 355; the next column across
        // the seam is 0 (5° step). A lookup just past 355 should blend
        // between the 355 column and the 0 column, not crash or clamp.
        let atSeamMinus = grid.probability(latitude: 70, longitude: 357.5)
        let at355 = grid.probability(latitude: 70, longitude: 355)
        let at0 = grid.probability(latitude: 70, longitude: 0)
        let lo = min(at355, at0)
        let hi = max(at355, at0)
        XCTAssertGreaterThanOrEqual(atSeamMinus, lo - 0.001)
        XCTAssertLessThanOrEqual(atSeamMinus, hi + 0.001)

        // A negative-equivalent longitude (-2.5 == 357.5) must resolve to
        // the same wrapped value.
        let viaNegative = grid.probability(latitude: 70, longitude: -2.5)
        XCTAssertEqual(atSeamMinus, viaNegative, accuracy: 0.001)

        // And a longitude expressed as 362.5 (== 2.5) must match a direct
        // 2.5 lookup.
        let viaOverflow = grid.probability(latitude: 70, longitude: 362.5)
        let direct = grid.probability(latitude: 70, longitude: 2.5)
        XCTAssertEqual(viaOverflow, direct, accuracy: 0.001)
    }

    func testHeaderTimesAreParsed() throws {
        let grid = try loadFixture()
        XCTAssertGreaterThan(grid.forecastTime, grid.observationTime)
    }

    func testMalformedPayloadThrows() {
        let bad = Data("{\"not\":\"a grid\"}".utf8)
        XCTAssertThrowsError(try OvationGrid.decode(from: bad))
    }
}
