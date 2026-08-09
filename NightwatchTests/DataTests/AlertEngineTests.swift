import Foundation
import Testing
@testable import Nightwatch
import AuroraCore

struct AlertEngineTests {
    private func score(_ hoursFromEpoch: Int, combined: Double) -> ScoredHour {
        ScoredHour(date: Date(timeIntervalSince1970: Double(hoursFromEpoch) * 3600), combined: combined)
    }

    @Test func noWindowsWhenNothingCrossesThreshold() {
        let hourly = (0..<10).map { score($0, combined: 10) }
        #expect(AlertEngine.windows(from: hourly, threshold: 50).isEmpty)
    }

    @Test func singleContiguousWindow() {
        let hourly = [
            score(0, combined: 10),
            score(1, combined: 60),
            score(2, combined: 70),
            score(3, combined: 55),
            score(4, combined: 20)
        ]
        let windows = AlertEngine.windows(from: hourly, threshold: 50)
        #expect(windows.count == 1)
        #expect(windows[0].start == Date(timeIntervalSince1970: 3600))
        #expect(windows[0].end == Date(timeIntervalSince1970: 3 * 3600))
        #expect(windows[0].peakDate == Date(timeIntervalSince1970: 2 * 3600))
        #expect(windows[0].peakScore == 70)
    }

    @Test func multipleSeparateWindows() {
        let hourly = [
            score(0, combined: 60),
            score(1, combined: 10),
            score(2, combined: 65),
            score(3, combined: 66)
        ]
        let windows = AlertEngine.windows(from: hourly, threshold: 50)
        #expect(windows.count == 2)
        #expect(windows[0].start == Date(timeIntervalSince1970: 0))
        #expect(windows[1].start == Date(timeIntervalSince1970: 2 * 3600))
        #expect(windows[1].end == Date(timeIntervalSince1970: 3 * 3600))
    }

    @Test func dedupesOverlappingHoursAcrossStitchedNights() {
        // Two "nights" sharing a boundary hour, as NightForecastService
        // produces when concatenating consecutive nightly reports.
        let night0 = [score(0, combined: 60), score(1, combined: 70)]
        let night1 = [score(1, combined: 70), score(2, combined: 65)] // hour 1 duplicated
        let windows = AlertEngine.windows(from: night0 + night1, threshold: 50)
        #expect(windows.count == 1)
        #expect(windows[0].start == Date(timeIntervalSince1970: 0))
        #expect(windows[0].end == Date(timeIntervalSince1970: 2 * 3600))
    }

    @Test func thresholdBoundaryIsInclusive() {
        let hourly = [score(0, combined: 50)]
        let windows = AlertEngine.windows(from: hourly, threshold: 50)
        #expect(windows.count == 1)
    }

    @Test func emptyInputProducesNoWindows() {
        #expect(AlertEngine.windows(from: [], threshold: 50).isEmpty)
    }
}
