import Foundation

/// One-time "cost to actually get there" estimator. Built for the lower/middle-class
/// user whose biggest blocker is the belief that moving abroad is only for the rich.
/// Every figure is a deliberately conservative *estimate in USD* — refresh annually
/// alongside VisaCatalog. Ranges are shown in the UI so users treat them as ballpark,
/// not quotes.
///
/// Components are split so the breakdown reads like a real budget:
///   flights + government fees + legal/gestor + deposit & first months' rent + setup misc.
struct MoveCostProfile {
    let countryId: String          // matches DestinationConfig
    let flag: String
    let name: String

    /// One-way economy airfare per person from a US hub (rough national average).
    let flightPerPersonUSD: Int
    /// Consular / immigration government fees for the cheapest common track, per applicant.
    let govtFeesPerPersonUSD: Int
    /// Typical lawyer / gestor / relocation-agent fee for the household (one-off).
    let legalUSD: Int
    /// Monthly rent for a modest 1-2 bed in a mid-cost area (single/couple baseline).
    let monthlyRentUSD: Int
    /// Monthly living cost ex-rent for one adult (food, transport, utilities, phone).
    let monthlyLivingPerAdultUSD: Int
    /// Up-front move setup: shipping a few boxes, initial furniture, deposits on
    /// utilities, document apostille/translation. Household one-off.
    let setupUSD: Int

    /// Landlords typically want first month + 1-2 months deposit. We budget 1 month
    /// rent deposit + first month rent = 2× monthly rent up front.
    var upfrontRentUSD: Int { monthlyRentUSD * 2 }
}

enum MoveCostData {
    /// 2025-2026 conservative estimates. Sources: aggregated consulate fee schedules,
    /// Numbeo cost-of-living medians, expat-forum airfare reports. Refresh each Q1.
    static let profiles: [MoveCostProfile] = [
        MoveCostProfile(countryId: "spain", flag: "🇪🇸", name: "Spain",
            flightPerPersonUSD: 550, govtFeesPerPersonUSD: 150, legalUSD: 1600,
            monthlyRentUSD: 1100, monthlyLivingPerAdultUSD: 800, setupUSD: 1500),
        MoveCostProfile(countryId: "portugal", flag: "🇵🇹", name: "Portugal",
            flightPerPersonUSD: 600, govtFeesPerPersonUSD: 120, legalUSD: 1600,
            monthlyRentUSD: 1000, monthlyLivingPerAdultUSD: 750, setupUSD: 1400),
        MoveCostProfile(countryId: "mexico", flag: "🇲🇽", name: "Mexico",
            flightPerPersonUSD: 350, govtFeesPerPersonUSD: 250, legalUSD: 600,
            monthlyRentUSD: 700, monthlyLivingPerAdultUSD: 600, setupUSD: 900),
        MoveCostProfile(countryId: "canada", flag: "🇨🇦", name: "Canada",
            flightPerPersonUSD: 400, govtFeesPerPersonUSD: 1100, legalUSD: 1500,
            monthlyRentUSD: 1600, monthlyLivingPerAdultUSD: 1000, setupUSD: 1800),
        MoveCostProfile(countryId: "ireland", flag: "🇮🇪", name: "Ireland",
            flightPerPersonUSD: 600, govtFeesPerPersonUSD: 300, legalUSD: 1500,
            monthlyRentUSD: 1900, monthlyLivingPerAdultUSD: 1000, setupUSD: 1800),
        MoveCostProfile(countryId: "italy", flag: "🇮🇹", name: "Italy",
            flightPerPersonUSD: 650, govtFeesPerPersonUSD: 130, legalUSD: 1400,
            monthlyRentUSD: 950, monthlyLivingPerAdultUSD: 800, setupUSD: 1500),
        MoveCostProfile(countryId: "germany", flag: "🇩🇪", name: "Germany",
            flightPerPersonUSD: 600, govtFeesPerPersonUSD: 110, legalUSD: 1200,
            monthlyRentUSD: 1300, monthlyLivingPerAdultUSD: 950, setupUSD: 1600),
        MoveCostProfile(countryId: "poland", flag: "🇵🇱", name: "Poland",
            flightPerPersonUSD: 650, govtFeesPerPersonUSD: 90, legalUSD: 1000,
            monthlyRentUSD: 750, monthlyLivingPerAdultUSD: 650, setupUSD: 1200),
        MoveCostProfile(countryId: "argentina", flag: "🇦🇷", name: "Argentina",
            flightPerPersonUSD: 750, govtFeesPerPersonUSD: 200, legalUSD: 700,
            monthlyRentUSD: 550, monthlyLivingPerAdultUSD: 550, setupUSD: 900),
        MoveCostProfile(countryId: "hungary", flag: "🇭🇺", name: "Hungary",
            flightPerPersonUSD: 650, govtFeesPerPersonUSD: 110, legalUSD: 900,
            monthlyRentUSD: 700, monthlyLivingPerAdultUSD: 650, setupUSD: 1100),
        // govtFees folds in the Immigration Health Surcharge: ~$800 visa fee +
        // ~$1,000/person/yr IHS prepaid for the full 5-yr Ancestry term (~$5,000).
        // The IHS is the real upfront cost (see HealthcareCostData note); pretending
        // UK entry is an $800 line item understated the move by thousands.
        MoveCostProfile(countryId: "uk_ancestry", flag: "🇬🇧", name: "UK (Ancestry)",
            flightPerPersonUSD: 550, govtFeesPerPersonUSD: 5800, legalUSD: 1200,
            monthlyRentUSD: 2000, monthlyLivingPerAdultUSD: 1100, setupUSD: 1800),
    ]

