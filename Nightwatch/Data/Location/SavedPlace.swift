import Foundation

/// A user-named location saved for repeated checking (spec §3 "Places":
/// home, cabin, dark-sky site). No account, no sync — this is purely local.
public struct SavedPlace: Sendable, Equatable, Codable, Identifiable {
    public let id: UUID
    /// User-entered name. Not localized content — it's the user's own text —
    /// so it is stored as a plain string, not a String Catalog key.
    public var name: String
    public var coordinate: GeoCoordinate
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, coordinate: GeoCoordinate, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.createdAt = createdAt
    }
}

/// Persists saved places to a local JSON file.
///
/// Persistence choice: Codable-to-disk, not SwiftData. Saved places are a
/// small (single-digit to low tens of entries), flat, order-sensitive list
/// with no relationships and no need for predicate-based querying — a JSON
/// array round-trips that exactly, is trivial to unit test with a throwaway
/// directory, and avoids introducing a `@Model` schema/migration surface for
/// data this simple. If Places ever grows relational needs (e.g. per-place
/// alert history joined against place), SwiftData would earn its keep then.
///
/// `@MainActor`/`@Observable` so views can bind `places` directly; writes go
/// through a background `Task` so they never block the caller, and are
/// still serialized because `PlacesStore` itself is main-actor-isolated.
@MainActor
@Observable
public final class PlacesStore {
    public private(set) var places: [SavedPlace]

    private let fileURL: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = directory ?? DiskCache<Data>.defaultDirectory(fileManager: fileManager)
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.fileURL = base.appendingPathComponent("saved_places").appendingPathExtension("json")
        self.places = PlacesStore.load(from: fileURL)
    }

    public func add(_ place: SavedPlace) {
        places.append(place)
        persist()
    }

    public func remove(id: SavedPlace.ID) {
        places.removeAll { $0.id == id }
        persist()
    }

    public func rename(id: SavedPlace.ID, to name: String) {
        guard let index = places.firstIndex(where: { $0.id == id }) else { return }
        places[index].name = name
        persist()
    }

    private func persist() {
        let snapshot = places
        let url = fileURL
        Task.detached(priority: .utility) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func load(from url: URL) -> [SavedPlace] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SavedPlace].self, from: data)) ?? []
    }
}
