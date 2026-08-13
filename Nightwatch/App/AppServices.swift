import Foundation
import Observation

/// Authoritative deterministic states available to Factory screenshot capture.
/// The raw values are the stable semantic IDs used for capture filenames.
enum FactoryScreenshotScenario: String, CaseIterable {
    case tonight
    case nights
    case ovalMap = "oval-map"
    case places
    case alerts
}

/// Deterministic launch configuration used only by App Store screenshot
/// capture. Release builds can never activate it, even if launch arguments
/// are supplied.
struct ScreenshotConfiguration {
    let isEnabled: Bool
    let scenario: FactoryScreenshotScenario?
    let selectedTab: String
    let showsAlerts: Bool
    let showsPaywall: Bool

    static var current: ScreenshotConfiguration {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let factoryMode = arguments.contains("-factoryScreenshot")
        let legacyMode = arguments.contains("-screenshotMode")
        guard factoryMode || legacyMode else {
            return ScreenshotConfiguration(isEnabled: false, scenario: nil, selectedTab: "tonight", showsAlerts: false, showsPaywall: false)
        }

        if factoryMode {
            let scenario: FactoryScreenshotScenario?
            if let index = arguments.firstIndex(of: "-factoryScreenshotState"), arguments.indices.contains(index + 1) {
                scenario = FactoryScreenshotScenario(rawValue: arguments[index + 1])
            } else {
                // No state is the discovery launch. The app still comes up in a
                // harmless deterministic default while emitting the manifest.
                scenario = nil
            }
            let selectedTab: String
            switch scenario {
            case .nights: selectedTab = "nights"
            case .ovalMap: selectedTab = "map"
            case .places: selectedTab = "places"
            default: selectedTab = "tonight"
            }
            return ScreenshotConfiguration(
                isEnabled: true,
                scenario: scenario,
                selectedTab: selectedTab,
                showsAlerts: scenario == .alerts,
                showsPaywall: false
            )
        }

        // Legacy/manual screenshot flags remain available for local debugging,
        // but Factory Phase 6 uses only the semantic contract above.
        let selectedTab: String
        if let index = arguments.firstIndex(of: "-startTab"), arguments.indices.contains(index + 1) {
            selectedTab = arguments[index + 1]
        } else {
            selectedTab = "tonight"
        }
        return ScreenshotConfiguration(
            isEnabled: true,
            scenario: nil,
            selectedTab: selectedTab,
            showsAlerts: arguments.contains("-showAlerts"),
            showsPaywall: arguments.contains("-showPaywall")
        )
#else
        return ScreenshotConfiguration(isEnabled: false, scenario: nil, selectedTab: "tonight", showsAlerts: false, showsPaywall: false)
#endif
    }

    func prepareLaunch() {
        guard isEnabled else { return }
        emitScenarioManifestIfNeeded()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(!showsPaywall, forKey: "isPremium")
        UserDefaults.standard.set(false, forKey: "nightVisionEnabled")
        UserDefaults.standard.set(true, forKey: AlertSettings.enabledKey)
        UserDefaults.standard.set(AlertSettings.defaultThreshold, forKey: AlertSettings.thresholdKey)
    }

    /// Factory discovers this generated file from the simulator data container.
    /// It is derived from `CaseIterable`; no second scenario registry exists.
    private func emitScenarioManifestIfNeeded() {
#if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-factoryScreenshot") else { return }

        struct Manifest: Encodable {
            let schemaVersion = 1
            let scenarios: [String]
        }

        let manifest = Manifest(scenarios: FactoryScreenshotScenario.allCases.map(\.rawValue))
        guard let data = try? JSONEncoder().encode(manifest),
              let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return }
        try? FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try? data.write(
            to: caches.appendingPathComponent("factory-screenshot-scenarios.json"),
            options: .atomic
        )
#endif
    }
}

/// Composition root. One place that knows how the app's pieces are wired
/// together, so views take protocols and the background task and the UI end
/// up sharing the same configuration instead of quietly diverging.
@MainActor
@Observable
final class AppServices {
    static let shared = AppServices()

    let forecastService: any NightForecastProviding
    let location: LocationService
    let places: PlacesStore

    private init() {
        let screenshot = ScreenshotConfiguration.current
        location = LocationService()

        if screenshot.isEnabled {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("nightwatch-screenshots-\(ProcessInfo.processInfo.processIdentifier)")
            let store = PlacesStore(directory: directory)
            let tromsø = SavedPlace(
                name: "Tromsø",
                coordinate: GeoCoordinate(latitude: 69.6492, longitude: 18.9553)
            )
            store.add(tromsø)
            store.add(SavedPlace(
                name: "Senja dark-sky coast",
                coordinate: GeoCoordinate(latitude: 69.3260, longitude: 17.3240)
            ))
            store.add(SavedPlace(
                name: "Lyngen cabin",
                coordinate: GeoCoordinate(latitude: 69.5767, longitude: 20.2189)
            ))
            places = store
            selectedPlaceID = tromsø.id

            let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(21 * 3600)
            forecastService = FixedNightForecastService(reports: [
                .preview(
                    nightOf: start,
                    ovationProbability: 78,
                    forecastKp: 5.2,
                    cloudFraction: 8,
                    moonIllumination: 0.18
                ),
                .preview(
                    nightOf: start.addingTimeInterval(86_400),
                    ovationProbability: 42,
                    forecastKp: 3.6,
                    cloudFraction: 24,
                    moonIllumination: 0.22
                ),
                .preview(
                    nightOf: start.addingTimeInterval(172_800),
                    ovationProbability: 63,
                    forecastKp: 4.4,
                    cloudFraction: 48,
                    moonIllumination: 0.27
                )
            ])
        } else {
            places = PlacesStore()
            forecastService = NightForecastService()
            if let raw = UserDefaults.standard.string(forKey: Self.selectedPlaceKey) {
                selectedPlaceID = UUID(uuidString: raw)
            }
        }
    }

    /// Which saved place the app is forecasting for, or `nil` for "follow my
    /// location". Owned here rather than in a view so that the Tonight,
    /// Nights-ahead and Map screens cannot disagree about where "here" is.
    ///
    /// Persisted: the places themselves survived a relaunch but the choice
    /// between them did not, so every cold launch silently snapped back to
    /// the device location while the list still showed a saved place.
    var selectedPlaceID: SavedPlace.ID? {
        didSet {
            UserDefaults.standard.set(selectedPlaceID?.uuidString, forKey: Self.selectedPlaceKey)
        }
    }

    /// The coordinate the app should forecast for: an explicitly chosen place
    /// wins, then the device's current location, then the most recently saved
    /// place, so someone who declined location permission still gets a useful
    /// app.
    var activeCoordinate: GeoCoordinate? {
        if let selectedPlaceID,
           let place = places.places.first(where: { $0.id == selectedPlaceID }) {
            return place.coordinate
        }
        return location.currentCoordinate ?? places.places.last?.coordinate
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
    ///
    /// Returns `.infinity` when alerts are switched off, so a disabled setting
    /// results in zero scheduled windows rather than relying on every caller
    /// to remember to check the toggle first.
    nonisolated static var alertThreshold: Double {
        guard AlertSettings.isEnabled else { return .infinity }
        let stored = UserDefaults.standard.double(forKey: alertThresholdKey)
        return stored > 0 ? stored : AlertSettings.defaultThreshold
    }

    nonisolated private static let selectedPlaceKey = "selectedPlaceID"
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
            alertThresholdProvider: { alertThreshold },
            quietHoursProvider: { AlertSettings.quietHours }
        )
    }
}
