import Foundation

struct AppLink: Codable, Identifiable, Hashable {
    var id: String { "\(label ?? "")_\(url ?? "")" }
    let label: String?
    let url: String?
}
