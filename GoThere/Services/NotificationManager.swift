import Foundation
import UserNotifications

/// Manages local notifications for calendar reminders.
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleNotification(for event: EventItem) {
        let content = UNMutableNotificationContent()
        content.title = "GoThere Reminder"
        content.body = event.title
        content.sound = .default

        // Schedule for 9:00 AM on event day
        let eventDate = Date(timeIntervalSince1970: event.dateMillis / 1000)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: eventDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_\(event.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["event_\(eventId)"]
        )
    }

    // MARK: - Document expiration (Differentiation Wave)

    private static let docPrefix = "docexp_"

    /// Request permission only if the user hasn't been asked yet — used the first
    /// time a document is uploaded so the prompt carries clear value context.
    func requestPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }

    /// Schedule (or reschedule) all expiry reminders for a document. Cancels any
    /// existing ones for this document first, then schedules a notification at
    /// each reminder offset before expiration plus one on the expiration day.
    /// No-op for non-expiring documents.
    func scheduleDocumentExpiry(_ doc: UserDocument) {
        cancelDocumentExpiry(documentId: doc.id)
        guard let expiration = doc.expirationDate else { return }

        let center = UNUserNotificationCenter.current()
        let cal = Calendar.current
        let now = Date()

        // Reminder offsets, e.g. 30/14/3 days before expiry.
        for offset in doc.effectiveReminderDays {
            guard let fireDate = cal.date(byAdding: .day, value: -offset, to: expiration),
                  fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "GoThere"
            content.body = Self.reminderBody(name: doc.name, daysBefore: offset)
            content.sound = .default
            var comps = cal.dateComponents([.year, .month, .day], from: fireDate)
            comps.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(
                identifier: "\(Self.docPrefix)\(doc.id)_\(offset)",
                content: content, trigger: trigger))
        }

        // Day-of-expiry notification.
        if expiration > now {
            let content = UNMutableNotificationContent()
            content.title = "GoThere"
            content.body = "\u{274C} \(doc.name) has expired. Update before submitting."
            content.sound = .default
            var comps = cal.dateComponents([.year, .month, .day], from: expiration)
            comps.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(
                identifier: "\(Self.docPrefix)\(doc.id)_expired",
                content: content, trigger: trigger))
        }
    }

    /// Cancel every pending expiry reminder for a document (on delete or before a
    /// reschedule). Matches by identifier prefix since the offset set may vary.
    func cancelDocumentExpiry(documentId: String) {
        let center = UNUserNotificationCenter.current()
        let prefix = "\(Self.docPrefix)\(documentId)_"
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            if !ids.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    /// Re-evaluate all documents (call on foreground): clears every doc reminder,
    /// then reschedules from current data so notifications that fired while the
    /// app was closed don't leave stale duplicates.
    func rescheduleAllDocuments(_ docs: [UserDocument]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let stale = requests.map(\.identifier).filter { $0.hasPrefix(Self.docPrefix) }
            if !stale.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: stale)
            }
            for doc in docs { self.scheduleDocumentExpiry(doc) }
        }
    }

    private static func reminderBody(name: String, daysBefore: Int) -> String {
        switch daysBefore {
        case 30: return "\u{1F4CB} \(name) expires in 30 days. Tap to review."
        case 14: return "\u{26A0}\u{FE0F} \(name) expires in 14 days. Renew before your application."
        case 3:  return "\u{1F6A8} \(name) expires in 3 days."
        default: return "\u{1F4CB} \(name) expires in \(daysBefore) day\(daysBefore == 1 ? "" : "s")."
        }
    }
}
