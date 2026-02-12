import Foundation

/// Calendar event stored per user in Firestore.
struct EventItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    /// UTC millis for the event day/time
    let dateMillis: Int64
    let notes: String?
    let createdAt: Int64

    init(
        id: String = "",
        title: String = "",
        dateMillis: Int64 = 0,
        notes: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.dateMillis = dateMillis
        self.notes = notes
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case dateMillis = "date_millis"
        case notes
        case createdAt = "created_at"
    }
}
