import Testing
@testable import Nightwatch

struct GeoCoordinateTests {
    @Test func roundsToOneDecimalPlace() {
        let c = GeoCoordinate(latitude: 59.9139, longitude: 10.7522)
        let rounded = c.roundedToTenth
        #expect(rounded.latitude == 59.9)
        #expect(rounded.longitude == 10.8)
    }

    @Test func roundsNegativeCoordinates() {
        let c = GeoCoordinate(latitude: -41.2865, longitude: 174.7762)
        let rounded = c.roundedToTenth
        #expect(rounded.latitude == -41.3)
        #expect(rounded.longitude == 174.8)
    }

    @Test func alreadyRoundedIsUnchanged() {
        let c = GeoCoordinate(latitude: 45.0, longitude: -12.5)
        #expect(c.roundedToTenth == c)
    }

    @Test func halfwayRoundsAwayFromZero() {
        let c = GeoCoordinate(latitude: 0.05, longitude: -0.05)
        let rounded = c.roundedToTenth
        #expect(rounded.latitude == 0.1)
        #expect(rounded.longitude == -0.1)
    }
}
