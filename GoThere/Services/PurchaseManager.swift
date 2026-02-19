import Foundation
import StoreKit
import FirebaseFirestore

private typealias StoreTransaction = StoreKit.Transaction

/// Manages in-app purchases using StoreKit 2.
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let productPortugal = "com.gothere.portugal_pack"
    static let productMexico = "com.gothere.mexico_pack"
    static let productAllCountries = "com.gothere.all_countries"

    @Published var unlockedCountries: Set<String> = ["spain"]  // Spain always unlocked
    @Published var products: [Product] = []

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    func loadProducts() async {
        do {
            let productIds = [Self.productPortugal, Self.productMexico, Self.productAllCountries]
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchased(transaction)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        for await result in StoreTransaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                await updatePurchased(transaction)
            }
        }
    }

    func isCountryUnlocked(_ countryId: String) -> Bool {
        unlockedCountries.contains(countryId)
    }

    func formattedPrice(for productId: String) -> String {
        products.first { $0.id == productId }?.displayPrice ?? "$4.99"
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

    private func updatePurchased(_ transaction: StoreTransaction) async {
        switch transaction.productID {
        case Self.productPortugal:
            unlockedCountries.insert("portugal")
        case Self.productMexico:
            unlockedCountries.insert("mexico")
        case Self.productAllCountries:
            unlockedCountries.insert("portugal")
            unlockedCountries.insert("mexico")
        default:
            break
        }
        await syncToFirestore()
    }

    private func syncToFirestore() async {
        guard let uid = AuthService.shared.uid else { return }
        let db = Firestore.firestore()
        try? await db.collection("users").document(uid).setData([
            "unlockedCountries": Array(unlockedCountries)
        ], merge: true)
    }

    func loadFromFirestore() async {
        guard let uid = AuthService.shared.uid else { return }
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let countries = doc.data()?["unlockedCountries"] as? [String] {
                unlockedCountries = Set(countries).union(["spain"])
            }
        } catch {
            print("Error loading purchases: \(error)")
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
