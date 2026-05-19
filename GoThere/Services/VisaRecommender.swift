import Foundation

/// Visa + its score and the reasons that produced the score — mirrors the
/// RankedDestination pattern used by DecisionEngine, so the result view can
/// render visa rows with the same reason-chip UX as the city ranking.
struct RankedVisa: Identifiable, Hashable {
    var id: String { visa.id }
    let visa: VisaInfo
    let score: Double
    let reasons: [String]
}

/// Visa-side companion to DecisionEngine. Decision Tree currently dead-ends at
/// city ranking + 5 city-research tasks (TaskRepository.starterTasks). This
/// service adds a parallel visa-recommendation surface: given the same
/// UserProfile, surface up to 5 visa tracks the user should look at next,
/// with deep-links into the Wizard where available.
///
/// Pure function. No state, no I/O. Safe to call from any view.
///
/// The TaskRepository.starterTasks flow is intentionally NOT replaced —
/// both surfaces coexist on the Decision Tree result view.
enum VisaRecommender {

    /// Top 5 visas for the user's currently-selected country.
    ///
    /// Scoring (independent contributions, summed):
    ///   • Income match — visa's `monthlyIncomeEUR` vs a budget-tier target
    ///     (±25% bands). Visas with non-income criteria get a small neutral boost.
    ///   • Household compatibility — retiree → passive, family → work/family,
    ///     couple → flexible, single → DNV/work.
    ///   • Ancestry — if the user disclosed an ancestry and the visa's id matches
    ///     `Ancestry.descentVisaId`, a large boost overrides income ranking
    ///     (per Item 8 brief).
    ///
    /// Personal Considerations (LGBTQ+/Disabled/Veteran/Pregnant) are intentionally
    /// NOT scored here — VisaCatalog doesn't carry visa-level data for those signals
    /// today. DecisionEngine already handles them at the country level. Per brief:
    /// "if data missing, do not synthesize — leave un-filtered with a flag note."
    static func recommend(profile: UserProfile, ancestry: Ancestry = .none) -> [RankedVisa] {
        let pool = VisaCatalog.byCountry(profile.countryId)
        guard !pool.isEmpty else { return [] }

        let budgetTarget = budgetTargetEUR(profile.budget)

        let scored: [RankedVisa] = pool.map { visa in
            var score: Double = 0
            var reasons: [String] = []

            // 1. Income match
            if let visaIncome = visa.monthlyIncomeEUR, let target = budgetTarget {
                let ratio = Double(visaIncome) / Double(target)
                if ratio <= 0.75 {
                    score += 6
                    reasons.append("Comfortable income fit")
                } else if ratio <= 1.0 {
                    score += 10
                    reasons.append("Income matches budget")
                } else if ratio <= 1.25 {
                    score += 4
                    reasons.append("Income tight")
                }
                // ratio > 1.25 → 0 added; visa surfaces only if other factors carry it
            } else if visa.monthlyIncomeEUR == nil {
                // Non-income visas (points / employer / business / ancestry) get a small
                // neutral boost so they aren't crowded out by income visas the user can't see scored.
                score += 3
                reasons.append("Non-income criteria")
            }

            // 2. Household compatibility
            score += householdContribution(profile.household, visa: visa, reasons: &reasons)

            // 3. Ancestry override
            if let descentId = ancestry.descentVisaId, visa.id == descentId {
                score += 50
                reasons.insert("Matches your ancestry", at: 0)
            }

            return RankedVisa(visa: visa, score: score, reasons: reasons)
        }

        return Array(
            scored
                .filter { $0.score > 0 }
                .sorted { $0.score > $1.score }
                .prefix(5)
        )
    }

    /// Cross-country ancestry surfacing.
    ///
    /// When the user has, say, Italian ancestry but is browsing Spain destinations,
    /// `recommend(...)` (country-scoped to Spain) won't reach Italian Jure Sanguinis.
    /// This helper returns that visa so the UI can render a separate
    /// "Did you know — your ancestry unlocks a path here" hint card.
    ///
    /// Returns nil when:
    ///   • ancestry is .none
    ///   • the descent visa lives in the user's currently selected country
    ///     (recommend() already covers it)
    ///   • the visa isn't found in VisaCatalog
    static func ancestryHint(profile: UserProfile, ancestry: Ancestry) -> VisaInfo? {
        guard let descentId = ancestry.descentVisaId,
              let visa = VisaCatalog.byId(descentId),
              visa.countryId != profile.countryId
        else { return nil }
        return visa
    }

    // MARK: - Internals

    /// Approximate "what monthly income does the user have to clear" target per budget tier.
    /// Used as the denominator in the income-match ratio. Conservative — favors visas
    /// the user can actually meet rather than ones at the ceiling of the band.
    private static func budgetTargetEUR(_ raw: String) -> Int? {
        switch raw {
        case Budget.low.rawValue: return 1_500
        case Budget.medium.rawValue: return 3_000
        case Budget.high.rawValue: return 6_000
        default: return nil
        }
    }

    private static func householdContribution(
        _ household: String,
        visa: VisaInfo,
        reasons: inout [String]
    ) -> Double {
        switch household {
        case Household.retiree.rawValue:
            switch visa.category {
            case .passiveIncome:
                reasons.append("Built for retirees")
                return 12
            case .ancestry:
                return 4
            default:
                return 0
            }
        case Household.familyKids.rawValue, Household.singleParent.rawValue:
            switch visa.category {
            case .family:
                reasons.append("Family reunification route")
                return 10
            case .work:
                reasons.append("Work route with family inclusion")
                return 8
            case .passiveIncome:
                return 5
            case .digitalNomad:
                reasons.append("Remote-work flexibility")
                return 6
            case .ancestry:
                return 6
            default:
                return 0
            }
        case Household.couple.rawValue:
            switch visa.category {
            case .digitalNomad: return 8
            case .passiveIncome: return 6
            case .work: return 6
            case .ancestry: return 5
            default: return 0
            }
        case Household.singles.rawValue:
            switch visa.category {
            case .digitalNomad:
                reasons.append("Digital nomad path")
                return 10
            case .work: return 8
            case .student: return 6
            case .ancestry: return 4
            default: return 0
            }
        default:
            return 0
        }
    }
}
