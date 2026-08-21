import Foundation
import StoreKit

/// Grandfathering for users who bought GoThere back when it was a paid install.
///
/// When the app flips from paid ($2.99 / €2,99) to free-with-IAP, everyone who already
/// paid must keep full access. If they don't, they open the app one day and find the
/// content they bought sitting behind a new paywall — the fastest way to turn the
/// handful of existing buyers into 1-star reviews.
///
/// Apple's mechanism for this is the app transaction: `AppTransaction.shared` reports
/// when the user *originally* acquired the app, regardless of how many times they've
/// reinstalled or which device they're on. If that date is before the day the free
/// version went live, they paid for it.
///
/// The result feeds `PurchaseManager.hasAllAccess`, which is the single gate every
/// content check in the app already runs through (`isCountryUnlocked`, DocumentScan,
/// RealJourney, AI chat quota, Resources). No call sites change.
enum LegacyEntitlementService {

    // MARK: - Configuration

    /// The moment GoThere stopped being a paid install.
    ///
    /// The App Store price schedule was set to $0.00 across all 175 storefronts on
    /// 2026-08-21 (effective immediately, no binary required). Anyone whose original
    /// purchase predates this paid to install and is grandfathered into permanent
    /// all-access.
    ///
    /// Set to end-of-day rather than the exact minute of the flip, deliberately erring
    /// LATE: a slightly late cutoff grandfathers at most a few hours of free-era installs
    /// on an app with zero ratings — a rounding error. A cutoff even minutes early locks
    /// out a real paying customer, which costs a support ticket and a 1-star review.
    static let freemiumGoLiveDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 22
        components.hour = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
    }()

    /// Build number (`CFBundleVersion`) below which every install was necessarily paid,
    /// as a backstop for the date check.
    ///
    /// On iOS, `AppTransaction.originalAppVersion` carries the *build* number of the
    /// version the user first downloaded, not the marketing version.
    ///
    /// DISABLED (0), and it should stay that way for this flip. Build 60 (v1.9.2) was
    /// live on both sides of the price change — it was the last paid build AND is the
    /// first free one, since going free needed no new binary. So build 60 cannot tell a
    /// payer from a free installer, and treating it as paid would hand permanent
    /// all-access to every free download until the next build ships. The date is the
    /// only signal that actually discriminates here.
    ///
    /// Kept as a hook for a future paid→free flip that *does* coincide with a release.
    static let lastPaidBuild: Int = 0

    /// UserDefaults mirror so the entitlement survives a cold launch with no network and
    /// before `AppTransaction` resolves. Never expires — a paid install stays paid.
    private static let cacheKey = "legacy_paid_install"

    #if DEBUG
    /// Debug-only override so the grandfathered path can be exercised in the simulator
    /// and in TestFlight builds, where `AppTransaction` values are synthesized and the
    /// original purchase date reflects the TestFlight install rather than a real sale.
    private static let debugOverrideKey = "debug_force_legacy_paid_install"
    #endif

    // MARK: - Cached result

    /// Last known answer. Read synchronously by `PurchaseManager` at init so the very
    /// first render is already correct for a returning paid user.
    static var cachedIsLegacyPaidInstall: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: debugOverrideKey) { return true }
        #endif
        return UserDefaults.standard.bool(forKey: cacheKey)
    }

    // MARK: - Resolution

    /// Asks StoreKit when this user originally acquired the app and decides whether they
    /// predate the freemium flip.
    ///
    /// Returns `nil` when StoreKit can't answer — no local app transaction, offline, or
    /// a verification failure. `nil` means "unknown", NOT "not a legacy buyer": callers
    /// must leave any previously-granted entitlement alone rather than revoking it, so a
    /// flaky launch never strips a paying customer's access.
    ///
    /// Deliberately uses `AppTransaction.shared` and never `AppTransaction.refresh()`.
    /// Refresh can present a sign-in sheet, which is unacceptable at launch.
    static func resolve() async -> Bool? {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: debugOverrideKey) { return true }
        #endif

        do {
            let result = try await AppTransaction.shared
            guard case .verified(let appTransaction) = result else { return nil }

            var isLegacy = appTransaction.originalPurchaseDate < freemiumGoLiveDate

            // Backstop: an original build at or below the last paid release is a paid
            // install even if the date comparison says otherwise (e.g. the price flip
            // landed later than `freemiumGoLiveDate` anticipated).
            if !isLegacy, lastPaidBuild > 0,
               let originalBuild = Int(appTransaction.originalAppVersion.prefix(while: \.isNumber)),
               originalBuild > 0, originalBuild <= lastPaidBuild {
                isLegacy = true
            }

            if isLegacy {
                UserDefaults.standard.set(true, forKey: cacheKey)
            }
            return isLegacy
        } catch {
            print("LegacyEntitlementService: app transaction unavailable — \(error)")
            return nil
        }
    }

    /// Records a legacy entitlement discovered somewhere other than StoreKit — in
    /// practice, the Firestore mirror on a user's second device, where the local app
    /// transaction belongs to a free-era download but the account already earned access.
    static func rememberLegacyEntitlement() {
        UserDefaults.standard.set(true, forKey: cacheKey)
    }
}
