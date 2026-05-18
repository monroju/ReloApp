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

    var date: Date {
        Date(timeIntervalSince1970: dateMillis / 1000)
    }
}
