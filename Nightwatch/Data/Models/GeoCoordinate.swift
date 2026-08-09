import Foundation

/// A location in decimal degrees. This is the one type every client and
/// service in `Data/` passes location around as, so the 1-decimal privacy
/// rounding (spec §8: coarse/precise location is used on device only, and
/// only a coarse coordinate is disclosed to MET Norway) has exactly one
/// implementation to audit.
public struct GeoCoordinate: Sendable, Equatable, Codable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Rounded to 1 decimal place (~10 km) — the exact and only precision
    /// sent to MET Norway. This is a privacy commitment made in the app's
    /// privacy policy (spec §8), so it is enforced here, in the client layer,
    /// rather than left to whichever call site happens to remember.
    public var roundedToTenth: GeoCoordinate {
        GeoCoordinate(
            latitude: (latitude * 10).rounded() / 10,
            longitude: (longitude * 10).rounded() / 10
        )
    }
}
