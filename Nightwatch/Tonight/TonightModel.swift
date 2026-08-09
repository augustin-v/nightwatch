import Foundation
import Observation

/// Drives the Tonight screen.
///
/// The load order is deliberate and is the whole reason the cache exists:
/// show whatever is on disk immediately — clearly labelled with how old it
/// is — then refresh in the background. Someone standing outside in the cold
/// should never see a spinner where last night's answer could have been.
@MainActor
@Observable
final class TonightModel {
    enum State: Equatable {
        case needsLocation
        case loading
        case ready(NightForecastReport)
        case unavailable
    }

    private(set) var state: State = .loading
    private(set) var isRefreshing = false

    private let services: AppServices
    private var hasStarted = false
    /// What the current `state` was actually computed for, so switching saved
    /// places re-forecasts instead of leaving the previous place's verdict on
    /// screen under a new name.
    private var loadedCoordinate: GeoCoordinate?

    init(services: AppServices = .shared) {
        self.services = services
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await load()
    }

    func refresh() async {
        await load(force: true)
    }

    /// Called when the selected place changes. Only re-forecasts when the
    /// coordinate genuinely moved, so returning to the tab does not fire a
    /// network round trip for nothing.
    func syncToActiveLocation() async {
        guard hasStarted else { return await start() }
        guard services.activeCoordinate != loadedCoordinate else { return }
        state = .loading
        await load(force: true)
    }

    /// Waits for a usable coordinate, asking CoreLocation if we're allowed to.
    ///
    /// A first fix simply returned when no coordinate was available yet and
    /// assumed the observable would bring us back — nothing did, so the
    /// screen sat on "Reading the sky…" forever. Polling the observable is
    /// unglamorous but it cannot get stuck, and it gives us a bounded wait
    /// with an honest empty state at the end of it instead of a spinner.
    private func awaitCoordinate(timeout: TimeInterval = 12) async -> GeoCoordinate? {
        if let existing = services.activeCoordinate { return existing }

        switch services.location.authorization {
        case .denied, .restricted:
            return nil
        case .notDetermined, .authorized:
            services.location.requestLocation()
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try? await Task.sleep(for: .milliseconds(400))
            if let coordinate = services.activeCoordinate { return coordinate }
            if case .denied = services.location.authorization { return nil }
            if case .restricted = services.location.authorization { return nil }
        }
        return nil
    }

    private func load(force: Bool = false) async {
        guard let coordinate = await awaitCoordinate() else {
            state = .needsLocation
            return
        }

        loadedCoordinate = coordinate
        services.rememberCoordinateForBackgroundRefresh(coordinate)

        if !force, case .loading = state,
           let cached = await services.forecastService.cachedTonight(at: coordinate) {
            state = .ready(cached)
        }

        isRefreshing = true
        let report = await services.forecastService.refreshTonight(at: coordinate)
        isRefreshing = false
        state = .ready(report)

        // A successful refresh is also the right moment to re-arm the next
        // background wake, so alerts stay scheduled for an app that is opened
        // regularly and quietly degrade for one that isn't.
        BackgroundTaskRegistrar.scheduleNextRefresh()
    }
}

extension DataFreshness {
    /// "Updated 4 min ago" style label, or nil when there is nothing honest
    /// to say. Relative formatting is locale-aware; the caller decides
    /// whether to render it as a warning.
    var localizedRelativeLabel: String? {
        guard let asOf else { return nil }
        let relative = asOf.formatted(.relative(presentation: .named))
        let key: String.LocalizationValue = isStale
            ? "tonight.freshness.stale"
            : "tonight.freshness.fresh"
        return String(format: String(localized: key), relative)
    }
}
