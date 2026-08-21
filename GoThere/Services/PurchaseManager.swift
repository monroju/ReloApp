import Foundation
import StoreKit
import FirebaseFirestore

private typealias StoreTransaction = StoreKit.Transaction

/// State machine for the all-access subscription introduced in the freemium pivot.
/// Encoded to Firestore via `dictionaryRepresentation`; decoded by `loadFromFirestore`.
enum SubscriptionStatus: Equatable {
    case none
    case active(expires: Date)
    case billingRetry
    case gracePeriod
    case expired

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    /// Firestore-friendly representation. Date is stored as a Unix timestamp so the
    /// document is portable across SDKs (Web admin, server functions, Android client).
    var dictionaryRepresentation: [String: Any] {
        switch self {
        case .none: return ["state": "none"]
        case .expired: return ["state": "expired"]
        case .billingRetry: return ["state": "billingRetry"]
        case .gracePeriod: return ["state": "gracePeriod"]
        case .active(let expires):
            return ["state": "active", "expiresAt": expires.timeIntervalSince1970]
        }
    }

    static func from(dictionary dict: [String: Any]) -> SubscriptionStatus {
        guard let state = dict["state"] as? String else { return .none }
        switch state {
        case "active":
            guard let ts = dict["expiresAt"] as? TimeInterval else { return .expired }
            return .active(expires: Date(timeIntervalSince1970: ts))
        case "billingRetry": return .billingRetry
        case "gracePeriod": return .gracePeriod
        case "expired": return .expired
        default: return .none
        }
    }
}

