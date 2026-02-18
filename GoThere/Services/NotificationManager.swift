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
}
