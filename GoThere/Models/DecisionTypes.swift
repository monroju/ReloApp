import Foundation

// MARK: - Enums

enum Household: String, CaseIterable, Identifiable {
    case familyKids = "Family with Kids"
    case couple = "Couple"
    case singles = "Single"
    case singleParent = "Single Parent"
    case retiree = "Retiree"
    var id: String { rawValue }
}

enum PersonalConsideration: String, CaseIterable, Identifiable {
    case lgbtq = "LGBTQ+"
    case disabled = "Disabled / Accessibility"
    case veteran = "Veteran"
    case pregnant = "Pregnant / Expecting"
    var id: String { rawValue }
}

enum Budget: String, CaseIterable, Identifiable {
    case low = "Budget-Friendly"
    case medium = "Mid-Range"
    case high = "Premium"
    var id: String { rawValue }
}

enum ClimatePref: String, CaseIterable, Identifiable {
    case warmCoastal = "Warm & Coastal"
    case temperate = "Temperate"
    case mountain = "Mountain"
    case noPreference = "No Preference"
    var id: String { rawValue }
}

enum LanguageComfort: String, CaseIterable, Identifiable {
    case native = "Fluent in local language"
    case some = "Basic knowledge"
    case none = "English only"
    var id: String { rawValue }
}

/// Optional citizenship-by-descent intake on the Decision Tree.
/// When set, VisaRecommender boosts the matching descent visa above income ranking
/// (and surfaces a cross-country ancestry hint when the descent visa lives outside
/// the user's currently selected country).
enum Ancestry: String, CaseIterable, Identifiable {
    case none = "None / Not sure"
    case italian = "Italian"
    case irish = "Irish"
    case german = "German"
    case polish = "Polish"
    case argentine = "Argentine"
    case hungarian = "Hungarian"
    case british = "British"

    var id: String { rawValue }

    /// Maps the ancestry to the VisaCatalog descent-visa id for that lineage.
    /// Nil for `.none` and for ancestries we don't yet have a descent route for.
    var descentVisaId: String? {
        switch self {
        case .italian: return "it_jure_sanguinis"
        case .irish: return "ie_fbr"
        case .german: return "de_stag_15"
        case .polish: return "pl_confirmation"
        case .argentine: return "ar_by_option"
        case .hungarian: return "hu_simplified"
        case .british: return "uk_ancestry"
        case .none: return nil
        }
    }
}

enum BusinessFocus: String, CaseIterable, Identifiable {
    case tech = "Tech / Startup"
    case tourism = "Tourism"
    case logistics = "Logistics"
    case agriculture = "Agriculture"
    case remoteWork = "Remote Work"
    case finance = "Finance"
    case none = "Not Applicable"
    var id: String { rawValue }
}

enum NightlifePref: String, CaseIterable, Identifiable {
    case important = "Important"
    case nice = "Nice to have"
    case notImportant = "Not Important"
    var id: String { rawValue }
}

enum DensityPref: String, CaseIterable, Identifiable {
    case high = "Large expat community"
    case medium = "Some expats"
    case low = "Mostly local"
    case noPreference = "No Preference"
    var id: String { rawValue }
}

// MARK: - User Profile

struct UserProfile: Codable {
    var household: String = Household.couple.rawValue
    var budget: String = Budget.medium.rawValue
    var climate: String = ClimatePref.noPreference.rawValue
    var preferCoastal: Bool = false
    var preferBigCity: Bool = false
    var language: String = LanguageComfort.none.rawValue
    var businessFocus: String = BusinessFocus.none.rawValue
    var nightlife: String = NightlifePref.notImportant.rawValue
    var density: String = DensityPref.noPreference.rawValue
    var safetyCritical: Bool = false
    var considerations: Set<String> = []
    /// Optional citizenship-by-descent signal. Stored as Ancestry.rawValue;
    /// VisaRecommender uses it to surface descent visas above income ranking.
    var ancestry: String = Ancestry.none.rawValue
    var countryId: String = "spain"
}

// MARK: - Ranked Destination

struct RankedDestination: Identifiable, Hashable {
    var id: String { destination.id }
    let destination: Destination
    let score: Double
    let reasons: [String]
}
