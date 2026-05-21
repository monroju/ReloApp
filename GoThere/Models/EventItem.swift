import Foundation

/// Calendar event stored per user in Firestore.
struct EventItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var dateMillis: TimeInterval = 0
    var notes: String?
    var createdAt: Date = Date()
    /// Origin of the event: "manual" (user added in Calendar) or "wizard" (auto-created from Wizard task due date).
    /// Optional for backward compatibility with existing Firestore docs.
    var source: String?

    // MARK: Foundation Wave 1 fields (all optional for backward compat).

    /// Milestone classification — drives the calendar color and icon. Decoded
    /// as a raw string; the consumer maps to `MilestoneCategory`.
    var category: String? = nil
    /// Days relative to the anchor date when this event was scheduled. Stored
    /// for replay-and-reschedule scenarios (e.g. anchor date moves).
    var daysOffsetFromAnchor: Int? = nil
    /// True if a local push notification was scheduled for this event.
    /// Lets the Calendar UI surface a bell icon without checking
    /// `UNUserNotificationCenter` synchronously.
    var notificationEnabled: Bool? = nil
    /// Track id this event was generated from. Lets the Calendar group / filter
    /// by track and lets the wizard re-run replace its own events idempotently.
    var visaTrackId: String? = nil

    var date: Date {
        Date(timeIntervalSince1970: dateMillis / 1000)
    }

    var resolvedCategory: MilestoneCategory {
        MilestoneCategory(rawValue: category ?? "") ?? .milestone
    }
}

/// Classification for calendar events emitted by the visa wizard. Drives
/// color, icon, and copy in CalendarScreenView. Unknown / legacy values
/// fall back to `.milestone`.
enum MilestoneCategory: String, Codable, CaseIterable {
    /// Hard deadline / "must be done by" — e.g. TIE 30 days post-arrival.
    case deadline
    /// Document expires on this date — e.g. FBI background check 90 days.
    case expiration
    /// Scheduled meeting — e.g. consulate appointment.
    case appointment
    /// Generic milestone — e.g. apostille submission target.
    case milestone
}
