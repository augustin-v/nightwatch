import SwiftUI

@main
struct NightwatchApp: App {
    /// `BGTaskScheduler.shared.register` must happen before
    /// `didFinishLaunchingWithOptions` returns, which for a SwiftUI `App`
    /// means the initialiser. This is what keeps alerts working without a
    /// server: each background wake recomputes the next 72 hours and
    /// re-schedules local notifications for the windows worth waking someone
    /// for (see `BackgroundRefreshCoordinator`).
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundTaskRegistrar.register {
            AppServices.makeBackgroundCoordinator()
        }
        BackgroundTaskRegistrar.scheduleNextRefresh()

        // Purchases and analytics configure before any view exists, so no
        // screen can appear ahead of the SDK that gates or measures it.
        PurchaseStore.configureSDKs()
        Analytics.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { _, phase in
            // Backgrounding is the last moment the app reliably gets before
            // suspension, so it is where the queued batch goes out.
            if phase == .background {
                Task { await Analytics.flush() }
            }
        }
    }
}
