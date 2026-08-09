import SwiftUI

@main
struct NightwatchApp: App {
    /// `BGTaskScheduler.shared.register` must happen before
    /// `didFinishLaunchingWithOptions` returns, which for a SwiftUI `App`
    /// means the initialiser. This is what keeps alerts working without a
    /// server: each background wake recomputes the next 72 hours and
    /// re-schedules local notifications for the windows worth waking someone
    /// for (see `BackgroundRefreshCoordinator`).
    init() {
        BackgroundTaskRegistrar.register {
            AppServices.makeBackgroundCoordinator()
        }
        BackgroundTaskRegistrar.scheduleNextRefresh()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
