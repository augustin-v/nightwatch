import CoreLocation
import UserNotifications

/// Thin wrappers around the two system permission prompts onboarding
/// screens 9 and 11 trigger. No networking, no backend — just the
/// system frameworks, requested at the point the copy explains why
/// (per ONBOARDING.md and the candidate spec §5).
enum PermissionRequesters {
    static func requestNotifications() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}

/// Minimal `CLLocationManager` delegate wrapper so the location-permission
/// onboarding screen can trigger the real system prompt. Actual location
/// reads / forecast fetching are Phase 3b — this only requests permission.
@Observable
final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    func requestWhenInUse() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
}
