import Foundation
import Testing
@testable import Nightwatch
import AuroraCore

struct NOAAClientsTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NightwatchNOAAClientsTests-\(UUID().uuidString)")
    }

    private func fixture(_ name: String) -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            Issue.record("missing fixture \(name)")
            return Data()
        }
        return (try? Data(contentsOf: url)) ?? Data()
    }

    // MARK: OvationNowcastClient

    @Test func ovationClientDecodesFixtureOnRefresh() async throws {
        let data = fixture("ovation_sample")
        let http = StubHTTPClient(responses: [.success(data: data)])
        let cache = DiskCache<Data>(filename: "ovation", directory: tempDirectory())
        let client = OvationNowcastClient(httpClient: http, cache: cache)

        let (grid, freshness) = try await client.refreshIfNeeded(now: Date())
        #expect(grid.probability(latitude: 66, longitude: 0) >= 0)
        #expect(freshness.isStale == false)
    }

    @Test func ovationClientDoesNotRefetchWithinThirtyMinutes() async throws {
        let data = fixture("ovation_sample")
        let http = StubHTTPClient(responses: [.success(data: data), .success(data: data)])
        let cache = DiskCache<Data>(filename: "ovation-throttle", directory: tempDirectory())
        let client = OvationNowcastClient(httpClient: http, cache: cache)

        let t0 = Date()
        _ = try await client.refreshIfNeeded(now: t0)
        _ = try await client.refreshIfNeeded(now: t0.addingTimeInterval(10 * 60)) // 10 min later: inside 30 min window

        let requestCount = await http.recordedRequests.count
        #expect(requestCount == 1)
    }

    @Test func ovationClientRefetchesAfterThirtyMinutes() async throws {
        let data = fixture("ovation_sample")
        let http = StubHTTPClient(responses: [.success(data: data), .success(data: data)])
        let cache = DiskCache<Data>(filename: "ovation-refetch", directory: tempDirectory())
        let client = OvationNowcastClient(httpClient: http, cache: cache)

        let t0 = Date()
        _ = try await client.refreshIfNeeded(now: t0)
        _ = try await client.refreshIfNeeded(now: t0.addingTimeInterval(31 * 60))

        let requestCount = await http.recordedRequests.count
        #expect(requestCount == 2)
    }

    @Test func ovationCachedGridDoesNotHitNetwork() async throws {
        let data = fixture("ovation_sample")
        let http = StubHTTPClient(responses: [.success(data: data)])
        let cache = DiskCache<Data>(filename: "ovation-cached", directory: tempDirectory())
        let client = OvationNowcastClient(httpClient: http, cache: cache)

        // Nothing cached yet.
        let before = await client.cachedGrid()
        #expect(before == nil)

        _ = try await client.refreshIfNeeded(now: Date())
        let after = await client.cachedGrid()
        #expect(after != nil)

        // cachedGrid never calls the network client.
        let requestCount = await http.recordedRequests.count
        #expect(requestCount == 1)
    }

    // MARK: KpForecastClient

    @Test func kpForecastClientDecodesFixture() async throws {
        let data = fixture("kp_forecast_sample")
        let http = StubHTTPClient(responses: [.success(data: data)])
        let cache = DiskCache<Data>(filename: "kp-forecast", directory: tempDirectory())
        let client = KpForecastClient(httpClient: http, cache: cache)

        let (forecast, _) = try await client.refreshIfNeeded(now: Date())
        #expect(!forecast.points.isEmpty)
    }

    // MARK: CurrentKpClient

    @Test func currentKpClientDecodesLatestFromFixture() async throws {
        let data = fixture("kp_1m_sample")
        let http = StubHTTPClient(responses: [.success(data: data)])
        let cache = DiskCache<Data>(filename: "current-kp", directory: tempDirectory())
        let client = CurrentKpClient(httpClient: http, cache: cache)

        let (current, _) = try await client.refreshIfNeeded(now: Date())
        #expect(current.kpIndex >= 0)
    }

    @Test func failedFetchThrowsRatherThanSilentlyDegrading() async {
        let http = StubHTTPClient(responses: [.failure(statusCode: 500)])
        let cache = DiskCache<Data>(filename: "kp-fail", directory: tempDirectory())
        let client = KpForecastClient(httpClient: http, cache: cache)

        await #expect(throws: (any Error).self) {
            _ = try await client.refreshIfNeeded(now: Date())
        }
    }
}

private final class BundleToken {}
