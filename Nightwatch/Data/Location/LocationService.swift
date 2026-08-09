import Foundation
import CoreLocation

/// Authorization state the view layer needs to react to, decoupled from
/// `CLAuthorizationStatus` so a preview/mock can produce every case without
/// touching CoreLocation.
public enum LocationAuthorization: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .notDetermined
        }
    }
}

/// CoreLocation wrapper exposing authorization state and the device's
/// current coordinate. Kept `@MainActor`/`@Observable` so views can bind to
/// it directly; the privacy-sensitive rounding for network calls (MET
/// Norway) happens downstream in `GeoCoordinate.roundedToTenth`, not here —
/// this type exposes the precise on-device coordinate because on-device use
/// (sun/moon geometry, the oval map) is exactly what spec §8 says never
/// leaves the device.
@MainActor
@Observable
public final class LocationService: NSObject {
    public private(set) var authorization: LocationAuthorization
    public private(set) var currentCoordinate: GeoCoordinate?
    public private(set) var lastError: Error?

    private let manager: CLLocationManager

    public init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        self.authorization = LocationAuthorization(manager.authorizationStatus)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestLocation() {
        manager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = LocationAuthorization(status)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            self.currentCoordinate = coordinate
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error
        }
    }
}
