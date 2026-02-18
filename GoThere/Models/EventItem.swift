import Foundation

/// Calendar event stored per user in Firestore.
struct EventItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var dateMillis: TimeInterval = 0
    var notes: String?
    var createdAt: Date = Date()

    var date: Date {
        Date(timeIntervalSince1970: dateMillis / 1000)
    }
}
