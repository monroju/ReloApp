import Foundation

/// Firestore-friendly Task model.
struct TaskItem: Codable, Identifiable, Hashable {
    var id: String?
    var title: String = ""
    var description: String?
    var category: String? = "General"
    var completed: Bool = false
    var dueAt: Date?
    var createdAt: Date? = Date()
    var cityId: String?
    var cityName: String?
    var countryId: String?
    var links: [AppLink]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, completed
        case dueAt, createdAt, cityId, cityName, countryId, links
    }
}

/// Destination-scoped task with phase support.
struct DestinationTask: Codable, Identifiable, Hashable {
    var id: String?
    var destinationId: String = ""
    var visaTrackId: String = ""
    var phaseId: String = ""
    var title: String = ""
    var description: String?
    var category: String? = "General"
    var completed: Bool = false
    var dueAt: Date?
    var createdAt: Date? = Date()
    var updatedAt: Date?
    var seeded: Bool = false
    var seedKey: String?
    var links: [AppLink]?
    var order: Int = 0

    func toTask() -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            description: description,
            category: category,
            completed: completed,
            dueAt: dueAt,
            createdAt: createdAt,
            links: links
        )
    }


    static func generateSeedKey(
        destinationId: String,
        visaTrackId: String,
        phaseId: String,
        title: String
    ) -> String {
        let slug = title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .prefix(50)
        return "\(destinationId)::\(visaTrackId)::\(phaseId)::\(slug)"
    }
}
