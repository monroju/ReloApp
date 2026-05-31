import Foundation

/// Per-country, per-persona inclusion notes loaded from `country_safety_profiles.json`.
/// Source: ILGA-Europe Rainbow Index, EU Disability Card directives, OECD maternity data,
/// SSA totalization agreements, and country family-law signals. Refresh annually.
///
/// Sibling file lives in `shared/country_safety_profiles.json` and is mirrored into both
/// the iOS bundle and Android assets so the data layer stays in sync.
struct CountrySafetyProfile: Decodable {
    let lgbtq: String?
    let disabled: String?
    let single_parent: String?
    let veteran: String?
    let pregnant: String?
    let neurodivergent: String?
    let senior: String?

    /// Map a PersonalConsideration rawValue to the matching note. Returns nil
    /// when the persona is not represented for that country.
    func note(for consideration: PersonalConsideration, householdIsSingleParent: Bool) -> String? {
        switch consideration {
        case .lgbtq:          return lgbtq
        case .disabled:       return disabled
        case .veteran:        return veteran
        case .pregnant:       return pregnant
        case .neurodivergent: return neurodivergent
        case .senior:         return senior
        }
    }
}

private struct SafetyProfilesEnvelope: Decodable {
    let countries: [String: CountrySafetyProfile]
}

enum CountrySafetyProfiles {
    private static var cache: [String: CountrySafetyProfile]?

    private static func load() -> [String: CountrySafetyProfile] {
        if let cached = cache { return cached }
        guard let url = Bundle.main.url(forResource: "country_safety_profiles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(SafetyProfilesEnvelope.self, from: data)
        else { return [:] }
        cache = envelope.countries
        return envelope.countries
    }

    static func profile(for countryId: String) -> CountrySafetyProfile? {
        load()[countryId]
    }

    /// Helper for single-parent households — returns a synthetic note when the user is
    /// a single parent (PersonalConsideration enum does not include it; Household does).
    static func singleParentNote(for countryId: String) -> String? {
        load()[countryId]?.single_parent
    }

    /// Returns notes for every active consideration, in stable display order.
    static func notes(for considerations: Set<PersonalConsideration>, countryId: String) -> [(PersonalConsideration, String)] {
        guard let profile = profile(for: countryId) else { return [] }
        let order: [PersonalConsideration] = [.lgbtq, .disabled, .veteran, .pregnant, .neurodivergent, .senior]
        return order.compactMap { c in
            guard considerations.contains(c),
                  let note = profile.note(for: c, householdIsSingleParent: false) else { return nil }
            return (c, note)
        }
    }
}

/// Lightweight persistence layer for PersonalConsiderations so they survive between
/// DecisionTree and Resources screens. Backed by UserDefaults — small, low-churn.
enum UserConsiderationsStore {
    private static let key = "gothere.user.considerations"
    private static let householdKey = "gothere.user.household"

    static func save(_ considerations: Set<String>, household: String) {
        UserDefaults.standard.set(Array(considerations), forKey: key)
        UserDefaults.standard.set(household, forKey: householdKey)
    }

    static func load() -> (considerations: Set<PersonalConsideration>, isSingleParent: Bool) {
        let raw = UserDefaults.standard.stringArray(forKey: key) ?? []
        let parsed = raw.compactMap { PersonalConsideration(rawValue: $0) }
        let household = UserDefaults.standard.string(forKey: householdKey) ?? ""
        return (Set(parsed), household == Household.singleParent.rawValue)
    }
}
