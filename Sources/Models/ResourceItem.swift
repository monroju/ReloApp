import Foundation

struct ResourceItem: Codable, Hashable {
    let name: String
    let path: String
    let sizeBytes: Int64?
    let downloadUrl: String?
    let category: String

    init(
        name: String,
        path: String,
        sizeBytes: Int64? = nil,
        downloadUrl: String? = nil,
        category: String = ""
    ) {
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.downloadUrl = downloadUrl
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case sizeBytes = "size_bytes"
        case downloadUrl = "download_url"
        case category
    }
}
