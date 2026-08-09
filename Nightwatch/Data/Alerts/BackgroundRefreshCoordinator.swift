import Foundation
import BackgroundTasks

/// Ties `NightForecastService` and `AlertScheduler` together for the one
/// operation spec §2 asks for on both triggers ("On each foreground open and
/// each `BGAppRefreshTask`, recompute the next 72 h and pre-schedule local
/// notifications..."): recompute the next 72 hours and reschedule alerts.
///
/// Fully injectable — the app layer supplies where "the user's location"
/// and "the user's threshold/quiet hours" come from (`LocationService`,
/// saved-place selection, Settings state — all app-layer/view-adjacent
/// concerns this worker did not touch), so this type has no opinion on
/// where those values live.
public actor BackgroundRefreshCoordinator {
    /// Must match `BGTaskSchedulerPermittedIdentifiers` in Info.plist
    /// (already declared by the scaffold).
    public static let backgroundTaskIdentifier = "com.augustinv.nightwatch.refresh"

    private let forecastService: any NightForecastProviding
    private let alertScheduler: AlertScheduler
    private let locationProvider: @Sendable () async -> GeoCoordinate?
    private let alertThresholdProvider: @Sendable () async -> Double
    private let quietHoursProvider: @Sendable () async -> QuietHours?

    public init(
        forecastService: any NightForecastProviding,
        alertScheduler: AlertScheduler,
        locationProvider: @escaping @Sendable () async -> GeoCoordinate?,
        alertThresholdProvider: @escaping @Sendable () async -> Double,
        quietHoursProvider: @escaping @Sendable () async -> QuietHours? = { nil }
    ) {
        self.forecastService = forecastService
        self.alertScheduler = alertScheduler
        self.locationProvider = locationProvider
        self.alertThresholdProvider = alertThresholdProvider
        self.quietHoursProvider = quietHoursProvider
    }

    /// Recomputes the next 72 hours (3 nights) and reschedules alerts
    /// accordingly. Call on foreground activation and from the
    /// `BGAppRefreshTask` handler (see `BackgroundTaskRegistrar` below).
    /// Silently no-ops if no location is available yet (e.g. permission not
    /// granted, no saved place) rather than throwing — there is nothing
    /// actionable a background task can do about that.
    @discardableResult
    public func refreshAndRescheduleAlerts(now: Date = Date()) async -> [AlertWindow] {
        guard let location = await locationProvider() else { return [] }
        let reports = await forecastService.refreshReports(count: 3, at: location, now: now)
        let hourly = reports.flatMap(\.verdict.hourly).map(ScoredHour.init)
        let threshold = await alertThresholdProvider()
        let quietHours = await quietHoursProvider()
        let windows = AlertEngine.windows(from: hourly, threshold: threshold)
        await alertScheduler.reschedule(windows: windows, quietHours: quietHours, now: now)
        return windows
    }
}

/// `BGTaskScheduler` registration must happen before the app finishes
/// launching, which this worker does not do — that line belongs in
/// `Nightwatch/App/NightwatchApp.swift`, a file this delegated task left
/// untouched. See the delegation report for the exact 3 lines to add there:
/// call `BackgroundTaskRegistrar.register` once at app init with a
/// `BackgroundRefreshCoordinator` factory, and call
/// `BackgroundTaskRegistrar.scheduleNextRefresh()` after each successful
/// foreground refresh so a `BGAppRefreshTask` keeps getting re-armed.
/// A minimal explicit escape hatch for handing a known-thread-safe,
/// SDK-provided reference type across a `Task {}` boundary once, in the one
/// place (`BackgroundTaskRegistrar.register`) that genuinely needs it.
private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

public enum BackgroundTaskRegistrar {
    /// Registers the handler for `BackgroundRefreshCoordinator.backgroundTaskIdentifier`.
    /// Must be called exactly once, before `application(_:didFinishLaunchingWithOptions:)`
    /// returns (in practice: from the SwiftUI `App`'s `init()`).
    public static func register(coordinatorFactory: @escaping @Sendable () -> BackgroundRefreshCoordinator) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundRefreshCoordinator.backgroundTaskIdentifier, using: nil) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            // `BGAppRefreshTask` is a plain NSObject the SDK does not mark
            // `Sendable`, but Apple documents its methods as callable from
            // any thread/queue; the launch handler itself is already
            // delivered off the main thread, so this crossing into `Task {}`
            // is real, and boxed explicitly rather than suppressed per-call.
            let box = UncheckedSendableBox(value: appRefreshTask)
            let work = Task {
                _ = await coordinatorFactory().refreshAndRescheduleAlerts()
                scheduleNextRefresh()
                box.value.setTaskCompleted(success: true)
            }
            appRefreshTask.expirationHandler = {
                work.cancel()
            }
        }
    }

    /// Submits the next `BGAppRefreshTaskRequest`. Per spec §2, the natural
    /// call site is near local dusk (cloud cover is the fastest-moving
    /// input) — `earliestBeginDate` defaults to 6 hours out as a reasonable
    /// floor; the app layer may pass a dusk-anchored date instead once it
    /// knows the user's location.
    public static func scheduleNextRefresh(earliestBeginDate: Date = Date().addingTimeInterval(6 * 3600)) {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundRefreshCoordinator.backgroundTaskIdentifier)
        request.earliestBeginDate = earliestBeginDate
        try? BGTaskScheduler.shared.submit(request)
    }
}
