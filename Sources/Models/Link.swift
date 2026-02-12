import Foundation

/// Simple label+url pair for helpful resources.
struct Link: Codable, Hashable {
    let label: String?
    let url: String?

    init(label: String? = nil, url: String? = nil) {
        self.label = label
        self.url = url
    }
}
