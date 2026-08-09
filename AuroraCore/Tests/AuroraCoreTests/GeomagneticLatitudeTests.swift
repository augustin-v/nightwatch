import XCTest
@testable import AuroraCore

final class GeomagneticLatitudeTests: XCTestCase {
    func testTromsoIsWellInsideTheAuroralZoneGeomagnetically() {
        // Tromsø's real-world geomagnetic latitude is well known to be
        // roughly 67°N, which is why it sees aurora on almost any clear
        // dark night regardless of Kp.
        let lat = GeomagneticLatitude.geomagneticLatitude(latitude: 69.6489, longitude: 18.9551)
        XCTAssertEqual(lat, 67, accuracy: 3)
    }

    func testHobartTasmaniaHasSubstantialSouthernGeomagneticLatitude() {
        // This is precisely the documented incumbent failure the product
        // exists to fix: Hobart's geomagnetic latitude is around -50°,
        // making it a legitimate aurora australis viewing site during
        // strong storms, which a naive geographic-latitude-only model misses.
        let lat = GeomagneticLatitude.geomagneticLatitude(latitude: -42.88, longitude: 147.33)
        XCTAssertLessThan(lat, -40)
    }

    func testKpOvalBoundaryShrinksWithHigherKp() {
        let quiet = GeomagneticLatitude.kpOvalBoundary(kp: 0)
        let storm = GeomagneticLatitude.kpOvalBoundary(kp: 8)
        XCTAssertLessThan(storm, quiet)
    }
}
