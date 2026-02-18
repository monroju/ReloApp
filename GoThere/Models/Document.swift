import Foundation

struct UserDocument: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var downloadUrl: String = ""
    var path: String = ""
}
