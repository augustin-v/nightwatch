import Foundation
import Testing
@testable import Nightwatch
import AuroraCore

struct NightForecastServiceTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NightwatchForecastServiceTests-\(UUID().uuidString)")
    }

    private func fixture(_ name: String) -> Data {
        let bundle = Bundle(for: ForecastBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            Issue.record("missing fixture \(name)")
            return Data()
        }
        return (try? Data(contentsOf: url)) ?? Data()
    }

    private func makeService(cacheRoot: URL) -> NightForecastService {
        NightForecastService(
            ovationClient: OvationNowcastClient(
                httpClient: StubHTTPClient(responses: [.success(data: fixture("ovation_sample"))]),
                cache: DiskCache(filename: "ovation", directory: cacheRoot)
            ),
            kpForecastClient: KpForecastClient(
                httpClient: StubHTTPClient(responses: [.success(data: fixture("kp_forecast_sample"))]),
                cache: DiskCache(filename: "kp_forecast", directory: cacheRoot)
            ),
            currentKpClient: CurrentKpClient(
                httpClient: StubHTTPClient(responses: [.success(data: fixture("kp_1m_sample"))]),
                cache: DiskCache(filename: "current_kp", directory: cacheRoot)
            ),
            cloudClient: MetNorwayCloudClient(
                httpClient: StubHTTPClient(responses: [.success(data: fixture("metno_sample"))]),
                cacheDirectory: cacheRoot
            ),
            reportCacheDirectory: cacheRoot
        )
    }

    private var fixedNow: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12))!
    }

    @Test func cachedReportsIsNilBeforeAnyRefresh() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let location = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        let cached = await service.cachedReports(count: 3, at: location)
        #expect(cached == nil)
    }

    @Test func refreshComposesThreeDistinctNights() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let location = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        let reports = await service.refreshReports(count: 3, at: location, now: fixedNow)
        #expect(reports.count == 3)

        // Each night is anchored 24h apart.
        #expect(reports[1].nightOf.timeIntervalSince(reports[0].nightOf) == 24 * 3600)
        #expect(reports[2].nightOf.timeIntervalSince(reports[1].nightOf) == 24 * 3600)

        // Each night has a full hourly sweep.
        for report in reports {
            #expect(report.verdict.hourly.count == 25)
        }
    }

    @Test func refreshedReportsArePersistedAndReadableFromCache() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let location = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        let fresh = await service.refreshReports(count: 3, at: location, now: fixedNow)
        let cached = await service.cachedReports(count: 3, at: location)

        #expect(cached != nil)
        #expect(cached?.count == fresh.count)
        #expect(cached?.map(\.nightOf) == fresh.map(\.nightOf))
        #expect(cached?.map(\.verdict.band) == fresh.map(\.verdict.band))
    }

    @Test func cachedReportsHonoursRequestedCount() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let location = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        _ = await service.refreshReports(count: 3, at: location, now: fixedNow)
        let cached = await service.cachedReports(count: 1, at: location)
        #expect(cached?.count == 1)
    }

    @Test func activityFreshnessIsFreshAfterASuccessfulRefresh() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let location = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        let reports = await service.refreshReports(count: 1, at: location, now: fixedNow)
        #expect(reports.first?.activityFreshness.isStale == false)
        #expect(reports.first?.cloudFreshness.isStale == false)
    }

    @Test func differentLocationsGetSeparateCaches() async {
        let root = tempDirectory()
        let service = makeService(cacheRoot: root)
        let oslo = GeoCoordinate(latitude: 59.9, longitude: 10.8)
        let tromso = GeoCoordinate(latitude: 69.6, longitude: 19.0)

        _ = await service.refreshReports(count: 1, at: oslo, now: fixedNow)
        let tromsoCache = await service.cachedReports(count: 1, at: tromso)
        #expect(tromsoCache == nil)
    }

    @Test func localNoonAnchorsToTheUpcomingOrCurrentNoonAtTheGivenLongitude() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 9))!
        let noon = NightForecastService.localNoon(onOrAfter: morning, longitude: 0, dayOffset: 0)
        // At longitude 0 the offset is UTC; 09:00 -> should anchor to 12:00 same day.
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12))!
        #expect(noon == expected)
    }

    @Test func localNoonRollsToNextDayWhenAlreadyPastNoon() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 20))!
        let noon = NightForecastService.localNoon(onOrAfter: evening, longitude: 0, dayOffset: 0)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 12))!
        #expect(noon == expected)
    }
}

private final class ForecastBundleToken {}
