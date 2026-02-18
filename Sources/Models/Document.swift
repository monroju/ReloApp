import Foundation

struct Document: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let downloadUrl: String
    /// Firebase Storage path used for deletes
    let path: String

    init(id: String = "", name: String = "", downloadUrl: String = "", path: String = "") {
        self.id = id
        self.name = name
        self.downloadUrl = downloadUrl
        self.path = path
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case downloadUrl = "download_url"
        case path
    }
}
