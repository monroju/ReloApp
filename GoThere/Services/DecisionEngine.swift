import Foundation

/// Ranks destinations based on user profile preferences.
enum DecisionEngine {

    static func rank(profile: UserProfile, destinations: [Destination]) -> [RankedDestination] {
        destinations.map { dest in
            var score: Double = 0
            var reasons: [String] = []

            // Budget match
            let budgetLevel: Int
            switch profile.budget {
            case Budget.low.rawValue: budgetLevel = 1
            case Budget.high.rawValue: budgetLevel = 3
            default: budgetLevel = 2
            }

            if dest.costLevel <= budgetLevel {
                score += 20
                if dest.costLevel < budgetLevel { reasons.append("Affordable") }
            } else {
                score -= 10
            }

            // Household
            switch profile.household {
            case Household.familyKids.rawValue:
                if dest.tags.contains("families") { score += 15; reasons.append("Family-friendly") }
                if dest.tags.contains("intl_schools") { score += 10; reasons.append("International schools") }
            case Household.singles.rawValue:
                if dest.tags.contains("singles") { score += 15; reasons.append("Great for singles") }
                if dest.tags.contains("nightlife") { score += 5 }
            case Household.singleParent.rawValue:
                if dest.tags.contains("families") { score += 12; reasons.append("Family-friendly") }
                if dest.tags.contains("safe") { score += 8; reasons.append("Safe for kids") }
                if dest.tags.contains("intl_schools") { score += 8; reasons.append("International schools") }
                if dest.tags.contains("public_transit") { score += 5; reasons.append("Strong public transit") }
            case Household.retiree.rawValue:
                if dest.tags.contains("retiree_friendly") { score += 15; reasons.append("Retiree-friendly") }
                if dest.tags.contains("safe") { score += 10 }
            case Household.couple.rawValue:
                if dest.tags.contains("culture") { score += 10 }
                if dest.tags.contains("coastal") { score += 5 }
            default:
                break
            }

            // Personal Considerations (country-level signal + tag bonus)
            score += personalConsiderationsScore(
                considerations: profile.considerations,
                countryId: profile.countryId,
                dest: dest,
                reasons: &reasons
            )

            // Climate
            switch profile.climate {
            case ClimatePref.warmCoastal.rawValue:
                if dest.climate == "warm_coastal" { score += 15; reasons.append("Warm & coastal") }
            case ClimatePref.temperate.rawValue:
                if dest.climate == "temperate" { score += 15; reasons.append("Temperate climate") }
            case ClimatePref.mountain.rawValue:
                if dest.tags.contains("mountain_access") { score += 15; reasons.append("Mountain access") }
            default:
                break
            }

            // Coastal preference
            if profile.preferCoastal && dest.tags.contains("coastal") {
                score += 10
                if !reasons.contains("Warm & coastal") { reasons.append("Coastal location") }
            }

            // City size
            if profile.preferBigCity && dest.type == "Big City" {
                score += 10; reasons.append("Major city")
            }

            // Expat density
            switch profile.density {
            case DensityPref.high.rawValue:
                if dest.expatDensity >= 4 { score += 10; reasons.append("Strong expat community") }
            case DensityPref.low.rawValue:
                if dest.expatDensity <= 2 { score += 10; reasons.append("Authentic local experience") }
            default:
                break
            }

            // Business focus
            switch profile.businessFocus {
            case BusinessFocus.tech.rawValue:
                if dest.tags.contains("tech") || dest.tags.contains("startup") { score += 10; reasons.append("Tech hub") }
            case BusinessFocus.tourism.rawValue:
                if dest.tags.contains("tourism") { score += 10; reasons.append("Tourism-oriented") }
            case BusinessFocus.remoteWork.rawValue:
                if dest.tags.contains("remote_work") { score += 10; reasons.append("Remote work friendly") }
            default:
                break
            }

            // Nightlife
            if profile.nightlife == NightlifePref.important.rawValue && dest.tags.contains("nightlife") {
                score += 5; reasons.append("Active nightlife")
            }

            // Safety
            if profile.safetyCritical && dest.safety >= 4 {
                score += 10
                if dest.safety == 5 { reasons.append("Very safe") }
            }

            // Airport access bonus
            if dest.tags.contains("airport") { score += 3 }

            return RankedDestination(destination: dest, score: max(0, score), reasons: reasons)
        }
        .sorted { $0.score > $1.score }
    }

    static func destinationsForCountry(_ countryId: String) -> [Destination] {
        switch countryId {
        case "portugal": return PortugalDestinations.all
        case "mexico": return MexicoDestinations.all
        default: return SpainDestinations.all
        }
    }

    // MARK: - Personal Considerations Scoring

    /// Country-level signal (legal + healthcare + cultural) blended with optional destination tags.
    /// Source rationale (2026): ILGA-Europe Rainbow Index, EU Disability Card adoption,
    /// totalization agreements (Veterans), and OECD maternity/healthcare quality.
    private static func personalConsiderationsScore(
        considerations: Set<String>,
        countryId: String,
        dest: Destination,
        reasons: inout [String]
    ) -> Double {
        guard !considerations.isEmpty else { return 0 }
        var score: Double = 0

        for raw in considerations {
            guard let c = PersonalConsideration(rawValue: raw) else { continue }
            switch c {
            case .lgbtq:
                // Strong: Spain, Portugal, Canada, Ireland, Germany, UK. Mixed: Italy, Argentina, Mexico. Weaker: Poland, Hungary.
                switch countryId {
                case "spain", "portugal", "canada", "ireland", "germany", "uk_ancestry":
                    score += 12; reasons.append("Strong LGBTQ+ protections")
                case "italy", "argentina", "mexico":
                    score += 6; reasons.append("LGBTQ+ legal but uneven")
                case "poland", "hungary":
                    score -= 4; reasons.append("LGBTQ+ rights limited")
                default: break
                }
                if dest.tags.contains("lgbtq_friendly") { score += 5 }
            case .disabled:
                // EU Disability Card members get scored higher; large cities with public transit score higher.
                switch countryId {
                case "germany", "spain", "portugal", "ireland", "italy", "poland", "hungary":
                    score += 8; reasons.append("EU Disability Card recognised")
                case "canada", "uk_ancestry":
                    score += 7; reasons.append("Strong accessibility law")
                case "mexico", "argentina":
                    score += 2
                default: break
                }
                if dest.type == "Big City" { score += 4; reasons.append("Better accessibility in city") }
                if dest.tags.contains("public_transit") { score += 4 }
            case .veteran:
                // US-veteran lens: SSA totalization + VA Foreign Medical Program coverage where applicable.
                switch countryId {
                case "spain", "portugal", "italy", "germany", "ireland", "poland", "hungary", "uk_ancestry", "canada":
                    score += 6; reasons.append("US totalization agreement")
                case "mexico":
                    score += 4; reasons.append("VA FMP coverage available")
                case "argentina":
                    score += 3
                default: break
                }
            case .pregnant:
                // OECD maternity care + paid leave proxy.
                switch countryId {
                case "germany", "ireland", "canada", "italy", "spain", "portugal", "uk_ancestry":
                    score += 10; reasons.append("Strong maternity care")
                case "poland", "hungary", "argentina":
                    score += 5
                case "mexico":
                    score += 4
                default: break
                }
                if dest.type == "Big City" { score += 3; reasons.append("Top-tier hospitals") }
            }
        }

        return score
    }
}
