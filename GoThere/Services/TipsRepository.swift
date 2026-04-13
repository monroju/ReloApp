import Foundation

struct DailyTip: Codable, Identifiable {
    let id: Int
    let country: String
    let tip: String
    let category: String
}

final class TipsRepository {
    static let shared = TipsRepository()
    private var allTips: [DailyTip]?
    private init() {}

    private func loadTips() -> [DailyTip] {
        if let cached = allTips { return cached }
        guard let url = Bundle.main.url(forResource: "daily_tips", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tips = try? JSONDecoder().decode([DailyTip].self, from: data)
        else { return [] }
        allTips = tips
        return tips
    }

    func todaysTip(for countryId: String) -> DailyTip? {
        let tips = loadTips().filter { $0.country == countryId || $0.country == "all" }
        guard !tips.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return tips[dayOfYear % tips.count]
    }
}
