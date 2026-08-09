import Foundation

/// The one verdict band shown to the user, per spec §4: "No chance / Slim /
/// Worth watching / Strong / Rare". No display text lives here — this is a
/// typed case the app layer localizes.
public enum VisibilityBand: Int, Sendable, Equatable, Comparable, CaseIterable {
    case none = 0
    case slim = 1
    case worthWatching = 2
    case strong = 3
    case rare = 4

    public static func < (lhs: VisibilityBand, rhs: VisibilityBand) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The single named limiting factor for the night, per spec §1/§4 ("Clouds
/// are the problem tonight"). A typed case, not a sentence — the app layer
/// composes the localized sentence around it.
public enum LimitingFactor: Sendable, Equatable {
    case darkness
    case clouds
    case activity
    case moon
    /// Nothing is limiting the night — used when the band is above `.none`
    /// and no single factor is meaningfully suppressing the score.
    case none
}

/// One hour's worth of already-resolved inputs. `VisibilityEngine` is pure:
/// it does not fetch or decode anything, it only scores what it is given.
public struct HourlyVisibilityInput: Sendable, Equatable {
    public let date: Date
    /// OVATION nowcast aurora probability at the observer's cell, percent (0-100).
    /// Pass 0 for hours beyond the nowcast horizon; the Kp/geomagnetic-latitude
    /// term still contributes to the activity sub-score for those hours.
    public let ovationProbability: Double
    /// Forecast planetary Kp for this hour (0-9).
    public let forecastKp: Double
    /// Cloud area fraction, percent (0-100).
    public let cloudFraction: Double
    /// Solar altitude, degrees (negative = below horizon).
    public let solarAltitude: Double
    /// Moon illuminated fraction (0-1).
    public let moonIllumination: Double
    /// Moon altitude, degrees (negative = below horizon).
    public let moonAltitude: Double

    public init(
        date: Date,
        ovationProbability: Double,
        forecastKp: Double,
        cloudFraction: Double,
        solarAltitude: Double,
        moonIllumination: Double,
        moonAltitude: Double
    ) {
        self.date = date
        self.ovationProbability = ovationProbability
        self.forecastKp = forecastKp
        self.cloudFraction = cloudFraction
        self.solarAltitude = solarAltitude
        self.moonIllumination = moonIllumination
        self.moonAltitude = moonAltitude
    }
}

/// Per-hour sub-scores and combined score, all 0-100.
public struct HourlyVisibilityScore: Sendable, Equatable {
    public let date: Date
    public let activity: Double
    public let clouds: Double
    public let darkness: Double
    public let moon: Double
    public let combined: Double
}

/// The full result for one night at one location.
public struct NightVerdict: Sendable, Equatable {
    public let hourly: [HourlyVisibilityScore]
    public let band: VisibilityBand
    /// The contiguous best-viewing window, if any hour qualified.
    public let bestWindow: ClosedRange<Date>?
    /// The single best instant within `bestWindow`.
    public let peak: Date?
    public let limitingFactor: LimitingFactor
}

/// Pure, deterministic scoring for "is tonight worth watching, and why".
/// Clouds and darkness are hard limiters that cap the combined score; the
/// combined score is the weakest hard factor times the activity score, never
/// an average — averaging is exactly how a competitor ends up alerting a
/// user under total overcast. Moon is a soft multiplicative penalty that
/// never drives the score to zero on its own.
public enum VisibilityEngine {
    /// Minimum combined score, out of 100, for an hour to count toward the
    /// best-viewing window.
    private static let windowThreshold: Double = 5

    // MARK: Sub-scores

    /// Activity sub-score (0-100): a blend of the live OVATION nowcast
    /// probability and a Kp-forecast-driven geomagnetic-latitude term, so
    /// hours beyond the OVATION nowcast horizon still get a reasonable
    /// estimate from the 3-day Kp forecast, and a mid-latitude viewer needs a
    /// much higher Kp than a Tromsø-class viewer for the same score.
    static func activityScore(ovationProbability: Double, forecastKp: Double, geomagneticLatitude: Double) -> Double {
        let boundary = GeomagneticLatitude.kpOvalBoundary(kp: forecastKp)
        let margin = abs(geomagneticLatitude) - boundary
        // Centered at the oval boundary (margin 0 -> 50), each degree of
        // margin worth 12 points; comfortably saturates within ~4° either
        // side, which matches the oval's typical few-degree width.
        let kpLatitudeScore = max(0, min(100, 50 + margin * 12))
        let blended = 0.5 * ovationProbability + 0.5 * kpLatitudeScore
        return max(0, min(100, blended))
    }

    /// Clouds sub-score (0-100), a hard limiter: simply the clear-sky
    /// fraction. 100% cloud cover is a 0 here regardless of everything else.
    static func cloudsScore(cloudFraction: Double) -> Double {
        max(0, min(100, 100 - cloudFraction))
    }

    /// Darkness sub-score (0-100), a hard limiter: 0 while the sun has not
    /// yet reached nautical twilight, ramped to 100 at astronomical
    /// twilight. Handles polar summer (sun never gets low enough -> always
    /// 0) and polar winter (sun never rises -> always 100) automatically,
    /// since it is a pure function of solar altitude.
    static func darknessScore(solarAltitude: Double) -> Double {
        SolarPosition.darknessFraction(altitude: solarAltitude) * 100
    }

    /// Moon sub-score (0-100), a soft penalty: 100 (no penalty) whenever the
    /// Moon is below the horizon, reduced by up to `maxPenaltyFraction` when
    /// a bright Moon is high in the sky. Never reaches 0 on its own — a full
    /// Moon overhead still leaves real, if reduced, visibility.
    static func moonScore(illumination: Double, altitude: Double) -> Double {
        let maxPenaltyFraction = 0.6
        guard altitude > 0 else { return 100 }
        let altitudeFactor = AstroMath.sinD(min(90, altitude)) // 0 at horizon, 1 at zenith
        let brightness = max(0, min(1, illumination)) * altitudeFactor
        let penalty = maxPenaltyFraction * brightness
        return 100 * (1 - penalty)
    }

    // MARK: Hourly scoring

    public static func score(
        hour: HourlyVisibilityInput,
        observerLatitude: Double,
        observerLongitude: Double
    ) -> HourlyVisibilityScore {
        let geomagLat = GeomagneticLatitude.geomagneticLatitude(latitude: observerLatitude, longitude: observerLongitude)
        let activity = activityScore(ovationProbability: hour.ovationProbability, forecastKp: hour.forecastKp, geomagneticLatitude: geomagLat)
        let clouds = cloudsScore(cloudFraction: hour.cloudFraction)
        let darkness = darknessScore(solarAltitude: hour.solarAltitude)
        let moon = moonScore(illumination: hour.moonIllumination, altitude: hour.moonAltitude)

        let hardFactor = min(clouds, darkness) / 100
        let beforeMoon = activity * hardFactor
        let combined = max(0, min(100, beforeMoon * (moon / 100)))

        return HourlyVisibilityScore(date: hour.date, activity: activity, clouds: clouds, darkness: darkness, moon: moon, combined: combined)
    }

    // MARK: Night verdict

    /// Scores every hour, picks the band from the peak combined score,
    /// finds the contiguous best-viewing window around that peak, and names
    /// the single limiting factor at the peak (or best-candidate) hour.
    ///
    /// `hours` need not be sorted; they are sorted by date internally. An
    /// empty `hours` array yields `.none` with no window and no limiting
    /// factor beyond `.none`.
    public static func nightVerdict(
        hours: [HourlyVisibilityInput],
        observerLatitude: Double,
        observerLongitude: Double
    ) -> NightVerdict {
        let sortedHours = hours.sorted { $0.date < $1.date }
        let scores = sortedHours.map { score(hour: $0, observerLatitude: observerLatitude, observerLongitude: observerLongitude) }

        guard !scores.isEmpty else {
            return NightVerdict(hourly: [], band: .none, bestWindow: nil, peak: nil, limitingFactor: .none)
        }

        guard let peakIndex = scores.indices.max(by: { scores[$0].combined < scores[$1].combined }) else {
            return NightVerdict(hourly: scores, band: .none, bestWindow: nil, peak: nil, limitingFactor: .none)
        }
        let peakScore = scores[peakIndex]

        let band = VisibilityEngine.band(for: peakScore.combined)

        var window: ClosedRange<Date>?
        var peakDate: Date?
        if peakScore.combined >= windowThreshold {
            var lo = peakIndex
            while lo > 0 && scores[lo - 1].combined >= windowThreshold { lo -= 1 }
            var hi = peakIndex
            while hi < scores.count - 1 && scores[hi + 1].combined >= windowThreshold { hi += 1 }
            window = scores[lo].date...scores[hi].date
            peakDate = peakScore.date
        }

        let limitingFactor = VisibilityEngine.limitingFactor(for: peakScore)

        return NightVerdict(hourly: scores, band: band, bestWindow: window, peak: peakDate, limitingFactor: limitingFactor)
    }

    static func band(for combinedScore: Double) -> VisibilityBand {
        switch combinedScore {
        case ..<1: return .none
        case 1..<25: return .slim
        case 25..<55: return .worthWatching
        case 55..<80: return .strong
        default: return .rare
        }
    }

    /// Names the factor most responsible for suppressing the score at a
    /// given hour. Hard limiters (darkness, clouds) take priority over the
    /// soft ones (activity, moon) when tied, since "not dark enough" or
    /// "clouded out" are the more fundamentally disqualifying explanations a
    /// user needs to hear.
    static func limitingFactor(for hourScore: HourlyVisibilityScore) -> LimitingFactor {
        let candidates: [(LimitingFactor, Double)] = [
            (.darkness, hourScore.darkness),
            (.clouds, hourScore.clouds),
            (.activity, hourScore.activity),
            (.moon, hourScore.moon)
        ]
        guard let worst = candidates.min(by: { $0.1 < $1.1 }) else { return .none }
        // If nothing is meaningfully suppressed, there is no single limiting factor.
        if worst.1 >= 95 { return .none }
        return worst.0
    }
}
