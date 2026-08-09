import Foundation
import Testing
@testable import Nightwatch

@Suite(.serialized)
struct AlertSettingsTests {
    @Test
    func grantedNotificationAuthorizationEnablesAlerts() {
        let defaults = UserDefaults(suiteName: "AlertSettingsTests.granted")!
        defaults.removePersistentDomain(forName: "AlertSettingsTests.granted")

        AlertSettings.applyNotificationAuthorization(granted: true, defaults: defaults)

        #expect(defaults.bool(forKey: AlertSettings.enabledKey))
    }

    @Test
    func deniedNotificationAuthorizationLeavesAlertsDisabled() {
        let defaults = UserDefaults(suiteName: "AlertSettingsTests.denied")!
        defaults.removePersistentDomain(forName: "AlertSettingsTests.denied")

        AlertSettings.applyNotificationAuthorization(granted: false, defaults: defaults)

        #expect(!defaults.bool(forKey: AlertSettings.enabledKey))
    }
}
