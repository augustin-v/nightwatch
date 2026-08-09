import Foundation

/// Composition root. One place that knows how the app's pieces are wired
/// together, so views take protocols and the background task and the UI end
/// up sharing the same configuration instead of quietly diverging.
@MainActor
final class AppServices {
    static let shared = AppServices()

    let forecastService: any NightForecastProviding
    let location = LocationService()
    let places = PlacesStore()

    private init() {
        forecastService = NightForecastService()
    }

    /// The coordinate the app should forecast for: the device's current
    /// location when we have it, otherwise the most recently saved place, so
    /// someone who declined location permission still gets a useful app.
    var activeCoordinate: GeoCoordinate? {
        location.currentCoordinate ?? places.places.last?.coordinate
    }

    /// Persisted so a background wake — which has no view hierarchy and may
    /// run long after the last launch — can still answer "where?" without
    /// waiting on CoreLocation.
    func rememberCoordinateForBackgroundRefresh(_ coordinate: GeoCoordinate) {
        UserDefaults.standard.set(coordinate.latitude, forKey: Self.lastLatitudeKey)
        UserDefaults.standard.set(coordinate.longitude, forKey: Self.lastLongitudeKey)
    }

    /// `nonisolated` because the background task runs off the main actor;
    /// UserDefaults is thread-safe, so there is nothing to serialise here.
    nonisolated static var lastKnownCoordinate: GeoCoordinate? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: lastLatitudeKey) != nil,
              defaults.object(forKey: lastLongitudeKey) != nil else { return nil }
        return GeoCoordinate(
            latitude: defaults.double(forKey: lastLatitudeKey),
            longitude: defaults.double(forKey: lastLongitudeKey)
        )
    }

    /// Score at or above which an alert is worth someone's sleep. Deliberately
    /// high by default: the entire product promise is that a notification from
    /// this app means it is actually worth going outside.
    nonisolated static var alertThreshold: Double {
        let stored = UserDefaults.standard.double(forKey: alertThresholdKey)
        return stored > 0 ? stored : 55
    }

    nonisolated private static let lastLatitudeKey = "lastKnownLatitude"
    nonisolated private static let lastLongitudeKey = "lastKnownLongitude"
    nonisolated private static let alertThresholdKey = "alertThreshold"

    /// Built fresh per background wake rather than captured, because the
    /// registration closure outlives any particular app session.
    nonisolated static func makeBackgroundCoordinator() -> BackgroundRefreshCoordinator {
        BackgroundRefreshCoordinator(
            forecastService: NightForecastService(),
            alertScheduler: AlertScheduler(),
            locationProvider: { lastKnownCoordinate },
            alertThresholdProvider: { alertThreshold }
        )
    }
}