/// Manages in-app purchases using StoreKit 2.
///
/// Two product families coexist during the freemium pivot:
///   • Legacy per-country one-time IAPs (`com.gothere.<country>_pack`) — pre-freemium
///     users keep their entitlements via the existing `unlockedCountries` path.
///   • New all-access subscriptions (`com.gothere.all_access_*`) and region bundles
///     (`com.gothere.europe_bundle`, `americas_bundle`) — drive `hasAllAccess` and
///     surface in the new PaywallView sections (Item 11).
///
/// Call sites use `isCountryUnlocked(_:)` unchanged — it ORs `hasAllAccess` with the
/// legacy per-country set so existing gates auto-honor the new SKUs.
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Product IDs

    // DEPRECATED 2026-Q3 — kept for owners pre-freemium. Existing buyers continue to
    // unlock the corresponding country via these one-time IAPs. New users see the
    // subscription + bundle SKUs below as the headline offering on PaywallView.
    static let productPortugal = "com.gothere.portugal_pack"
    static let productMexico = "com.gothere.mexico_pack"
    static let productIreland = "com.gothere.ireland_pack"
    static let productItaly = "com.gothere.italy_pack"
    static let productGermany = "com.gothere.germany_pack"
    static let productPoland = "com.gothere.poland_pack"
    static let productArgentina = "com.gothere.argentina_pack"
    static let productHungary = "com.gothere.hungary_pack"
    static let productUkAncestry = "com.gothere.uk_ancestry_pack"
    static let productAllCountries = "com.gothere.all_countries"

    // New SKUs for the freemium pivot. Runtime-safe — `loadProducts` tolerates
    // products that aren't yet configured in ASC; they simply don't appear in
    // `products` until they're created.
    static let productAllAccessMonthly = "com.gothere.all_access_monthly"
    static let productAllAccessAnnual = "com.gothere.all_access_annual"
    static let productEuropeBundle = "com.gothere.europe_bundle"
    static let productAmericasBundle = "com.gothere.americas_bundle"

    /// Countries unlocked by the Europe region bundle. Excludes Spain (always free).
    static let europeBundleCountries: [String] = [
        "portugal", "ireland", "italy", "germany", "poland", "hungary", "uk_ancestry"
    ]

    /// Countries unlocked by the Americas region bundle. Excludes Canada (always free).
    static let americasBundleCountries: [String] = ["mexico", "argentina"]

    static let allPaidCountries: [String] = europeBundleCountries + americasBundleCountries

    // MARK: - Published state

    /// Spain and Canada are always free.
    /// Spain is GoThere's original launch destination.
    /// Canada is free for the v1 launch of the Fast-Track Eligibility module to ride the Bill C-3 news cycle.
    @Published var unlockedCountries: Set<String> = ["spain", "canada"]
    @Published var products: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .none
    /// Tracks owned non-consumable product IDs (legacy packs + bundles + all_countries).
    /// Used by `hasAllAccess` for the bundle-combo path. Subscription products are
    /// reflected via `subscriptionStatus` instead.
    @Published var ownedSKUs: Set<String> = []

    /// Server-granted, time-boxed premium window from the referral loop (a "free
    /// month"). Mirrored on `users/{uid}.promoAccessUntil` (unix seconds) by the
    /// redeemReferral Cloud Function. Deliberately SEPARATE from
    /// `subscriptionStatus` so the launch-time StoreKit reconcile — which has no
    /// real store receipt to see behind a promo grant — never clobbers it.
    @Published var promoAccessUntil: Date? = nil

    /// True when this user bought GoThere while it was a paid install, before the
    /// freemium flip. Grandfathers them into permanent all-access so the paywall never
    /// appears in front of content they already paid for.
    ///
    /// Seeded synchronously from the UserDefaults cache so the first render is correct,
    /// then confirmed against StoreKit's app transaction and mirrored to Firestore.
    /// Only ever set to `true` — see `refreshLegacyEntitlement()`.
    @Published var isLegacyPaidInstall: Bool = LegacyEntitlementService.cachedIsLegacyPaidInstall

    // MARK: - Derived state

    /// True when the user has full content access through any of: an active
    /// subscription, the legacy `all_countries` lifetime IAP, OR both region bundles.
    /// Wired into `isCountryUnlocked(_:)` so new SKUs unlock content without changing
    /// existing call sites.
    var hasAllAccess: Bool {
        // Paid-install buyers from before the freemium pivot keep everything, forever.
        // Checked first because it's a local, offline-safe answer.
        if isLegacyPaidInstall { return true }
        if let until = promoAccessUntil, until > Date() { return true }
        if subscriptionStatus.isActive { return true }
        if ownedSKUs.contains(Self.productAllCountries) { return true }
        if ownedSKUs.contains(Self.productEuropeBundle) && ownedSKUs.contains(Self.productAmericasBundle) {
            return true
        }
        // Legacy pre-freemium owners may restore from Firestore docs written before
        // `ownedSKUs` existed — fall back to inferring all-access when every paid
        // country sits in `unlockedCountries`.
        if Self.allPaidCountries.allSatisfy({ unlockedCountries.contains($0) }) { return true }
        return false
    }

    // MARK: - Lifecycle

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await refreshLegacyEntitlement()
            await loadProducts()
            await reconcileEntitlements(silent: true)
        }
    }

    // MARK: - Legacy paid-install grandfathering

    /// Confirms the pre-freemium paid-install entitlement against StoreKit's app
    /// transaction and mirrors the result to Firestore.
    ///
    /// Only ever grants — never revokes. `LegacyEntitlementService.resolve()` returns
    /// `nil` when StoreKit can't answer (offline, missing local transaction), and a
    /// "don't know" must never strip access from someone who paid.
    func refreshLegacyEntitlement() async {
        guard let isLegacy = await LegacyEntitlementService.resolve(), isLegacy else { return }
        guard !isLegacyPaidInstall else { return }
        isLegacyPaidInstall = true
        Analytics.log(.purchaseCompleted, properties: [
            "product_id": "legacy_paid_install",
            "is_subscription": false,
            "is_bundle": true,
            "grandfathered": true
        ])
        await syncToFirestore()
    }

    // MARK: - Product loading

    func loadProducts() async {
        do {
            let productIds = [
                // Legacy per-country IAPs (deprecated for new users; honored for owners).
                Self.productPortugal,
                Self.productMexico,
                Self.productIreland,
                Self.productItaly,
                Self.productGermany,
                Self.productPoland,
                Self.productArgentina,
                Self.productHungary,
                Self.productUkAncestry,
                Self.productAllCountries,
                // Freemium pivot SKUs.
                Self.productAllAccessMonthly,
                Self.productAllAccessAnnual,
                Self.productEuropeBundle,
                Self.productAmericasBundle
            ]
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase + restore

    func purchase(_ product: Product) async throws {
        Analytics.log(.purchaseInitiated, properties: [
            "product_id": product.id,
            "price": (product.price as NSDecimalNumber).doubleValue,
            "currency": product.priceFormatStyle.currencyCode
        ])
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchased(transaction)
                await transaction.finish()
            case .userCancelled:
                Analytics.log(.purchaseFailed, properties: ["product_id": product.id, "reason": "user_cancelled"])
            case .pending:
                Analytics.log(.purchaseFailed, properties: ["product_id": product.id, "reason": "pending"])
            @unknown default:
                break
            }
        } catch {
            Analytics.log(.purchaseFailed, properties: ["product_id": product.id, "reason": "exception"])
            throw error
        }
    }

    func restorePurchases() async {
        // User-initiated — fires purchase analytics for each restored entitlement,
        // matching the original behavior.
        await reconcileEntitlements(silent: false)
    }

    // MARK: - Entitlement evaluation

    /// Walks `Transaction.currentEntitlements`, re-evaluates which non-consumables are
    /// owned, and refreshes subscription state from the most-recent renewable
    /// transaction.
    /// Does NOT call `transaction.finish()` — currentEntitlements are already-delivered
    /// entitlements; the original `restorePurchases` followed the same pattern.
    /// `silent: true` is used at launch so existing entitlements don't re-fire as fresh purchases.
    private func reconcileEntitlements(silent: Bool) async {
        var seenSubscription = false
        for await result in StoreTransaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                await updatePurchased(transaction, silent: silent)
                if transaction.productType == .autoRenewable {
                    seenSubscription = true
                }
            }
        }
        if !seenSubscription, subscriptionStatus.isActive {
            // The previously-active sub is gone from currentEntitlements — treat as expired.
            subscriptionStatus = .expired
            await syncToFirestore()
        }
    }

    // MARK: - Country gating

    func isCountryUnlocked(_ countryId: String) -> Bool {
        if hasAllAccess { return true }
        if FirstWeekTrialService.unlocksCountry(countryId) { return true }
        return unlockedCountries.contains(countryId)
    }

    func formattedPrice(for productId: String) -> String {
        products.first { $0.id == productId }?.displayPrice ?? "$4.99"
    }

    /// Optimistically applies a server-granted referral month so the UI unlocks
    /// the moment `redeemReferral` returns, without waiting for the Firestore
    /// mirror to propagate back. Extends, never shortens.
    func applyPromoGrant(until: Date) {
        if let current = promoAccessUntil, current > until { return }
        promoAccessUntil = until
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreTransaction.updates {
                if let transaction = try? await self?.checkVerified(result) {
                    await self?.updatePurchased(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified(_ result: VerificationResult<StoreTransaction>) throws -> StoreTransaction {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let transaction):
            return transaction
        }
    }

    /// Apply a verified transaction to local state and Firestore.
    /// `silent: true` suppresses purchaseCompleted / countryUnlocked analytics — used by
    /// `refreshEntitlements` at launch so existing entitlements don't re-fire as fresh purchases.
    private func updatePurchased(_ transaction: StoreTransaction, silent: Bool = false) async {
        let productId = transaction.productID
        let unlockedFromThis: [String]
        var isSubscription = false

        switch productId {
        case Self.productPortugal:        unlockedFromThis = ["portugal"]
        case Self.productMexico:          unlockedFromThis = ["mexico"]
        case Self.productIreland:         unlockedFromThis = ["ireland"]
        case Self.productItaly:           unlockedFromThis = ["italy"]
        case Self.productGermany:         unlockedFromThis = ["germany"]
        case Self.productPoland:          unlockedFromThis = ["poland"]
        case Self.productArgentina:       unlockedFromThis = ["argentina"]
        case Self.productHungary:         unlockedFromThis = ["hungary"]
        case Self.productUkAncestry:      unlockedFromThis = ["uk_ancestry"]
        case Self.productAllCountries:
            unlockedFromThis = Self.allPaidCountries
        case Self.productEuropeBundle:
            unlockedFromThis = Self.europeBundleCountries
        case Self.productAmericasBundle:
            unlockedFromThis = Self.americasBundleCountries
        case Self.productAllAccessMonthly, Self.productAllAccessAnnual:
            unlockedFromThis = []
            isSubscription = true
        default:
            unlockedFromThis = []
        }

        // Track owned SKU (non-consumables only).
        if !isSubscription {
            // If the transaction is revoked we should drop the SKU; otherwise add it.
            if transaction.revocationDate == nil {
                ownedSKUs.insert(productId)
            } else {
                ownedSKUs.remove(productId)
            }
        }

        unlockedFromThis.forEach { unlockedCountries.insert($0) }

        // Subscription state evaluation.
        if isSubscription {
            await evaluateSubscription(transaction)
            // Write the iapPurchases/{originalTransactionId} lookup so the
            // Firebase IAP function (Item 12) can map ASC Server Notifications
            // back to this Firebase user on renewal / refund / expiration.
            await writePurchaseLookup(transaction)
        }

        if !silent {
            Analytics.log(.purchaseCompleted, properties: [
                "product_id": productId,
                "transaction_id": String(transaction.id),
                "countries_unlocked": unlockedFromThis,
                "is_bundle": productId == Self.productAllCountries
                    || productId == Self.productEuropeBundle
                    || productId == Self.productAmericasBundle,
                "is_subscription": isSubscription
            ])
            unlockedFromThis.forEach { country in
                Analytics.log(.countryUnlocked, country: country, extra: ["product_id": productId])
            }
        }

        await syncToFirestore()
    }

    /// Maps a verified auto-renewable transaction to our `SubscriptionStatus` enum.
    /// Uses `Product.SubscriptionInfo.status` when the product is loaded (gives accurate
    /// billing-retry / grace-period detection); falls back to `expirationDate` heuristics
    /// when the product hasn't been loaded yet.
    private func evaluateSubscription(_ transaction: StoreTransaction) async {
        // Handle revocation immediately.
        if transaction.revocationDate != nil {
            subscriptionStatus = .expired
            return
        }

        let product = products.first { $0.id == transaction.productID }
        let now = Date()

        // Detailed path — query SubscriptionInfo.status when product is loaded.
        if let subInfo = product?.subscription {
            do {
                let statuses = try await subInfo.status
                if let first = statuses.first {
                    switch first.state {
                    case .subscribed:
                        if let expires = transaction.expirationDate {
                            subscriptionStatus = .active(expires: expires)
                            return
                        }
                    case .inBillingRetryPeriod:
                        subscriptionStatus = .billingRetry
                        return
                    case .inGracePeriod:
                        subscriptionStatus = .gracePeriod
                        return
                    case .expired, .revoked:
                        subscriptionStatus = .expired
                        return
                    default:
                        break
                    }
                }
            } catch {
                // Fall through to the heuristic path below.
            }
        }

        // Heuristic fallback — accept the entitlement when the expiration is in the future.
        if let expires = transaction.expirationDate, expires > now {
            subscriptionStatus = .active(expires: expires)
        } else {
            subscriptionStatus = .expired
        }
    }

    // MARK: - Firestore sync

    /// Writes the `iapPurchases/{originalTransactionId}` lookup row used by the
    /// Firebase IAP function (Item 12) to map Apple Server Notifications back
    /// to this Firebase user. Only called for auto-renewable transactions —
    /// one-time IAPs don't generate notifications.
    private func writePurchaseLookup(_ transaction: StoreTransaction) async {
        guard let uid = AuthService.shared.uid else { return }
        let key = String(transaction.originalID)
        let db = Firestore.firestore()
        try? await db.collection("iapPurchases").document(key).setData([
            "uid": uid,
            "productId": transaction.productID,
            "platform": "ios",
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    private func syncToFirestore() async {
        guard let uid = AuthService.shared.uid else { return }
        let db = Firestore.firestore()
        var payload: [String: Any] = [
            "unlockedCountries": Array(unlockedCountries),
            "ownedSKUs": Array(ownedSKUs),
            "subscriptionStatus": subscriptionStatus.dictionaryRepresentation,
            "hasAllAccess": hasAllAccess
        ]
        // Write-once: only ever set the flag, never clear it. A device that can't see
        // the app transaction must not erase the entitlement for the user's other
        // devices.
        if isLegacyPaidInstall {
            payload["legacyPaidInstall"] = true
        }
        try? await db.collection("users").document(uid).setData(payload, merge: true)
    }

    func loadFromFirestore() async {
        guard let uid = AuthService.shared.uid else { return }
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else { return }

            if let countries = data["unlockedCountries"] as? [String] {
                unlockedCountries = Set(countries).union(["spain", "canada"])
            }
            if let skus = data["ownedSKUs"] as? [String] {
                ownedSKUs = Set(skus)
            }
            if let subDict = data["subscriptionStatus"] as? [String: Any] {
                subscriptionStatus = SubscriptionStatus.from(dictionary: subDict)
            }
            // Pre-freemium paid-install grandfathering, earned on another device.
            // Grant-only: a `false`/absent field never revokes a local grant.
            if data["legacyPaidInstall"] as? Bool == true, !isLegacyPaidInstall {
                isLegacyPaidInstall = true
                LegacyEntitlementService.rememberLegacyEntitlement()
            }
            // Referral / promo grant window. Never written back by syncToFirestore
            // (that payload omits it), so a StoreKit reconcile can't shorten it.
            if let ts = data["promoAccessUntil"] as? TimeInterval {
                promoAccessUntil = Date(timeIntervalSince1970: ts)
            }
        } catch {
            print("Error loading purchases: \(error)")
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
