import StoreKit
import SwiftUI

/// One-time offer shown right after a descent path is tracked: the country's plan
/// first (one purchase), All-Access second. Shown at most once per path and never
/// when the country is already unlocked. The checklist and score stay free.
struct PlanBUnlockOfferSheet: View {
    let path: PlanBPath
    let countryId: String
    let countryName: String

    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showAllAccess = false
    @State private var purchasing = false

    static func shownKey(_ pathId: String) -> String { "gothere.planb.offerShown.\(pathId)" }
    static func productId(for countryId: String) -> String { "com.gothere.\(countryId)_pack" }

    private var product: Product? {
        purchaseManager.products.first { $0.id == Self.productId(for: countryId) }
    }

    private var readyCount: Int { path.activeItems.filter { $0.state == .done }.count }
    private var totalCount: Int { path.activeItems.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        PlanBScoreRing(score: PlanBScore.path(path), size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your \(countryName) path is set up")
                                .font(.title3.bold())
                            Text("\(readyCount) of \(totalCount) documents ready")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Unlock your \(countryName) plan")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 12) {
                        bullet("calendar", "Every stage after you gather your papers, with how long each one takes")
                        bullet("doc.text.magnifyingglass", "All of GoThere's \(countryName) guides, tasks and sources")
                        bullet("checkmark.seal", "One purchase. No subscription.")
                    }

                    Button {
                        buyCountry()
                    } label: {
                        HStack {
                            if purchasing { ProgressView().tint(.white) }
                            Text(product.map { String(localized: "Unlock \(countryName) for \($0.displayPrice)") }
                                 ?? String(localized: "Unlock \(countryName)"))
                                .font(.body.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.goPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(product == nil || purchasing)

                    Button {
                        Analytics.log(.planbOfferTapped, properties: props(choice: "all_access"))
                        showAllAccess = true
                    } label: {
                        Text("Or unlock every country with All-Access")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }

                    Text("Your checklist and readiness score stay free either way.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        Analytics.log(.planbOfferTapped, properties: props(choice: "dismiss"))
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAllAccess) {
                PaywallView(source: "planb_offer").environmentObject(purchaseManager)
            }
            .onChange(of: purchaseManager.isCountryUnlocked(countryId)) { _, unlocked in
                if unlocked { dismiss() }
            }
            .task {
                await purchaseManager.loadProductsIfNeeded()
            }
        }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.goPrimary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func props(choice: String? = nil) -> [String: Any] {
        var p: [String: Any] = ["cc": path.countryCode, "country_id": countryId]
        if let choice { p["choice"] = choice }
        return p
    }

    private func buyCountry() {
        guard let product else { return }
        Analytics.log(.planbOfferTapped, properties: props(choice: "country"))
        Analytics.paywallSource = "planb_offer"
        purchasing = true
        Task {
            try? await purchaseManager.purchase(product)
            purchasing = false
        }
    }
}
