import Foundation
import Testing
import UserNotifications
@testable import Nightwatch

/// `UNNotificationRequest` is not `Sendable`, so an `actor` conformance
/// (which requires crossing an isolation boundary with that parameter)
/// doesn't type-check. This test double instead uses a class + lock, the
/// same shape `SystemNotificationScheduler` uses in production for the same
/// reason.
final class FakeNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _addedRequests: [UNNotificationRequest] = []
    private var _removedIdentifiers: [[String]] = []
    private var pending: [String]
    private var _failNextAdd = false

    init(existingPending: [String] = []) {
        self.pending = existingPending
    }

    var addedRequests: [UNNotificationRequest] {
        lock.withLock { _addedRequests }
    }

    var removedIdentifiers: [[String]] {
        lock.withLock { _removedIdentifiers }
    }

    func setFailNextAdd(_ value: Bool) {
        lock.withLock { _failNextAdd = value }
    }

    func pendingRequestIdentifiers(withPrefix prefix: String) async -> [String] {
        lock.withLock { pending.filter { $0.hasPrefix(prefix) } }
    }

    func removePendingRequests(identifiers: [String]) async {
        lock.withLock {
            _removedIdentifiers.append(identifiers)
            pending.removeAll { identifiers.contains($0) }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        let shouldFail = lock.withLock { () -> Bool in
            let value = _failNextAdd
            if value { _failNextAdd = false }
            return value
        }
        if shouldFail { throw NSError(domain: "test", code: 1) }
        lock.withLock {
            _addedRequests.append(request)
            pending.append(request.identifier)
        }
    }
}

struct AlertSchedulerTests {
    private func window(startHour: Int, endHour: Int, peakHour: Int, base: Date) -> AlertWindow {
        AlertWindow(
            start: base.addingTimeInterval(Double(startHour) * 3600),
            end: base.addingTimeInterval(Double(endHour) * 3600),
            peakDate: base.addingTimeInterval(Double(peakHour) * 3600),
            peakScore: 70
        )
    }

    @Test func schedulesOneRequestPerWindow() async {
        let fake = FakeNotificationScheduler()
        let scheduler = AlertScheduler(scheduler: fake)
        let now = Date()
        let windows = [
            window(startHour: 1, endHour: 2, peakHour: 1, base: now),
            window(startHour: 5, endHour: 6, peakHour: 5, base: now)
        ]

        let scheduled = await scheduler.reschedule(windows: windows, now: now)
        #expect(scheduled.count == 2)
        let added = fake.addedRequests
        #expect(added.count == 2)
        #expect(added.allSatisfy { $0.identifier.hasPrefix(AlertScheduler.identifierPrefix) })
    }

    @Test func removesAllPreviousAlertsBeforeSchedulingNewOnes() async {
        let existing = [
            AlertScheduler.identifierPrefix + "old-1",
            AlertScheduler.identifierPrefix + "old-2",
            "com.other.app.something" // not ours: must not be touched
        ]
        let fake = FakeNotificationScheduler(existingPending: existing)
        let scheduler = AlertScheduler(scheduler: fake)
        let now = Date()

        _ = await scheduler.reschedule(windows: [window(startHour: 1, endHour: 2, peakHour: 1, base: now)], now: now)

        let removed = fake.removedIdentifiers
        #expect(removed.count == 1)
        #expect(Set(removed[0]) == Set([AlertScheduler.identifierPrefix + "old-1", AlertScheduler.identifierPrefix + "old-2"]))
    }

    @Test func reschedulingTwiceNeverAccumulatesDuplicates() async {
        let fake = FakeNotificationScheduler()
        let scheduler = AlertScheduler(scheduler: fake)
        let now = Date()
        let windows = [window(startHour: 1, endHour: 2, peakHour: 1, base: now)]

        _ = await scheduler.reschedule(windows: windows, now: now)
        _ = await scheduler.reschedule(windows: windows, now: now)

        let pendingAfter = await fake.pendingRequestIdentifiers(withPrefix: AlertScheduler.identifierPrefix)
        #expect(pendingAfter.count == 1)
    }

    @Test func skipsWindowsAlreadyInThePast() async {
        let fake = FakeNotificationScheduler()
        let scheduler = AlertScheduler(scheduler: fake)
        let now = Date()
        let pastWindow = window(startHour: -5, endHour: -4, peakHour: -5, base: now)
        let futureWindow = window(startHour: 2, endHour: 3, peakHour: 2, base: now)

        let scheduled = await scheduler.reschedule(windows: [pastWindow, futureWindow], now: now)
        #expect(scheduled.count == 1)
    }

    @Test func skipsWindowsInsideQuietHours() async {
        let fake = FakeNotificationScheduler()
        let scheduler = AlertScheduler(scheduler: fake)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        // 2026-08-09 00:00 UTC
        let base = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 0))!
        let quietWindow = AlertWindow(
            start: base.addingTimeInterval(1 * 3600),
            end: base.addingTimeInterval(2 * 3600),
            peakDate: base.addingTimeInterval(1 * 3600), // 01:00 -> inside 22...7 quiet hours
            peakScore: 70
        )
        let loudWindow = AlertWindow(
            start: base.addingTimeInterval(10 * 3600),
            end: base.addingTimeInterval(11 * 3600),
            peakDate: base.addingTimeInterval(10 * 3600), // 10:00 -> outside quiet hours
            peakScore: 70
        )

        let scheduled = await scheduler.reschedule(windows: [quietWindow, loudWindow], quietHours: QuietHours(startHour: 22, endHour: 7), now: base.addingTimeInterval(-3600), calendar: calendar)
        #expect(scheduled.count == 1)
    }

    @Test func quietHourWrapMatchesBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date22 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 22))!
        let date7 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 7))!
        let date12 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!

        #expect(AlertScheduler.isQuietHour(date22, quietHours: QuietHours(startHour: 22, endHour: 7), calendar: calendar))
        #expect(AlertScheduler.isQuietHour(date7, quietHours: QuietHours(startHour: 22, endHour: 7), calendar: calendar))
        #expect(!AlertScheduler.isQuietHour(date12, quietHours: QuietHours(startHour: 22, endHour: 7), calendar: calendar))
    }

    @Test func aFailedAddDoesNotStopOtherWindowsFromScheduling() async {
        let fake = FakeNotificationScheduler()
        fake.setFailNextAdd(true)
        let scheduler = AlertScheduler(scheduler: fake)
        let now = Date()
        let windows = [
            window(startHour: 1, endHour: 2, peakHour: 1, base: now),
            window(startHour: 5, endHour: 6, peakHour: 5, base: now)
        ]

        let scheduled = await scheduler.reschedule(windows: windows, now: now)
        #expect(scheduled.count == 1)
    }
}
