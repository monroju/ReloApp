import Foundation

struct FormDoc: Codable, Hashable {
    let name: String
    let url: String
    let path: String
    let sizeBytes: Int64
    let updatedAt: Int64

    init(
        name: String = "",
        url: String = "",
        path: String = "",
        sizeBytes: Int64 = 0,
        updatedAt: Int64 = 0
    ) {
        self.name = name
        self.url = url
        self.path = path
        self.sizeBytes = sizeBytes
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case path
        case sizeBytes = "size_bytes"
        case updatedAt = "updated_at"
    }
}
