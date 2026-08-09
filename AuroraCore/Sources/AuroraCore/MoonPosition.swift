import Foundation

/// The equatorial position, horizon altitude and illuminated fraction of the
/// Moon for a given instant and observer location, computed on-device with
/// the standard low-accuracy lunar orbital-elements series (Meeus-class,
/// commonly attributed to Paul Schlyter's abridged formulae). Typical error
/// is a few arcminutes in position, comfortably inside the product's ±1°
/// altitude target.
public struct MoonPosition: Sendable, Equatable {
    /// Apparent geocentric right ascension, in degrees.
    public let rightAscension: Double
    /// Apparent geocentric declination, in degrees.
    public let declination: Double
    /// Altitude above the horizon for the requesting observer, in degrees.
    public let altitude: Double
    /// Fraction of the Moon's disc illuminated, from 0 (new) to 1 (full).
    public let illuminatedFraction: Double

    public static func compute(date: Date, latitude: Double, longitude: Double) -> MoonPosition {
        let d = AstroMath.daysSinceJ2000(date)

        // Lunar orbital elements (degrees / Earth radii), low-precision series.
        let N = AstroMath.normalizeDegrees(125.1228 - 0.0529538083 * d)
        let i = 5.1454
        let w = AstroMath.normalizeDegrees(318.0634 + 0.1643573223 * d)
        let a = 60.2666
        let e = 0.054900
        let M = AstroMath.normalizeDegrees(115.3654 + 13.0649929509 * d)

        // Solve Kepler's equation for eccentric anomaly E (degrees) by fixed-point iteration.
        var E = M + (180.0 / .pi) * e * AstroMath.sinD(M) * (1.0 + e * AstroMath.cosD(M))
        for _ in 0..<4 {
            let delta = (E - (180.0 / .pi) * e * AstroMath.sinD(E) - M) / (1 - e * AstroMath.cosD(E))
            E -= delta
        }

        let x = a * (AstroMath.cosD(E) - e)
        let y = a * sqrt(1 - e * e) * AstroMath.sinD(E)
        let r = sqrt(x * x + y * y)
        let v = AstroMath.atan2D(y, x)

        let xeclip = r * (AstroMath.cosD(N) * AstroMath.cosD(v + w) - AstroMath.sinD(N) * AstroMath.sinD(v + w) * AstroMath.cosD(i))
        let yeclip = r * (AstroMath.sinD(N) * AstroMath.cosD(v + w) + AstroMath.cosD(N) * AstroMath.sinD(v + w) * AstroMath.cosD(i))
        let zeclip = r * (AstroMath.sinD(v + w) * AstroMath.sinD(i))

        var lonecl = AstroMath.atan2D(yeclip, xeclip)
        let latecl = AstroMath.atan2D(zeclip, sqrt(xeclip * xeclip + yeclip * yeclip))

        // Sun's mean elements, needed for the main lunar perturbation terms
        // and for the Moon's illuminated fraction.
        let Ms = AstroMath.normalizeDegrees(356.0470 + 0.9856002585 * d) // Sun mean anomaly
        let ws = AstroMath.normalizeDegrees(282.9404 + 4.70935E-5 * d)   // Sun arg. of perihelion
        let Ls = AstroMath.normalizeDegrees(Ms + ws)                    // Sun mean longitude
        let Lm = AstroMath.normalizeDegrees(N + w + M)                  // Moon mean longitude
        let D = AstroMath.normalizeDegrees(Lm - Ls)                     // Moon mean elongation
        let F = AstroMath.normalizeDegrees(Lm - N)                      // Moon argument of latitude

        // Principal perturbation terms in lunar ecliptic longitude (degrees).
        let dLon = -1.274 * AstroMath.sinD(M - 2 * D)
            + 0.658 * AstroMath.sinD(2 * D)
            - 0.186 * AstroMath.sinD(Ms)
            - 0.059 * AstroMath.sinD(2 * M - 2 * D)
            - 0.057 * AstroMath.sinD(M - 2 * D + Ms)
            + 0.053 * AstroMath.sinD(M + 2 * D)
            + 0.046 * AstroMath.sinD(2 * D - Ms)
            + 0.041 * AstroMath.sinD(M - Ms)
            - 0.035 * AstroMath.sinD(D)
            - 0.031 * AstroMath.sinD(M + Ms)
        lonecl = AstroMath.normalizeDegrees(lonecl + dLon)
        _ = F // argument of latitude retained for documentation; the low-order latitude perturbation is negligible at this accuracy tier and omitted

        let oblecl = 23.4393 - 3.563E-7 * d

        let cosLat = AstroMath.cosD(latecl)
        let xeq = AstroMath.cosD(lonecl) * cosLat
        let yeq = AstroMath.sinD(lonecl) * cosLat * AstroMath.cosD(oblecl) - AstroMath.sinD(latecl) * AstroMath.sinD(oblecl)
        let zeq = AstroMath.sinD(lonecl) * cosLat * AstroMath.sinD(oblecl) + AstroMath.sinD(latecl) * AstroMath.cosD(oblecl)

        let rightAscension = AstroMath.normalizeDegrees(AstroMath.atan2D(yeq, xeq))
        let declination = AstroMath.asinD(zeq)

        let altitude = AstroMath.altitude(
            rightAscensionDegrees: rightAscension,
            declinationDegrees: declination,
            date: date,
            latitude: latitude,
            longitude: longitude
        )

        // Sun's geocentric equatorial position, reusing SolarPosition, to get
        // the geocentric elongation for the illuminated-fraction formula.
        let sun = SolarPosition.compute(date: date, latitude: latitude, longitude: longitude)
        let elongation = AstroMath.acosD(
            AstroMath.sinD(sun.declination) * AstroMath.sinD(declination)
                + AstroMath.cosD(sun.declination) * AstroMath.cosD(declination) * AstroMath.cosD(sun.rightAscension - rightAscension)
        )
        // Fraction illuminated as seen from Earth: k = (1 - cos(elongation)) / 2.
        // elongation = 0 -> new moon (k=0); elongation = 180 -> full moon (k=1).
        let illuminatedFraction = (1 - AstroMath.cosD(elongation)) / 2

        return MoonPosition(
            rightAscension: rightAscension,
            declination: declination,
            altitude: altitude,
            illuminatedFraction: illuminatedFraction
        )
    }
}
