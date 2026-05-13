import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.goPrimary)

                        Text("Unlock More Destinations")
                            .font(.title2.bold())

                        Text("Spain and Canada are free. Unlock Portugal, Mexico, Ireland, Italy, Germany, Poland, Argentina, Hungary, or UK Ancestry — or grab the bundle for full access to every visa guide, task list, and resource.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Products
                    VStack(spacing: 12) {
                        purchaseCard(
                            emoji: "\u{1F1F5}\u{1F1F9}",
                            title: "Portugal Pack",
                            description: "D7 & D8 visa guides, tasks, and resources",
                            productId: PurchaseManager.productPortugal,
                            countryId: "portugal"
                        )

                        purchaseCard(
                            emoji: "\u{1F1F2}\u{1F1FD}",
                            title: "Mexico Pack",
                            description: "Temporary resident visa guides, tasks, and resources",
                            productId: PurchaseManager.productMexico,
                            countryId: "mexico"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EE}\u{1F1EA}",
                            title: "Ireland Pack",
                            description: "Foreign Births Register — Irish/EU citizenship by descent",
                            productId: PurchaseManager.productIreland,
                            countryId: "ireland"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EE}\u{1F1F9}",
                            title: "Italy Pack",
                            description: "Jure sanguinis — Italian/EU citizenship by descent",
                            productId: PurchaseManager.productItaly,
                            countryId: "italy"
                        )

                        purchaseCard(
                            emoji: "\u{1F1E9}\u{1F1EA}",
                            title: "Germany Pack",
                            description: "Article 116 + StAG §15 citizenship restoration",
                            productId: PurchaseManager.productGermany,
                            countryId: "germany"
                        )

                        purchaseCard(
                            emoji: "\u{1F1F5}\u{1F1F1}",
                            title: "Poland Pack",
                            description: "Confirmation of Polish citizenship by descent",
                            productId: PurchaseManager.productPoland,
                            countryId: "poland"
                        )

                        purchaseCard(
                            emoji: "\u{1F1E6}\u{1F1F7}",
                            title: "Argentina Pack",
                            description: "Citizenship by option — for children of native Argentines",
                            productId: PurchaseManager.productArgentina,
                            countryId: "argentina"
                        )

                        purchaseCard(
                            emoji: "\u{1F1ED}\u{1F1FA}",
                            title: "Hungary Pack",
                            description: "Simplified naturalization — Hungarian descent + language",
                            productId: PurchaseManager.productHungary,
                            countryId: "hungary"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EC}\u{1F1E7}",
                            title: "UK Ancestry Pack",
                            description: "5-year work visa for Commonwealth citizens with a UK-born grandparent",
                            productId: PurchaseManager.productUkAncestry,
                            countryId: "uk_ancestry"
                        )

                        purchaseCard(
                            emoji: "\u{1F30D}",
                            title: "All Countries",
                            description: "Unlock everything - best value!",
                            productId: PurchaseManager.productAllCountries,
                            countryId: nil
                        )
                    }

                    // Restore
                    Button {
                        isRestoring = true
                        Task {
                            await purchaseManager.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.goPrimary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Unlock Destinations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func purchaseCard(emoji: String, title: String, description: String, productId: String, countryId: String?) -> some View {
        let isUnlocked = countryId.map { purchaseManager.isCountryUnlocked($0) } ?? (purchaseManager.unlockedCountries.count >= 11)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(emoji)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.goSuccess)
                        .font(.title2)
                } else {
                    Text(purchaseManager.formattedPrice(for: productId))
                        .font(.headline)
                        .foregroundColor(.goPrimary)
                }
            }

            if !isUnlocked {
                Button {
                    if let product = purchaseManager.products.first(where: { $0.id == productId }) {
                        Task { try? await purchaseManager.purchase(product) }
                    }
                } label: {
                    Text("Purchase")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.goPrimary)
            }
        }
        .goCard()
    }
}
