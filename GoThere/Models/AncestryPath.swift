import Foundation

struct AncestryPath: Identifiable, Codable {
    let id: String
    let countryId: String
    let countryName: String
    let shortName: String
    let fullName: String
    let summary: String
    let incomeRequired: Bool
    let estCostUSD: CostRange
    let estTimelineMonths: TimelineRange
    let outcome: String
    let eligibilityRules: [EligibilityRule]
    let documents: [String]
    let lowIncomeNotes: String
    let officialUrl: String

    struct CostRange: Codable {
        let low: Int
        let high: Int
        let note: String
    }

    struct TimelineRange: Codable {
        let low: Int
        let high: Int
    }

    struct EligibilityRule: Identifiable, Codable {
        let id: String
        let label: String
        let explanation: String?
        let required: Bool
        let openWorkaround: String?
    }
}

struct AncestryCatalog: Codable {
    let version: Int
    let lastUpdated: String
    let disclaimer: String
    let paths: [AncestryPath]
}
