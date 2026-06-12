import Foundation

/// Per-country medication & care continuity notes loaded from `care_continuity_profiles.json`.
/// Covers ADHD stimulant availability, gender-affirming hormone access, insulin, and the
/// rules for carrying prescription meds at entry (Schengen Art. 75, COFEPRIS, etc.).
///
/// Sibling file lives in `shared/care_continuity_profiles.json` and is mirrored into both
/// the iOS bundle and Android assets. Canonical sources: INCB country regulations,
/// CDC Yellow Book, national medicine agencies. Refresh annually alongside the safety profiles.
struct CareContinuityProfile: Decodable {
    let adhd: String?
    let hrt: String?
    let insulin: String?
    let bring_in: String?
}

private struct CareContinuityEnvelope: Decodable {
    let countries: [String: CareContinuityProfile]
}

enum CareContinuityProfiles {
    private static var cache: [String: CareContinuityProfile]?

    private static func load() -> [String: CareContinuityProfile] {
        if let cached = cache { return cached }
        guard let url = Bundle.main.url(forResource: "care_continuity_profiles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(CareContinuityEnvelope.self, from: data)
        else { return [:] }
        cache = envelope.countries
        return envelope.countries
    }

    static func profile(for countryId: String) -> CareContinuityProfile? {
        load()[countryId]
    }
}
