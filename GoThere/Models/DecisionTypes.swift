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
    var countryId: String = "spain"
}

// MARK: - Ranked Destination

struct RankedDestination: Identifiable, Hashable {
    var id: String { destination.id }
    let destination: Destination
    let score: Double
    let reasons: [String]
}
