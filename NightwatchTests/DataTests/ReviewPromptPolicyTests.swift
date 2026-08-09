import Foundation
import Testing
@testable import Nightwatch

@Suite(.serialized)
struct ReviewPromptPolicyTests {
    @Test
    func requestsReviewOnlyAfterThirdSuccessfulForecast() {
        let suite = "ReviewPromptPolicyTests.thirdSuccess"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        #expect(!ReviewPromptPolicy.recordSuccessfulForecast(defaults: defaults))
        #expect(!ReviewPromptPolicy.recordSuccessfulForecast(defaults: defaults))
        #expect(ReviewPromptPolicy.recordSuccessfulForecast(defaults: defaults))
        #expect(!ReviewPromptPolicy.recordSuccessfulForecast(defaults: defaults))
    }

    @Test
    func priorRequestRemainsIneligibleAfterRelaunch() {
        let suite = "ReviewPromptPolicyTests.persisted"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(true, forKey: ReviewPromptPolicy.hasRequestedKey)

        #expect(!ReviewPromptPolicy.recordSuccessfulForecast(defaults: defaults))
    }
}
