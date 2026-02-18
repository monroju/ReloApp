import Foundation

struct Resource: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let url: String
    let category: String

    init(id: String = "", label: String = "", url: String = "", category: String = "") {
        self.id = id
        self.label = label
        self.url = url
        self.category = category
    }
}
