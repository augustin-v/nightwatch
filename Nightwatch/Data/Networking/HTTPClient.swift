import Foundation

/// The one seam every network client in `Data/` goes through. Tests inject a
/// stub conformance instead of hitting the network, per the delegated brief
/// ("Hermetic and offline — inject a URLProtocol stub or a client protocol,
/// do not hit the network in tests").
public protocol HTTPClient: Sendable {
    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse)
}

public enum HTTPClientError: Error, Sendable, Equatable {
    case invalidResponse
    case httpStatus(Int)
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HTTPClientError.invalidResponse }
        return (data, http)
    }
}

/// Shared HTTP date parsing (`Expires`, `Last-Modified`), which use the
/// RFC 1123 format (`Sun, 06 Nov 1994 08:49:37 GMT`) rather than ISO 8601.
enum HTTPDate {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "GMT")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return f
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return formatter.date(from: value)
    }
}
