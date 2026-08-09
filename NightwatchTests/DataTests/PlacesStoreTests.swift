import Foundation
import Testing
@testable import Nightwatch

@MainActor
struct PlacesStoreTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NightwatchPlacesStoreTests-\(UUID().uuidString)")
    }

    @Test func startsEmptyWithNoPersistedFile() {
        let store = PlacesStore(directory: tempDirectory())
        #expect(store.places.isEmpty)
    }

    @Test func addAppendsAndPersists() async throws {
        let dir = tempDirectory()
        let store = PlacesStore(directory: dir)
        let place = SavedPlace(name: "Cabin", coordinate: GeoCoordinate(latitude: 68.2, longitude: 14.6))
        store.add(place)
        #expect(store.places.count == 1)

        // Persistence is fire-and-forget; give it a moment, then load fresh.
        try await Task.sleep(nanoseconds: 200_000_000)
        let reloaded = PlacesStore(directory: dir)
        #expect(reloaded.places.count == 1)
        #expect(reloaded.places.first?.name == "Cabin")
    }

    @Test func removeDeletesByID() {
        let store = PlacesStore(directory: tempDirectory())
        let place = SavedPlace(name: "Home", coordinate: GeoCoordinate(latitude: 1, longitude: 1))
        store.add(place)
        store.remove(id: place.id)
        #expect(store.places.isEmpty)
    }

    @Test func renameUpdatesInPlace() {
        let store = PlacesStore(directory: tempDirectory())
        let place = SavedPlace(name: "Old", coordinate: GeoCoordinate(latitude: 1, longitude: 1))
        store.add(place)
        store.rename(id: place.id, to: "New")
        #expect(store.places.first?.name == "New")
    }
}