    static func profile(for countryId: String) -> MoveCostProfile? {
        profiles.first { $0.countryId == countryId }
    }
}

/// Lifestyle dial — scales the recurring living-cost portion of the estimate.
/// "Lean" is shoestring (shared/rural, cook at home), "Comfortable" is a relaxed
/// city budget. Multiplies rent + living; one-off costs (flights, fees) are unaffected.
enum MoveLifestyle: String, CaseIterable, Identifiable {
    case lean = "Lean"
    case moderate = "Moderate"
    case comfortable = "Comfortable"
    var id: String { rawValue }
    var multiplier: Double {
        switch self {
        case .lean: return 0.75
        case .moderate: return 1.0
        case .comfortable: return 1.5
        }
    }
}

/// Itemised, computed estimate for a given household + lifestyle.
struct MoveCostEstimate {
    let flights: Int
    let govtFees: Int
    let legal: Int
    let upfrontRent: Int        // deposit + first month
    let firstMonthsLiving: Int  // remaining living runway
    let setup: Int

    var total: Int { flights + govtFees + legal + upfrontRent + firstMonthsLiving + setup }

    /// We show a ±20% band so the headline number reads as a ballpark, not a quote.
    var lowBand: Int { Int(Double(total) * 0.8) }
    var highBand: Int { Int(Double(total) * 1.2) }

    /// Estimate the realistic landing budget: enough cash to arrive and survive
    /// `monthsRunway` months before income stabilises.
    static func compute(profile: MoveCostProfile,
                        adults: Int,
                        children: Int,
                        lifestyle: MoveLifestyle,
                        monthsRunway: Int) -> MoveCostEstimate {
        let people = max(1, adults + children)
        let m = lifestyle.multiplier

        let flights = profile.flightPerPersonUSD * people
        // Children usually pay reduced or no consular fee on family tracks — count at 50%.
        let govtFees = profile.govtFeesPerPersonUSD * adults
            + Int(Double(profile.govtFeesPerPersonUSD) * 0.5 * Double(children))
        let legal = profile.legalUSD
        let upfrontRent = Int(Double(profile.upfrontRentUSD) * m)
        // Living runway for the months *after* the first (first month rent is in upfront).
        let extraMonths = max(0, monthsRunway - 1)
        let monthlyLiving = Double(profile.monthlyLivingPerAdultUSD) * Double(max(1, adults))
            + Double(profile.monthlyLivingPerAdultUSD) * 0.6 * Double(children)
            + Double(profile.monthlyRentUSD)
        let firstMonthsLiving = Int(monthlyLiving * m * Double(extraMonths))
        let setup = Int(Double(profile.setupUSD) * m)

        return MoveCostEstimate(
            flights: flights, govtFees: govtFees, legal: legal,
            upfrontRent: upfrontRent, firstMonthsLiving: firstMonthsLiving, setup: setup
        )
    }
}
