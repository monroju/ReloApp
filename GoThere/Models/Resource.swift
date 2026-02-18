import Foundation

struct Resource: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var label: String = ""
    var url: String = ""
    var category: String = ""
}

struct ResourceItem: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var path: String
    var sizeBytes: Int64?
    var downloadUrl: String?
    var category: String = ""
}
