import Foundation

/// A decoded NOAA SWPC OVATION aurora nowcast grid
/// (`services.swpc.noaa.gov/json/ovation_aurora_latest.json`): a regular
/// longitude/latitude grid of aurora probability (0-100).
///
/// The payload is decoded once into a flat, indexed array — the JSON tree is
/// not retained — so repeated lookups (one per screen refresh, one per saved
/// place) are O(1) plus a cheap bilinear blend rather than a re-scan.
public struct OvationGrid: Sendable, Equatable {
    public let observationTime: Date
    public let forecastTime: Date

    /// Grid longitudes present, ascending, degrees East in [0, 360).
    let longitudes: [Int]
    /// Grid latitudes present, ascending, degrees in [-90, 90].
    let latitudes: [Int]
    /// Longitude step between adjacent grid columns, degrees.
    let lonStep: Int
    /// Latitude step between adjacent grid rows, degrees.
    let latStep: Int
    /// Flat probability array, row-major by longitude index then latitude index:
    /// `probabilities[lonIndex * latitudes.count + latIndex]`.
    let probabilities: [Double]

    public enum DecodingError: Error, Equatable {
        case missingHeader
        case emptyGrid
        case irregularGrid
    }

    public static func decode(from data: Data) throws -> OvationGrid {
        let raw = try JSONDecoder().decode(RawPayload.self, from: data)
        guard let observationTime = OvationGrid.parseDate(raw.observationTime),
              let forecastTime = OvationGrid.parseDate(raw.forecastTime) else {
            throw DecodingError.missingHeader
        }
        guard !raw.coordinates.isEmpty else { throw DecodingError.emptyGrid }

        var lonSet = Set<Int>()
        var latSet = Set<Int>()
        lonSet.reserveCapacity(360)
        latSet.reserveCapacity(181)
        for c in raw.coordinates {
            lonSet.insert(Int(c[0].rounded()))
            latSet.insert(Int(c[1].rounded()))
        }
        let longitudes = lonSet.sorted()
        let latitudes = latSet.sorted()
        guard longitudes.count > 1, latitudes.count > 1 else { throw DecodingError.irregularGrid }

        let lonStep = longitudes[1] - longitudes[0]
        let latStep = latitudes[1] - latitudes[0]
        for k in 1..<longitudes.count where longitudes[k] - longitudes[k - 1] != lonStep {
            throw DecodingError.irregularGrid
        }
        for k in 1..<latitudes.count where latitudes[k] - latitudes[k - 1] != latStep {
            throw DecodingError.irregularGrid
        }

        var lonIndex = [Int: Int](minimumCapacity: longitudes.count)
        for (idx, lon) in longitudes.enumerated() { lonIndex[lon] = idx }
        var latIndex = [Int: Int](minimumCapacity: latitudes.count)
        for (idx, lat) in latitudes.enumerated() { latIndex[lat] = idx }

        var flat = [Double](repeating: 0, count: longitudes.count * latitudes.count)
        for c in raw.coordinates {
            let lon = Int(c[0].rounded())
            let lat = Int(c[1].rounded())
            guard let li = lonIndex[lon], let ai = latIndex[lat] else { continue }
            flat[li * latitudes.count + ai] = c[2]
        }

        return OvationGrid(
            observationTime: observationTime,
            forecastTime: forecastTime,
            longitudes: longitudes,
            latitudes: latitudes,
            lonStep: lonStep,
            latStep: latStep,
            probabilities: flat
        )
    }

    /// Aurora probability (0-100) at an arbitrary latitude/longitude via
    /// bilinear interpolation over the surrounding four grid cells, with
    /// correct wraparound at the 0°/360° longitude seam.
    public func probability(latitude: Double, longitude: Double) -> Double {
        guard !longitudes.isEmpty, !latitudes.isEmpty else { return 0 }

        let normalizedLon = AstroMath.normalizeDegrees(longitude)
        let clampedLat = max(Double(latitudes.first!), min(Double(latitudes.last!), latitude))

        let lonSpan = Double(longitudes.count) * Double(lonStep) // e.g. 360 for a full 0..359 grid
        let lonPos = normalizedLon / Double(lonStep)
        let lonIdx0 = Int(floor(lonPos)) % longitudes.count
        let lonFrac = lonPos - floor(lonPos)
        let wrapsFullCircle = lonSpan >= 360.0 - 1e-9
        let lonIdx1: Int
        if wrapsFullCircle {
            lonIdx1 = (lonIdx0 + 1) % longitudes.count
        } else {
            lonIdx1 = min(lonIdx0 + 1, longitudes.count - 1)
        }

        let latPosRaw = (clampedLat - Double(latitudes.first!)) / Double(latStep)
        var latIdx0 = Int(floor(latPosRaw))
        latIdx0 = max(0, min(latitudes.count - 1, latIdx0))
        let latIdx1 = min(latIdx0 + 1, latitudes.count - 1)
        let latFrac = latIdx1 == latIdx0 ? 0 : (latPosRaw - Double(latIdx0))

        let latCount = latitudes.count
        func value(_ loi: Int, _ lai: Int) -> Double { probabilities[loi * latCount + lai] }

        let v00 = value(lonIdx0, latIdx0)
        let v10 = value(lonIdx1, latIdx0)
        let v01 = value(lonIdx0, latIdx1)
        let v11 = value(lonIdx1, latIdx1)

        let top = v00 * (1 - lonFrac) + v10 * lonFrac
        let bottom = v01 * (1 - lonFrac) + v11 * lonFrac
        return top * (1 - latFrac) + bottom * latFrac
    }

    private struct RawPayload: Decodable {
        let observationTime: String
        let forecastTime: String
        let coordinates: [[Double]]

        enum CodingKeys: String, CodingKey {
            case observationTime = "Observation Time"
            case forecastTime = "Forecast Time"
            case coordinates
        }
    }

    private static func parseDate(_ s: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
    }
}
