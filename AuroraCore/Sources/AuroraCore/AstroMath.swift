import Foundation

/// Low-level angle and time helpers shared by the solar and lunar position
/// code. Internal only — nothing here is part of the public API surface.
enum AstroMath {
    static func degToRad(_ d: Double) -> Double { d * .pi / 180.0 }
    static func radToDeg(_ r: Double) -> Double { r * 180.0 / .pi }

    static func sinD(_ d: Double) -> Double { sin(degToRad(d)) }
    static func cosD(_ d: Double) -> Double { cos(degToRad(d)) }
    static func tanD(_ d: Double) -> Double { tan(degToRad(d)) }
    static func asinD(_ x: Double) -> Double { radToDeg(asin(max(-1, min(1, x)))) }
    static func acosD(_ x: Double) -> Double { radToDeg(acos(max(-1, min(1, x)))) }
    static func atan2D(_ y: Double, _ x: Double) -> Double { radToDeg(atan2(y, x)) }

    /// Normalizes an angle in degrees to the [0, 360) range.
    static func normalizeDegrees(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        return d
    }

    /// Julian Day (UT) for a given instant.
    static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    /// Julian centuries since J2000.0 (2000-01-01T12:00:00Z), used by the
    /// low-accuracy solar position series.
    static func julianCenturiesSinceJ2000(_ date: Date) -> Double {
        (julianDay(date) - 2451545.0) / 36525.0
    }

    /// Days since J2000.0, used by the low-accuracy lunar position series.
    static func daysSinceJ2000(_ date: Date) -> Double {
        julianDay(date) - 2451545.0
    }

    /// Greenwich Mean Sidereal Time, in degrees, normalized to [0, 360).
    static func greenwichMeanSiderealTimeDegrees(_ date: Date) -> Double {
        let jd = julianDay(date)
        let t = (jd - 2451545.0) / 36525.0
        let gmst = 280.46061837
            + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * t * t
            - (t * t * t) / 38710000.0
        return normalizeDegrees(gmst)
    }

    /// Topocentric-ignoring altitude of a body given its equatorial right
    /// ascension/declination (degrees) at an instant, for an observer at
    /// (latitude, longitude) in degrees (longitude positive east). Geocentric
    /// only — no parallax correction, which is well within the product's
    /// stated ±1° accuracy target for the Moon and negligible for the Sun.
    static func altitude(
        rightAscensionDegrees: Double,
        declinationDegrees: Double,
        date: Date,
        latitude: Double,
        longitude: Double
    ) -> Double {
        let lst = normalizeDegrees(greenwichMeanSiderealTimeDegrees(date) + longitude)
        let hourAngle = normalizeDegrees(lst - rightAscensionDegrees)
        let h = hourAngle > 180 ? hourAngle - 360 : hourAngle
        let sinAlt = sinD(latitude) * sinD(declinationDegrees)
            + cosD(latitude) * cosD(declinationDegrees) * cosD(h)
        return asinD(sinAlt)
    }
}
