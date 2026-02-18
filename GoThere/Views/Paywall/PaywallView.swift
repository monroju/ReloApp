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

                        Text("Spain is free! Unlock Portugal, Mexico, or all countries for full access to visa guides, tasks, and resources.")
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
        let isUnlocked = countryId.map { purchaseManager.isCountryUnlocked($0) } ?? (purchaseManager.unlockedCountries.count >= 3)

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
