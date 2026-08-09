import Foundation

/// The equatorial position and horizon altitude of the Sun for a given
/// instant and observer location, computed on-device with the standard
/// Meeus low-accuracy solar position series (~0.01° in longitude, which
/// keeps altitude error well inside the product's ±1° target and twilight
/// crossing times inside ±2 minutes).
public struct SolarPosition: Sendable, Equatable {
    /// Apparent geocentric right ascension, in degrees.
    public let rightAscension: Double
    /// Apparent geocentric declination, in degrees.
    public let declination: Double
    /// Altitude above the horizon for the requesting observer, in degrees.
    /// Negative values are below the horizon.
    public let altitude: Double

    public static func compute(date: Date, latitude: Double, longitude: Double) -> SolarPosition {
        let t = AstroMath.julianCenturiesSinceJ2000(date)

        let l0 = AstroMath.normalizeDegrees(280.46646 + t * (36000.76983 + 0.0003032 * t))
        let m = AstroMath.normalizeDegrees(357.52911 + t * (35999.05029 - 0.0001537 * t))
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        let mrad = AstroMath.degToRad(m)
        let centerC = (1.914602 - t * (0.004817 + 0.000014 * t)) * sin(mrad)
            + (0.019993 - 0.000101 * t) * sin(2 * mrad)
            + 0.000289 * sin(3 * mrad)

        let trueLongitude = l0 + centerC
        _ = e // eccentricity kept for documentation/traceability of the series; not needed further at this accuracy tier

        let omega = 125.04 - 1934.136 * t
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * AstroMath.sinD(omega)

        let obliquity0 = 23.0 + (26.0 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let obliquityCorrected = obliquity0 + 0.00256 * AstroMath.cosD(omega)

        let sinLambda = AstroMath.sinD(apparentLongitude)
        let cosLambda = AstroMath.cosD(apparentLongitude)
        let sinEps = AstroMath.sinD(obliquityCorrected)
        let cosEps = AstroMath.cosD(obliquityCorrected)

        let declination = AstroMath.asinD(sinEps * sinLambda)
        let rightAscension = AstroMath.normalizeDegrees(
            AstroMath.atan2D(cosEps * sinLambda, cosLambda)
        )

        let altitude = AstroMath.altitude(
            rightAscensionDegrees: rightAscension,
            declinationDegrees: declination,
            date: date,
            latitude: latitude,
            longitude: longitude
        )

        return SolarPosition(rightAscension: rightAscension, declination: declination, altitude: altitude)
    }

    /// Convenience accessor for just the altitude, in degrees.
    public static func altitude(date: Date, latitude: Double, longitude: Double) -> Double {
        compute(date: date, latitude: latitude, longitude: longitude).altitude
    }
}

/// The three standard twilight altitude thresholds, in degrees of solar
/// altitude below the horizon.
public enum TwilightThreshold: Double, Sendable, CaseIterable {
    case civil = -6
    case nautical = -12
    case astronomical = -18
}

/// The result of searching for a threshold-crossing dark window across a
/// night. Extreme latitudes are first-class outcomes, not errors: this type
/// makes "the sun never gets that low tonight" (polar day) and "the sun
/// never comes back up above that level" (polar night) explicit cases a
/// caller must handle, rather than a crash, a nil, or a fabricated time.
public enum TwilightWindow: Sendable, Equatable {
    /// The sun is below `threshold` during `start..<end` within the searched
    /// night. `start` is the dusk crossing, `end` is the dawn crossing.
    case window(start: Date, end: Date)
    /// The sun never descends to `threshold` during the searched night — for
    /// example Tromsø in late June never reaches astronomical twilight.
    /// "Never dark" for that threshold, not a missing value.
    case neverReached
    /// The sun never rises back above `threshold` during the searched
    /// window — for example Tromsø in December stays below astronomical
    /// twilight all day. "Always dark" for that threshold.
    case alwaysBelow
}

public extension SolarPosition {
    /// Finds the dark window for `threshold` covering the night that starts
    /// on the evening of `referenceDate`. The search scans a 24-hour window
    /// beginning at `referenceDate` in 2-minute steps (720 samples), locates
    /// the altitude minimum (solar midnight) inside it, then looks for a
    /// downward crossing before the minimum (dusk) and an upward crossing
    /// after it (dawn), linearly interpolating between samples for
    /// sub-sample precision (~±2 minutes at these latitudes).
    ///
    /// Pass a `referenceDate` at or after local solar noon (e.g. local
    /// 12:00) for "the night starting this evening"; the search window is
    /// `[referenceDate, referenceDate + 24h]`.
    static func twilightWindow(
        for threshold: TwilightThreshold,
        searchingFrom referenceDate: Date,
        latitude: Double,
        longitude: Double
    ) -> TwilightWindow {
        let stepSeconds: TimeInterval = 120
        let sampleCount = Int(24 * 3600 / stepSeconds) // 720, i.e. every 2 minutes across 24h
        var samples: [(date: Date, altitude: Double)] = []
        samples.reserveCapacity(sampleCount + 1)
        for i in 0...sampleCount {
            let d = referenceDate.addingTimeInterval(Double(i) * stepSeconds)
            samples.append((d, altitude(date: d, latitude: latitude, longitude: longitude)))
        }

        guard let minIndex = samples.indices.min(by: { samples[$0].altitude < samples[$1].altitude }) else {
            return .neverReached
        }

        let thresh = threshold.rawValue

        // Check the whole-window extremes first: these are the genuine
        // polar-day / polar-night cases and must be decided before any
        // crossing search, since a crossing search alone cannot distinguish
        // "no crossing because it's always dark" from "no crossing because
        // the window happened to start already dark".
        if samples.allSatisfy({ $0.altitude >= thresh }) { return .neverReached }
        if samples.allSatisfy({ $0.altitude < thresh }) { return .alwaysBelow }

        // Mixed case: a genuine dusk and/or dawn crossing exists somewhere
        // in the window. Dusk is the downward crossing nearest to (at or
        // before) the altitude minimum; dawn is the upward crossing nearest
        // to (at or after) it. If the window itself starts or ends already
        // below threshold (no crossing on that side within the sampled
        // span), use that edge as a conservative boundary.
        var duskDate: Date?
        for i in stride(from: minIndex, to: 0, by: -1) {
            let prev = samples[i - 1]
            let cur = samples[i]
            if prev.altitude >= thresh && cur.altitude < thresh {
                duskDate = interpolateCrossing(prev, cur, threshold: thresh)
                break
            }
        }
        if duskDate == nil && samples[0].altitude < thresh {
            duskDate = samples[0].date
        }

        var dawnDate: Date?
        if minIndex < samples.count - 1 {
            for i in (minIndex + 1)..<samples.count {
                let prev = samples[i - 1]
                let cur = samples[i]
                if prev.altitude < thresh && cur.altitude >= thresh {
                    dawnDate = interpolateCrossing(prev, cur, threshold: thresh)
                    break
                }
            }
        }
        if dawnDate == nil && samples[samples.count - 1].altitude < thresh {
            dawnDate = samples[samples.count - 1].date
        }

        let start = duskDate ?? samples[0].date
        let end = dawnDate ?? samples[samples.count - 1].date
        return .window(start: start, end: end)
    }

    private static func interpolateCrossing(
        _ a: (date: Date, altitude: Double),
        _ b: (date: Date, altitude: Double),
        threshold: Double
    ) -> Date {
        let span = b.altitude - a.altitude
        guard span != 0 else { return a.date }
        let fraction = (threshold - a.altitude) / span
        let clamped = max(0, min(1, fraction))
        return a.date.addingTimeInterval(b.date.timeIntervalSince(a.date) * clamped)
    }

    /// The darkness sub-score used by `VisibilityEngine`: 0 while the sun is
    /// above nautical twilight (-12°), ramped linearly to 1 at astronomical
    /// twilight (-18°), and 1 (fully dark) below that.
    static func darknessFraction(altitude: Double) -> Double {
        if altitude >= TwilightThreshold.nautical.rawValue { return 0 }
        if altitude <= TwilightThreshold.astronomical.rawValue { return 1 }
        let nautical = TwilightThreshold.nautical.rawValue
        let astronomical = TwilightThreshold.astronomical.rawValue
        return (nautical - altitude) / (nautical - astronomical)
    }
}
