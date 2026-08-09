import Foundation

/// Decoded MET Norway Locationforecast 2.0 `compact` response
/// (`api.met.no/weatherapi/locationforecast/2.0/compact`), reduced to the one
/// field the product needs: `cloud_area_fraction` per forecast hour.
public struct CloudForecast: Sendable, Equatable {
    public struct HourlyCloud: Sendable, Equatable {
        public let time: Date
        /// Cloud area fraction, percent (0-100).
        public let cloudAreaFraction: Double
    }

    /// Ascending by time.
    public let hours: [HourlyCloud]

    public enum DecodingError: Error, Equatable {
        case empty
        case malformedTimeseries
    }

    public static func decode(from data: Data) throws -> CloudForecast {
        let raw = try JSONDecoder().decode(RawResponse.self, from: data)
        let series = raw.properties.timeseries
        guard !series.isEmpty else { throw DecodingError.empty }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var hours: [HourlyCloud] = []
        hours.reserveCapacity(series.count)
        for entry in series {
            guard let date = formatter.date(from: entry.time) else { throw DecodingError.malformedTimeseries }
            hours.append(HourlyCloud(
                time: date,
                cloudAreaFraction: entry.data.instant.details.cloudAreaFraction
            ))
        }
        hours.sort { $0.time < $1.time }
        return CloudForecast(hours: hours)
    }

    /// Cloud area fraction (percent) for an arbitrary hour: the exact match
    /// if present, otherwise linear interpolation between the two
    /// bracketing samples. Returns `nil` when `date` falls outside the
    /// decoded forecast range.
    public func cloudAreaFraction(at date: Date) -> Double? {
        guard let first = hours.first, let last = hours.last else { return nil }
        if date < first.time || date > last.time { return nil }
        if let exact = hours.first(where: { $0.time == date }) { return exact.cloudAreaFraction }
        for i in 1..<hours.count {
            let a = hours[i - 1]
            let b = hours[i]
            if a.time <= date && date <= b.time {
                let span = b.time.timeIntervalSince(a.time)
                guard span > 0 else { return a.cloudAreaFraction }
                let f = date.timeIntervalSince(a.time) / span
                return a.cloudAreaFraction + (b.cloudAreaFraction - a.cloudAreaFraction) * f
            }
        }
        return nil
    }

    private struct RawResponse: Decodable {
        let properties: RawProperties
    }
    private struct RawProperties: Decodable {
        let timeseries: [RawTimeseriesEntry]
    }
    private struct RawTimeseriesEntry: Decodable {
        let time: String
        let data: RawData
    }
    private struct RawData: Decodable {
        let instant: RawInstant
    }
    private struct RawInstant: Decodable {
        let details: RawDetails
    }
    private struct RawDetails: Decodable {
        let cloudAreaFraction: Double

        enum CodingKeys: String, CodingKey {
            case cloudAreaFraction = "cloud_area_fraction"
        }
    }
}
