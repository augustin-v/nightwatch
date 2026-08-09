import Foundation
import Testing
@testable import Nightwatch

struct DiskCacheTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NightwatchDiskCacheTests-\(UUID().uuidString)")
    }

    @Test func missingFileReturnsNilOnLoad() async {
        let cache = DiskCache<String>(filename: "missing", directory: tempDirectory())
        let loaded = await cache.load()
        #expect(loaded == nil)
    }

    @Test func savedValueRoundTrips() async {
        let dir = tempDirectory()
        let cache = DiskCache<String>(filename: "roundtrip", directory: dir)
        let now = Date()
        let envelope = CacheEnvelope(value: "hello", fetchedAt: now, expiresAt: nil, lastModifiedHeader: "Mon, 01 Jan 2024 00:00:00 GMT", etagHeader: "\"abc\"")
        await cache.save(envelope)

        let loaded = await cache.load()
        #expect(loaded?.value == "hello")
        #expect(loaded?.lastModifiedHeader == "Mon, 01 Jan 2024 00:00:00 GMT")
        #expect(loaded?.etagHeader == "\"abc\"")
    }

    @Test func freshnessBeforeExpiryIsFresh() {
        let now = Date()
        let envelope = CacheEnvelope(value: "x", fetchedAt: now.addingTimeInterval(-60), expiresAt: now.addingTimeInterval(60), lastModifiedHeader: nil, etagHeader: nil)
        #expect(envelope.freshness(now: now) == .fresh(asOf: now.addingTimeInterval(-60)))
    }

    @Test func freshnessAfterExpiryIsStale() {
        let now = Date()
        let fetchedAt = now.addingTimeInterval(-120)
        let envelope = CacheEnvelope(value: "x", fetchedAt: fetchedAt, expiresAt: now.addingTimeInterval(-60), lastModifiedHeader: nil, etagHeader: nil)
        #expect(envelope.freshness(now: now) == .stale(asOf: fetchedAt))
    }

    @Test func freshnessWithNoExpiryIsAlwaysFresh() {
        let now = Date()
        let fetchedAt = now.addingTimeInterval(-3600 * 24)
        let envelope = CacheEnvelope(value: "x", fetchedAt: fetchedAt, expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil)
        #expect(envelope.freshness(now: now) == .fresh(asOf: fetchedAt))
    }

    @Test func newSaveOverwritesPrevious() async {
        let dir = tempDirectory()
        let cache = DiskCache<Int>(filename: "overwrite", directory: dir)
        await cache.save(CacheEnvelope(value: 1, fetchedAt: Date(), expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        await cache.save(CacheEnvelope(value: 2, fetchedAt: Date(), expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        let loaded = await cache.load()
        #expect(loaded?.value == 2)
    }

    @Test func clearRemovesTheFile() async {
        let dir = tempDirectory()
        let cache = DiskCache<Int>(filename: "clear-me", directory: dir)
        await cache.save(CacheEnvelope(value: 42, fetchedAt: Date(), expiresAt: nil, lastModifiedHeader: nil, etagHeader: nil))
        await cache.clear()
        let loaded = await cache.load()
        #expect(loaded == nil)
    }
}
