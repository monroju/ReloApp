import Foundation

/// Firestore-friendly Task model.
/// Named `TaskModel` to avoid collision with Swift's built-in `Task`.
struct TaskModel: Codable, Identifiable, Hashable {
    let id: String?
    let title: String
    let description: String?
    let category: String?
    let completed: Bool
    /// UTC millis midnight (optional)
    let dueAt: Int64?
    let createdAt: Int64?
    let cityId: String?
    let cityName: String?
    /// spain, portugal, mexico - defaults to spain for legacy
    let countryId: String?
    let links: [Link]?

    init(
        id: String? = nil,
        title: String = "",
        description: String? = nil,
        category: String? = "General",
        completed: Bool = false,
        dueAt: Int64? = nil,
        createdAt: Int64? = nil,
        cityId: String? = nil,
        cityName: String? = nil,
        countryId: String? = nil,
        links: [Link]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.completed = completed
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.cityId = cityId
        self.cityName = cityName
        self.countryId = countryId
        self.links = links
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case completed
        case dueAt = "due_at"
        case createdAt = "created_at"
        case cityId = "city_id"
        case cityName = "city_name"
        case countryId = "country_id"
        case links
    }
}
