import Foundation

struct FormDoc: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String = ""
    var url: String = ""
    var path: String = ""
    var sizeBytes: Int64 = 0
    var updatedAt: TimeInterval = 0
}
