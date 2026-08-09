import Foundation

/// Decoded NOAA SWPC planetary Kp forecast
/// (`services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json`):
/// a 3-day, 3-hour-step forecast of the planetary K index.
///
/// Note: the live endpoint returns a flat JSON array of objects
/// (`{"time_tag", "kp", "observed", "noaa_scale"}` per row), not the classic
/// SWPC "header row followed by string rows" array-of-arrays shape used by
/// some other SWPC products. This decoder matches the verified live shape.
public struct KpForecast: Sendable, Equatable {
    public struct ForecastPoint: Sendable, Equatable {
        public let time: Date
        public let kp: Double
        public let isObserved: Bool
        public let noaaScale: String?
    }

    /// Ascending by time.
    public let points: [ForecastPoint]

    public enum DecodingError: Error, Equatable {
        case empty
        case malformedRow
    }

    public static func decode(from data: Data) throws -> KpForecast {
        let rows = try JSONDecoder().decode([RawRow].self, from: data)
        guard !rows.isEmpty else { throw DecodingError.empty }
        let formatter = KpForecast.timeTagFormatter
        var points: [ForecastPoint] = []
        points.reserveCapacity(rows.count)
        for row in rows {
            guard let date = formatter.date(from: row.timeTag) else { throw DecodingError.malformedRow }
            points.append(ForecastPoint(
                time: date,
                kp: row.kp,
                isObserved: row.observed.lowercased() == "observed",
                noaaScale: row.noaaScale
            ))
        }
        points.sort { $0.time < $1.time }
        return KpForecast(points: points)
    }

    /// Forecast Kp at an arbitrary instant via linear interpolation between
    /// the two bracketing 3-hour points. Returns `nil` when `date` falls
    /// outside the decoded forecast horizon rather than extrapolating a
    /// number the caller would have no way to distinguish from a real one.
    public func kp(at date: Date) -> Double? {
        guard let first = points.first, let last = points.last else { return nil }
        if date < first.time || date > last.time { return nil }
        if let exact = points.first(where: { $0.time == date }) { return exact.kp }
        for i in 1..<points.count {
            let a = points[i - 1]
            let b = points[i]
            if a.time <= date && date <= b.time {
                let span = b.time.timeIntervalSince(a.time)
                guard span > 0 else { return a.kp }
                let f = date.timeIntervalSince(a.time) / span
                return a.kp + (b.kp - a.kp) * f
            }
        }
        return nil
    }

    private struct RawRow: Decodable {
        let timeTag: String
        let kp: Double
        let observed: String
        let noaaScale: String?

        enum CodingKeys: String, CodingKey {
            case timeTag = "time_tag"
            case kp
            case observed
            case noaaScale = "noaa_scale"
        }
    }

    static let timeTagFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()
}

/// Decoded NOAA SWPC 1-minute planetary K index feed
/// (`services.swpc.noaa.gov/json/planetary_k_index_1m.json`): a rolling
/// window of near-real-time Kp estimates.
public struct CurrentKp: Sendable, Equatable {
    public let time: Date
    public let kpIndex: Double
    public let estimatedKp: Double

    public enum DecodingError: Error, Equatable {
        case empty
        case malformedRow
    }

    /// The most recent sample in the feed.
    public static func decodeLatest(from data: Data) throws -> CurrentKp {
        let series = try decodeSeries(from: data)
        guard let last = series.last else { throw DecodingError.empty }
        return last
    }

    /// The full series, ascending by time.
    public static func decodeSeries(from data: Data) throws -> [CurrentKp] {
        let rows = try JSONDecoder().decode([RawRow].self, from: data)
        guard !rows.isEmpty else { throw DecodingError.empty }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatterNoFraction = ISO8601DateFormatter()
        formatterNoFraction.formatOptions = [.withInternetDateTime]

        var out: [CurrentKp] = []
        out.reserveCapacity(rows.count)
        for row in rows {
            let iso = row.timeTag.hasSuffix("Z") ? row.timeTag : row.timeTag + "Z"
            guard let date = formatter.date(from: iso) ?? formatterNoFraction.date(from: iso) else {
                throw DecodingError.malformedRow
            }
            out.append(CurrentKp(time: date, kpIndex: row.kpIndex, estimatedKp: row.estimatedKp))
        }
        out.sort { $0.time < $1.time }
        return out
    }

    private struct RawRow: Decodable {
        let timeTag: String
        let kpIndex: Double
        let estimatedKp: Double

        enum CodingKeys: String, CodingKey {
            case timeTag = "time_tag"
            case kpIndex = "kp_index"
            case estimatedKp = "estimated_kp"
        }
    }
}
