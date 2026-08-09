import Foundation

/// A cached value plus the bookkeeping needed to decide freshness and to
/// honour HTTP conditional-request caching (MET Norway's terms of use
/// require honouring `Expires` / `If-Modified-Since`, not just optimising
/// with them).
public struct CacheEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let value: T
    /// When this value was originally fetched from the network (or, after a
    /// 304, when it was first fetched — a 304 refreshes validity, not the
    /// underlying data's age).
    public let fetchedAt: Date
    /// When the server said this value stops being valid, if it said so.
    public let expiresAt: Date?
    /// The `Last-Modified` header from the response that produced `value`,
    /// echoed back as `If-Modified-Since` on the next request.
    public let lastModifiedHeader: String?
    /// The `ETag` header, if the server sent one, echoed back as `If-None-Match`.
    public let etagHeader: String?

    public init(value: T, fetchedAt: Date, expiresAt: Date?, lastModifiedHeader: String?, etagHeader: String?) {
        self.value = value
        self.fetchedAt = fetchedAt
        self.expiresAt = expiresAt
        self.lastModifiedHeader = lastModifiedHeader
        self.etagHeader = etagHeader
    }

    public func freshness(now: Date) -> DataFreshness {
        if let expiresAt, now > expiresAt {
            return .stale(asOf: fetchedAt)
        }
        return .fresh(asOf: fetchedAt)
    }
}

/// Generic on-disk JSON cache, one file per key, actor-isolated so
/// concurrent reads/writes from multiple clients under Swift 6 strict
/// concurrency are safe without a separate lock.
///
/// Persistence choice: flat JSON files under Application Support rather than
/// SwiftData. Every cached payload here is a single opaque decoded value
/// looked up by one fixed key (there is no querying, filtering or
/// relationship modelling need), so a keyed file store is the simplest thing
/// that is correct, avoids pulling `@Model` machinery into a non-visual data
/// layer, and makes "does this cache round-trip" trivial to unit test with a
/// throwaway directory.
public actor DiskCache<T: Codable & Sendable> {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(filename: String, directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = directory ?? DiskCache.defaultDirectory(fileManager: fileManager)
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.fileURL = base.appendingPathComponent(filename).appendingPathExtension("json")
    }

    public static func defaultDirectory(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("NightwatchCache", isDirectory: true)
    }

    public func load() -> CacheEnvelope<T>? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CacheEnvelope<T>.self, from: data)
    }

    public func save(_ envelope: CacheEnvelope<T>) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(envelope) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public func clear() {
        try? fileManager.removeItem(at: fileURL)
    }
}
