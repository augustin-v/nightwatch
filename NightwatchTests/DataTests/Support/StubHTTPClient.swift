import Foundation
@testable import Nightwatch

/// A scripted `HTTPClient` for hermetic, offline tests: each call to
/// `fetch` returns the next queued response (or repeats the last one), and
/// records every request made so tests can assert on headers/URLs sent.
actor StubHTTPClient: HTTPClient {
    struct Response {
        let statusCode: Int
        let data: Data
        let headers: [String: String]

        static func success(data: Data, headers: [String: String] = [:]) -> Response {
            Response(statusCode: 200, data: data, headers: headers)
        }

        static func notModified(headers: [String: String] = [:]) -> Response {
            Response(statusCode: 304, data: Data(), headers: headers)
        }

        static func failure(statusCode: Int) -> Response {
            Response(statusCode: statusCode, data: Data(), headers: [:])
        }
    }

    private var queuedResponses: [Response]
    private(set) var recordedRequests: [URLRequest] = []

    init(responses: [Response]) {
        self.queuedResponses = responses
    }

    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        recordedRequests.append(request)
        let response = queuedResponses.isEmpty ? Response(statusCode: 200, data: Data(), headers: [:]) : queuedResponses.removeFirst()
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        )!
        return (response.data, http)
    }
}
