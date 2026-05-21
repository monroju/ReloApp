import Foundation

enum VisaCategory: String, CaseIterable, Identifiable {
    case passiveIncome = "Passive Income / Retiree"
    case digitalNomad = "Digital Nomad"
    case work = "Work / Skilled"
    case selfEmployed = "Self-Employed"
    case ancestry = "Ancestry / Descent"
    case investment = "Investment"
    case student = "Student"
    case family = "Family"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .passiveIncome: return "dollarsign.circle"
        case .digitalNomad: return "laptopcomputer"
        case .work: return "briefcase"
        case .selfEmployed: return "person.crop.rectangle.badge.plus"
        case .ancestry: return "tree"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .student: return "graduationcap"
        case .family: return "person.2"
        }
    }
}

struct VisaInfo: Identifiable, Hashable {
    let id: String              // unique slug, e.g. "es_nlv"
    let countryId: String       // "spain", "portugal", etc — matches DestinationConfig
    let countryFlag: String
    let countryName: String
    let name: String            // "Non-Lucrative Visa"
    let shortName: String       // "NLV"
    let category: VisaCategory
    let income: String          // "~€2,400/mo passive" (display string with all nuance)
    /// Structured monthly income threshold in EUR, for Cost Calc comparison + paywall teasers.
    /// Nil when the visa uses non-income criteria (points-based, employer-sponsored, no test).
    /// Populated for passive-income / DNV / retiree tracks. Refresh annually alongside
    /// VisaCatalog's "thresholds reflect 2025-2026 rules" note.
    var monthlyIncomeEUR: Int? = nil
    let processingTime: String  // "2-3 months"
    let duration: String        // "1y → 2/2/5 renewable"
    let workAllowed: String     // "No" / "Foreign employer only" / "Yes"
    let pathToPR: String        // "5 years"
    let pathToCitizenship: String  // "10 years (2y Latin Am/Sephardic)"
    let costEstimate: String    // "€600 + lawyer"
    let pros: [String]
    let cons: [String]
    let officialUrl: String
    let wizardTrackId: String?  // matches wizard_config.json — nil if no wizard yet
}
