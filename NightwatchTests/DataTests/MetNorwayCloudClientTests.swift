import Foundation
import Testing
@testable import Nightwatch
import AuroraCore

struct MetNorwayCloudClientTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NightwatchMetNorwayTests-\(UUID().uuidString)")
    }

    private func fixture() -> Data {
        let bundle = Bundle(for: MetBundleToken.self)
        guard let url = bundle.url(forResource: "metno_sample", withExtension: "json") else {
            Issue.record("missing metno_sample fixture")
            return Data()
        }
        return (try? Data(contentsOf: url)) ?? Data()
    }

    @Test func sendsIdentifyingUserAgent() async throws {
        let http = StubHTTPClient(responses: [.success(data: fixture())])
        let client = MetNorwayCloudClient(httpClient: http, userAgent: "TestApp/1.0 test@example.com", cacheDirectory: tempDirectory())

        _ = try await client.refreshIfNeeded(at: GeoCoordinate(latitude: 69.6489, longitude: 18.9553))

        let requests = await http.recordedRequests
        #expect(requests.first?.value(forHTTPHeaderField: "User-Agent") == "TestApp/1.0 test@example.com")
    }

    @Test func roundsCoordinateToOneDecimalInRequestURL() async throws {
        let http = StubHTTPClient(responses: [.success(data: fixture())])
        let client = MetNorwayCloudClient(httpClient: http, cacheDirectory: tempDirectory())

        _ = try await client.refreshIfNeeded(at: GeoCoordinate(latitude: 69.64893, longitude: 18.95528))

        let requests = await http.recordedRequests
        let url = try #require(requests.first?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let lat = components.queryItems?.first { $0.name == "lat" }?.value
        let lon = components.queryItems?.first { $0.name == "lon" }?.value
        #expect(lat == "69.6")
        #expect(lon == "19.0")
    }

    @Test func doesNotRefetchBeforeExpires() async throws {
        let now = Date()
        let expires = now.addingTimeInterval(3600)
        let expiresHeader = HTTPDate.formatter.string(from: expires)
        let http = StubHTTPClient(responses: [
            .success(data: fixture(), headers: ["Expires": expiresHeader, "Last-Modified": "Sun, 09 Aug 2026 08:00:00 GMT"])
        ])
        let client = MetNorwayCloudClient(httpClient: http, cacheDirectory: tempDirectory())
        let coordinate = GeoCoordinate(latitude: 60.0, longitude: 10.0)

        _ = try await client.refreshIfNeeded(at: coordinate, now: now)
        _ = try await client.refreshIfNeeded(at: coordinate, now: now.addingTimeInterval(600))

        let requestCount = await http.recordedRequests.count
        #expect(requestCount == 1)
    }

    @Test func sendsIfModifiedSinceOnceExpired() async throws {
        let now = Date()
        let expires = now.addingTimeInterval(60)
        let expiresHeader = HTTPDate.formatter.string(from: expires)
        let lastModified = "Sun, 09 Aug 2026 08:00:00 GMT"
        let http = StubHTTPClient(responses: [
            .success(data: fixture(), headers: ["Expires": expiresHeader, "Last-Modified": lastModified]),
            .notModified(headers: ["Expires": HTTPDate.formatter.string(from: now.addingTimeInterval(7200))])
        ])
        let client = MetNorwayCloudClient(httpClient: http, cacheDirectory: tempDirectory())
        let coordinate = GeoCoordinate(latitude: 60.0, longitude: 10.0)

        _ = try await client.refreshIfNeeded(at: coordinate, now: now)
        let (forecast, freshness) = try await client.refreshIfNeeded(at: coordinate, now: now.addingTimeInterval(120))

        let requests = await http.recordedRequests
        #expect(requests.count == 2)
        #expect(requests.last?.value(forHTTPHeaderField: "If-Modified-Since") == lastModified)
        #expect(!forecast.hours.isEmpty)
        #expect(freshness.isStale == false)
    }

    @Test func fallsBackToStaleCacheOnServerError() async throws {
        let now = Date()
        let expires = now.addingTimeInterval(60)
        let http = StubHTTPClient(responses: [
            .success(data: fixture(), headers: ["Expires": HTTPDate.formatter.string(from: expires)]),
            .failure(statusCode: 500)
        ])
        let client = MetNorwayCloudClient(httpClient: http, cacheDirectory: tempDirectory())
        let coordinate = GeoCoordinate(latitude: 60.0, longitude: 10.0)

        _ = try await client.refreshIfNeeded(at: coordinate, now: now)
        let (forecast, freshness) = try await client.refreshIfNeeded(at: coordinate, now: now.addingTimeInterval(120))

        #expect(!forecast.hours.isEmpty)
        #expect(freshness.isStale == true)
    }
}

private final class MetBundleToken {}
