import Foundation

final class PoiRepository {
    static let shared = PoiRepository()
    private var cache: [String: CityPoiData] = [:]
    private init() {}

    func loadCity(_ cityId: String) -> CityPoiData? {
        if let cached = cache[cityId] { return cached }

        guard let url = Bundle.main.url(forResource: "poi_\(cityId)", withExtension: "json", subdirectory: "poi"),
              let data = try? Data(contentsOf: url),
              let city = try? JSONDecoder().decode(CityPoiData.self, from: data)
        else { return nil }

        cache[cityId] = city
        return city
    }
}
