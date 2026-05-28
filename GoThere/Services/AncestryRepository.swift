import Foundation

final class AncestryRepository {
    static let shared = AncestryRepository()
    let catalog: AncestryCatalog

    private init() {
        guard let url = Bundle.main.url(forResource: "ancestry_paths", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AncestryCatalog.self, from: data) else {
            self.catalog = AncestryCatalog(version: 0, lastUpdated: "", disclaimer: "", paths: [])
            return
        }
        self.catalog = decoded
    }

    var paths: [AncestryPath] { catalog.paths }
    func path(byCountryId id: String) -> AncestryPath? { paths.first { $0.countryId == id } }
}
