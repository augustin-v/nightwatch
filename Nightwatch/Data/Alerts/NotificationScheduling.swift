import Foundation
import UserNotifications

/// The seam `AlertScheduler` goes through instead of talking to
/// `UNUserNotificationCenter` directly, so tests can verify scheduling
/// decisions (which windows produced which requests, that stale ones were
/// removed first) without touching the real notification system.
public protocol NotificationScheduling: Sendable {
    func pendingRequestIdentifiers(withPrefix prefix: String) async -> [String]
    func removePendingRequests(identifiers: [String]) async
    func add(_ request: UNNotificationRequest) async throws
}

/// The real `UNUserNotificationCenter`-backed conformance used in the app.
/// `UNUserNotificationCenter` is Apple's own thread-safe singleton, not
/// (yet) `Sendable`-annotated by the SDK, so this wrapper is `@unchecked
/// Sendable` — it holds no mutable state of its own and every call it makes
/// is documented by Apple as safe from any thread/queue.
public struct SystemNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func pendingRequestIdentifiers(withPrefix prefix: String) async -> [String] {
        await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
    }

    public func removePendingRequests(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}
