import Foundation

/// First-install sampler: unlocks one paid country (Portugal) for 7 days from first launch,
/// so new users feel the full content depth before hitting the paywall. Mirrors Localista's
/// freemium-preview pattern (premium guide unlocked for first-session users).
///
/// Tied to the install date stored in UserDefaults, NOT to anything resettable by signing
/// out, so users can't farm repeat trials. After expiry, normal paywall gating applies.
enum FirstWeekTrialService {
    static let sampleCountryId = "portugal"
    private static let installedAtKey = "first_install_timestamp"
    private static let trialLengthDays: TimeInterval = 7 * 24 * 60 * 60

    /// Call once on app launch.
    static func bootstrap() {
        let defaults = UserDefaults.standard
        if defaults.double(forKey: installedAtKey) == 0 {
            defaults.set(Date().timeIntervalSince1970, forKey: installedAtKey)
        }
    }

    static var isActive: Bool {
        let installed = UserDefaults.standard.double(forKey: installedAtKey)
        if installed == 0 { return false }
        return Date().timeIntervalSince1970 - installed < trialLengthDays
    }

    static var daysRemaining: Int {
        let installed = UserDefaults.standard.double(forKey: installedAtKey)
        if installed == 0 { return 0 }
        let secondsLeft = trialLengthDays - (Date().timeIntervalSince1970 - installed)
        return max(0, Int(ceil(secondsLeft / (24 * 60 * 60))))
    }

    static func unlocksCountry(_ countryId: String) -> Bool {
        isActive && countryId == sampleCountryId
    }
}
