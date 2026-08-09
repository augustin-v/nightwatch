import Foundation
import AuroraCore

/// A contiguous span of hours whose combined visibility score met or beat an
/// alert threshold, per spec §2 ("pre-schedule local notifications for
/// windows where the combined score crosses the user's threshold").
public struct AlertWindow: Sendable, Equatable, Identifiable {
    public var id: Date { start }
    public let start: Date
    public let end: Date
    public let peakDate: Date
    public let peakScore: Double

    public init(start: Date, end: Date, peakDate: Date, peakScore: Double) {
        self.start = start
        self.end = end
        self.peakDate = peakDate
        self.peakScore = peakScore
    }
}

/// The one hour of `HourlyVisibilityScore` that `AlertEngine` actually
/// needs: the timestamp and the combined score. `HourlyVisibilityScore`
/// itself has no public initializer outside AuroraCore (it's pure computed
/// output, not a construction surface), so `AlertEngine` depends on this
/// minimal, freely-constructible type instead — real callers map from
/// `NightVerdict.hourly`, and tests can build exact scenarios directly
/// without needing AuroraCore's internals.
public struct ScoredHour: Sendable, Equatable {
    public let date: Date
    public let combined: Double

    public init(date: Date, combined: Double) {
        self.date = date
        self.combined = combined
    }

    public init(_ score: HourlyVisibilityScore) {
        self.date = score.date
        self.combined = score.combined
    }
}

/// Pure function from hourly scores to alert windows — no scheduling, no
/// notification framework, so it is trivially unit-testable and reusable
/// from both the foreground-refresh path and the `BGAppRefreshTask` path.
public enum AlertEngine {
    /// Finds every maximal contiguous run of hours whose `combined` score is
    /// `>= threshold`, across the (possibly overlapping, possibly
    /// unsorted) hourly scores from one or more nights stitched together.
    /// Hours are deduplicated by exact timestamp before scanning, since
    /// adjacent nights' 24h windows share their boundary hour.
    public static func windows(from hourly: [ScoredHour], threshold: Double) -> [AlertWindow] {
        let sorted = dedupedSorted(hourly)
        guard !sorted.isEmpty else { return [] }

        var result: [AlertWindow] = []
        var i = 0
        while i < sorted.count {
            guard sorted[i].combined >= threshold else { i += 1; continue }
            var j = i
            while j + 1 < sorted.count && sorted[j + 1].combined >= threshold {
                j += 1
            }
            let slice = sorted[i...j]
            guard let peak = slice.max(by: { $0.combined < $1.combined }) else { i = j + 1; continue }
            result.append(AlertWindow(start: slice.first!.date, end: slice.last!.date, peakDate: peak.date, peakScore: peak.combined))
            i = j + 1
        }
        return result
    }

    private static func dedupedSorted(_ hourly: [ScoredHour]) -> [ScoredHour] {
        var seen = Set<Date>()
        var out: [ScoredHour] = []
        for h in hourly.sorted(by: { $0.date < $1.date }) where seen.insert(h.date).inserted {
            out.append(h)
        }
        return out
    }
}
