import Foundation

/// Generic schema for real-world visa journeys derived from anonymized client
/// correspondence. Premium-only content, gated by `PurchaseManager.hasAllAccess`.
/// All personal/identifying detail is stripped at authoring time — this struct
/// holds only structural/process content.
struct RealJourney: Identifiable, Hashable {
    let id: String              // e.g. "spain_dnv"
    let visaId: String          // optional link to VisaCatalog entry
    let countryId: String       // gating + display
    let title: String
    let subtitle: String        // e.g. "Family of four · 2023 case"
    let totalDuration: String   // e.g. "~7 months end-to-end"
    let feeSummary: String      // round figures only, no exact amounts
    let eligibilitySummary: [String]
    let phases: [JourneyPhase]
    let crossPhaseGotchas: [JourneyGotcha]
    let disclaimer: String
}

struct JourneyPhase: Identifiable, Hashable {
    let id: String
    let order: Int
    let title: String
    let timeframe: String        // "Weeks 1–2"
    let summary: String
    let documents: [String]
    let lawyerPatterns: [LawyerPattern]
    let gotchas: [String]
}

struct LawyerPattern: Identifiable, Hashable {
    let id: String
    let situation: String        // "Submission confirmation"
    let phrasing: String         // paraphrased — never verbatim, < 14 words
}

struct JourneyGotcha: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}
