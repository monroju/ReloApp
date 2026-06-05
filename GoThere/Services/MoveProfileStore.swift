import Foundation

/// Lightweight UserDefaults-backed façade for the small pieces of "what GoThere
/// knows about the user's move" that aren't already owned by a Firestore
/// repository. Today that's the Cost Calculator's computed monthly total — the
/// sliders themselves stay screen-local (per the differentiation spec: persist
/// the *output*, not the inputs), but the resulting EUR figure is saved so the
/// Co-Pilot dashboard can cross-reference it against visa income thresholds.
///
/// Intentionally additive and dependency-free. It does NOT duplicate keys that
/// already live elsewhere — `target_move_millis` (VisaWizardViewModel) and
/// `gothere.user.household` / considerations (UserConsiderationsStore) are read
/// in place by the dashboard's read-model, not mirrored here.
enum MoveProfileStore {
    private static let costEURKey   = "gothere.move.estimatedMonthlyCostEUR"
    private static let costCityKey  = "gothere.move.costCity"
    private static let costCountryKey = "gothere.move.costCountry"
    private static let dependentsKey = "gothere.move.dependents"
    private static let costUpdatedAtKey = "gothere.move.costUpdatedAt"

    // MARK: - Calculator output

    /// Persist the Cost Calculator's computed monthly total (in EUR) plus the
    /// context it was computed for. Called from the calculator as inputs change.
    static func saveEstimatedCost(eur: Int, city: String, country: String, dependents: Int) {
        let d = UserDefaults.standard
        d.set(eur, forKey: costEURKey)
        d.set(city, forKey: costCityKey)
        d.set(country, forKey: costCountryKey)
        d.set(dependents, forKey: dependentsKey)
        d.set(Date().timeIntervalSince1970, forKey: costUpdatedAtKey)
    }

    /// Computed monthly cost in EUR, or nil if the user has never opened the
    /// calculator. Returned as Int? so the dashboard can distinguish "no estimate
    /// yet" (→ setup nudge) from a real €0.
    static var estimatedMonthlyCostEUR: Int? {
        guard UserDefaults.standard.object(forKey: costEURKey) != nil else { return nil }
        return UserDefaults.standard.integer(forKey: costEURKey)
    }

    static var costCity: String? { UserDefaults.standard.string(forKey: costCityKey) }
    static var costCountry: String? { UserDefaults.standard.string(forKey: costCountryKey) }

    /// Dependents the user selected in the calculator (for the income-threshold
    /// math). Defaults to 0 when never set.
    static var dependents: Int { UserDefaults.standard.integer(forKey: dependentsKey) }

    // MARK: - Target move date (read-through to the canonical key)

    /// Canonical target-move-date key, written by VisaWizardViewModel on wizard
    /// completion. Exposed here as a typed read so the dashboard doesn't have to
    /// know the raw key or the millis convention. Nil when unset or in the past.
    static var targetMoveDate: Date? {
        let millis = UserDefaults.standard.double(forKey: "target_move_millis")
        guard millis > 0 else { return nil }
        return Date(timeIntervalSince1970: millis / 1000)
    }
}
