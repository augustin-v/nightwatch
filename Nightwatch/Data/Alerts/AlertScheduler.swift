import Foundation
import UserNotifications

/// An hour-of-day window (0-23, in the device's current calendar) that may
/// wrap past midnight, e.g. 22:00 through 07:00. Deliberately not
/// `ClosedRange<Int>`: Swift's `ClosedRange` traps at construction if
/// `lowerBound > upperBound`, which is exactly the shape every wrapping
/// quiet-hours window has (`22...7` is not a constructible `ClosedRange`).
public struct QuietHours: Sendable, Equatable {
    public let startHour: Int
    public let endHour: Int

    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }

    public func contains(hour: Int) -> Bool {
        if startHour <= endHour {
            return (startHour...endHour).contains(hour)
        }
        // Wraps past midnight, e.g. 22 through 7.
        return hour >= startHour || hour <= endHour
    }
}

/// Schedules local notifications for alert windows and guarantees no
/// duplicates accumulate across repeated refreshes (spec §2: "cancelling
/// and replacing previously scheduled ones"), by always removing every
/// previously scheduled Nightwatch alert before scheduling the new set.
///
/// Notification copy comes from the String Catalog (`Localizable.xcstrings`,
/// keys `alert.notification.title` / `alert.notification.body`) per
/// STANDARDS §11 — nothing here hardcodes English.
public actor AlertScheduler {
    /// Every notification this scheduler creates is identified with this
    /// prefix, so `reschedule` can find and remove exactly its own past
    /// notifications and nothing else.
    public static let identifierPrefix = "com.augustinv.nightwatch.alert."

    private let scheduler: NotificationScheduling

    public init(scheduler: NotificationScheduling = SystemNotificationScheduler()) {
        self.scheduler = scheduler
    }

    /// Removes every previously scheduled Nightwatch alert, then schedules
    /// one notification per window in `windows`, skipping windows already
    /// in the past and windows whose peak instant falls inside
    /// `quietHours`.
    @discardableResult
    public func reschedule(
        windows: [AlertWindow],
        quietHours: QuietHours? = nil,
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) async -> [String] {
        let existing = await scheduler.pendingRequestIdentifiers(withPrefix: Self.identifierPrefix)
        await scheduler.removePendingRequests(identifiers: existing)

        var scheduledIdentifiers: [String] = []
        for window in windows where window.start > now {
            if let quietHours, Self.isQuietHour(window.peakDate, quietHours: quietHours, calendar: calendar) {
                continue
            }
            let request = Self.makeRequest(for: window, calendar: calendar)
            guard (try? await scheduler.add(request)) != nil else { continue }
            scheduledIdentifiers.append(request.identifier)
        }
        return scheduledIdentifiers
    }

    static func isQuietHour(_ date: Date, quietHours: QuietHours, calendar: Calendar) -> Bool {
        quietHours.contains(hour: calendar.component(.hour, from: date))
    }

    static func identifier(for window: AlertWindow) -> String {
        identifierPrefix + ISO8601DateFormatter().string(from: window.start)
    }

    static func makeRequest(for window: AlertWindow, calendar: Calendar) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: window.peakDate)

        content.title = String(localized: "alert.notification.title")
        content.body = String(format: String(localized: "alert.notification.body"), timeString)
        content.sound = .default

        var triggerCalendar = calendar
        triggerCalendar.timeZone = .current
        // Fire at the start of the window, not the peak — spec §2 wants the
        // user notified early enough to still go and look, not told after
        // the best moment has already passed.
        let components = triggerCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: window.start)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return UNNotificationRequest(identifier: identifier(for: window), content: content, trigger: trigger)
    }
}
