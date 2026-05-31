import Foundation

/// Investment-migration reference — upper-tier "optionality / Plan B" buyer. Two buckets:
///   1. Residency-by-investment visas already in VisaCatalog (golden / investor tracks).
///   2. Citizenship-by-investment (CBI) programs — passport-only, not relocation
///      destinations, so they live here rather than in the 11-country catalog.
/// Informational only; investment-migration is lawyer territory — the view always
/// routes to a vetted-advisor handoff. Refresh annually (programs change fast).
enum InvestmentMigration {

    /// In-catalog residency-by-investment visas, pulled live from VisaCatalog.
    static var residencyByInvestment: [VisaInfo] {
        VisaCatalog.byCategory(.investment)
    }

    struct CBIProgram: Identifiable {
        let id: String
        let flag: String
        let country: String
        let minInvestmentUSD: Int
        let route: String          // donation vs real estate
        let timelineMonths: String
        let perks: String
        let officialUrl: String
    }

    /// Caribbean + select CBI programs. Passport-by-investment — visa-free travel +
    /// a true second nationality, popular for tax/political diversification.
    static let cbiPrograms: [CBIProgram] = [
        CBIProgram(id: "kn", flag: "🇰🇳", country: "St. Kitts & Nevis",
            minInvestmentUSD: 250_000, route: "Sustainable Island State Contribution (donation) or real estate",
            timelineMonths: "4–6 mo", perks: "Oldest CBI (since 1984); visa-free ~150 countries incl. UK/Schengen",
            officialUrl: "https://www.ciu.gov.kn/"),
        CBIProgram(id: "dm", flag: "🇩🇲", country: "Dominica",
            minInvestmentUSD: 200_000, route: "Economic Diversification Fund (donation) or real estate",
            timelineMonths: "4–6 mo", perks: "Often the lowest-cost CBI; visa-free ~140 countries",
            officialUrl: "https://cbiu.gov.dm/"),
        CBIProgram(id: "ag", flag: "🇦🇬", country: "Antigua & Barbuda",
            minInvestmentUSD: 230_000, route: "National Development Fund (donation) or real estate",
            timelineMonths: "4–6 mo", perks: "Family-friendly pricing; visa-free ~150 countries",
            officialUrl: "https://cip.gov.ag/"),
        CBIProgram(id: "gd", flag: "🇬🇩", country: "Grenada",
            minInvestmentUSD: 235_000, route: "National Transformation Fund (donation) or real estate",
            timelineMonths: "4–8 mo", perks: "Only Caribbean CBI with a US E-2 treaty (path to US business visa); visa-free China",
            officialUrl: "https://cbi.gov.gd/"),
        CBIProgram(id: "lc", flag: "🇱🇨", country: "St. Lucia",
            minInvestmentUSD: 240_000, route: "National Economic Fund (donation), real estate, or govt bonds",
            timelineMonths: "4–6 mo", perks: "Bond option refundable after hold period; visa-free ~145 countries",
            officialUrl: "https://www.cipsaintlucia.com/"),
    ]

    /// Notable programs that ended/changed — set expectations honestly for buyers who
    /// read old advice. Surfaced as a callout.
    static let endedPrograms: [String] = [
        "🇪🇸 Spain Golden Visa — ended April 2025 (no longer available; use Spain's NLV or DNV instead).",
        "🇵🇹 Portugal Golden Visa — real-estate route killed Oct 2023; €500k fund/cultural routes only.",
        "🇮🇪 Ireland IIP — closed to new applicants in 2023.",
    ]

    static let disclaimer = "Investment migration is high-stakes and lawyer-led. Programs, prices, and due-diligence rules change frequently. GoThere is informational — engage a licensed investment-migration advisor before committing funds."
}
