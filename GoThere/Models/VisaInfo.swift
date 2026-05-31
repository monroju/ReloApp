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
    /// Per-dependent income add-on as a fraction of the base threshold (e.g. 0.25
    /// = +25% per dependent for Spain NLV per IPREM). Nil for visas with no
    /// formal per-dependent income rule.
    /// Foundation Wave 1 — unblocks per-dependent affordability math.
    var dependentMultiplier: Double? = nil
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
    /// Optional preferential tax regimes the user may opt into when holding this visa
    /// (e.g. Beckham Law on Spain DNV, IFICI/NHR-successor on Portugal D-visas).
    /// Wave 2 — surfaces in VisaCompare + Wizard summary as an "ask your tax advisor" hint.
    var taxRegimes: [TaxRegime] = []
    /// Inclusivity signals surfaced in VisaCompare + decision-tree results when the
    /// matching PersonalConsideration is selected. Use values from `InclusivityFlag`.
    /// Empty means no explicit accommodation beyond what category implies.
    var inclusivityFlags: [String] = []
}

/// Canonical inclusivity-flag values for VisaInfo.inclusivityFlags.
/// Treat as a string-constant namespace — kept as plain strings so the catalog stays
/// readable and so cross-platform JSON exports remain trivial.
enum InclusivityFlag {
    static let familyReunification     = "family_reunification"      // brings spouse/children/parents
    static let singleParentFriendly    = "single_parent_friendly"    // dependent rules don't penalise solo applicants
    static let lgbtqMarriageRecognized = "lgbtq_marriage_recognized" // same-sex spouse counted equally
    static let caregiverPathway        = "caregiver_pathway"         // caregiver permitted to accompany
    static let disabilityAccommodation = "disability_accommodation"  // disability-aware income / medical rules
    static let seniorFriendly          = "senior_friendly"           // retiree / passive-income suitable
    static let veteranBenefits         = "veteran_benefits"          // SSA totalization or VA FMP active
    static let ancestryFastTrack       = "ancestry_fast_track"       // citizenship-by-descent route
}

/// Preferential tax regime available to holders of a given visa. Informational
/// only — actual eligibility depends on filing posture and is decided by Hacienda
/// / AT / equivalent authority, not by this app.
struct TaxRegime: Codable, Hashable {
    /// Display name, e.g. "Beckham Law", "NHR successor (IFICI)", "RFA".
    let name: String
    /// Optional flat-rate income tax percent expressed as a decimal (e.g. 0.24 for 24%).
    /// Nil when the regime is more nuanced than a single rate.
    let flatRatePercent: Double?
    /// Bullet criteria the user must meet to qualify. Short, verifiable, plain English.
    let eligibilityCriteria: [String]
    /// When the user must elect into the regime, e.g. "Within 6 months of becoming
    /// Spanish tax resident". Nil if not time-bound.
    let applicationWindow: String?
}

extension VisaInfo {
    /// Visa IDs that explicitly require a university degree (or degree-equivalent).
    /// Everything else is treated as not strictly requiring one. Curated rather than
    /// stored per-entry so the 47-row catalog stays readable; refresh alongside it.
    private static let degreeRequiredIds: Set<String> = [
        "it_dnv",          // Italy DNV — "highly skilled" (degree / 6yr experience)
        "de_blue_card",    // EU Blue Card — university degree mandatory
        "de_job_seeker",   // Job Seeker — degree required
    ]

    /// True when the track does NOT strictly require a university degree — the key
    /// unlock for lower-income / no-degree users. Ancestry, passive-income, family,
    /// self-employed, investment and points/apprenticeship tracks generally qualify.
    var requiresNoDegree: Bool {
        !Self.degreeRequiredIds.contains(id)
    }

    /// True when the track can be satisfied with independent income — freelance/gig
    /// earnings, self-employment, savings, or passive income — rather than a salaried
    /// job offer or employer sponsorship. Surfaces "bring your own income" paths.
    var acceptsIndependentIncome: Bool {
        switch category {
        case .passiveIncome, .selfEmployed, .digitalNomad, .investment:
            return true
        default:
            return false
        }
    }

    /// Effective monthly EUR income threshold for the given dependent count.
    /// Returns nil when the visa has no structured income threshold. Falls
    /// back to single-applicant figure when `dependentMultiplier` is nil.
    func requiredMonthlyEUR(dependents: Int) -> Int? {
        guard let base = monthlyIncomeEUR else { return nil }
        guard dependents > 0 else { return base }
        guard let multiplier = dependentMultiplier else { return base }
        let addition = Double(base) * multiplier * Double(dependents)
        return base + Int(addition.rounded())
    }

    /// Inclusivity flags merged with category- and country-implied defaults.
    /// Use when deciding whether to surface a visa to a user with a given PersonalConsideration.
    /// Category implies:  .family → family_reunification, .ancestry → ancestry_fast_track,
    ///                    .passiveIncome → senior_friendly.
    /// Country implies:   marriage-equality countries → lgbtq_marriage_recognized,
    ///                    US-totalization countries  → veteran_benefits.
    var effectiveInclusivityFlags: Set<String> {
        var flags = Set(inclusivityFlags)
        switch category {
        case .family:        flags.insert(InclusivityFlag.familyReunification)
        case .ancestry:      flags.insert(InclusivityFlag.ancestryFastTrack)
        case .passiveIncome: flags.insert(InclusivityFlag.seniorFriendly)
        default: break
        }
        // Country-level signals — kept in sync with country_safety_profiles.json.
        let marriageEqualityCountries: Set<String> = [
            "spain", "portugal", "canada", "ireland", "germany", "uk_ancestry",
            "argentina", "mexico"
            // italy = civil unions only; not flagged here
        ]
        if marriageEqualityCountries.contains(countryId) {
            flags.insert(InclusivityFlag.lgbtqMarriageRecognized)
        }
        let usTotalizationCountries: Set<String> = [
            "spain", "portugal", "italy", "germany", "ireland",
            "poland", "hungary", "uk_ancestry", "canada"
            // mexico = VA FMP only, no totalization; argentina = neither
        ]
        if usTotalizationCountries.contains(countryId) {
            flags.insert(InclusivityFlag.veteranBenefits)
        }
        return flags
    }
}
