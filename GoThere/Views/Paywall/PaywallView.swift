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

                    // Products. Titles renamed Pack → Plan per teardown finding: WhereNext / Going
                    // sell named *deliverables*, not feature labels. Descriptions are now
                    // metric-led where a countryId is set — see metricDescription(for:) below.
                    // Old strings kept inline as `// was: …` comments per operator safety rule.
                    VStack(spacing: 12) {
                        purchaseCard(
                            emoji: "\u{1F1F5}\u{1F1F9}",
                            title: "Your Portugal Move Plan",  // was: "Portugal Pack"
                            description: "D7 & D8 visa guides, tasks, and resources",
                            productId: PurchaseManager.productPortugal,
                            countryId: "portugal"
                        )

                        purchaseCard(
                            emoji: "\u{1F1F2}\u{1F1FD}",
                            title: "Your Mexico Move Plan",  // was: "Mexico Pack"
                            description: "Temporary resident visa guides, tasks, and resources",
                            productId: PurchaseManager.productMexico,
                            countryId: "mexico"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EE}\u{1F1EA}",
                            title: "Your Ireland Citizenship Plan",  // was: "Ireland Pack"
                            description: "Foreign Births Register — Irish/EU citizenship by descent",
                            productId: PurchaseManager.productIreland,
                            countryId: "ireland"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EE}\u{1F1F9}",
                            title: "Your Italy Citizenship Plan",  // was: "Italy Pack"
                            description: "Jure sanguinis — Italian/EU citizenship by descent",
                            productId: PurchaseManager.productItaly,
                            countryId: "italy"
                        )

                        purchaseCard(
                            emoji: "\u{1F1E9}\u{1F1EA}",
                            title: "Your Germany Restoration Plan",  // was: "Germany Pack"
                            description: "Article 116 + StAG §15 citizenship restoration",
                            productId: PurchaseManager.productGermany,
                            countryId: "germany"
                        )

                        purchaseCard(
                            emoji: "\u{1F1F5}\u{1F1F1}",
                            title: "Your Poland Citizenship Plan",  // was: "Poland Pack"
                            description: "Confirmation of Polish citizenship by descent",
                            productId: PurchaseManager.productPoland,
                            countryId: "poland"
                        )

                        purchaseCard(
                            emoji: "\u{1F1E6}\u{1F1F7}",
                            title: "Your Argentina Move Plan",  // was: "Argentina Pack"
                            description: "Citizenship by option — for children of native Argentines",
                            productId: PurchaseManager.productArgentina,
                            countryId: "argentina"
                        )

                        purchaseCard(
                            emoji: "\u{1F1ED}\u{1F1FA}",
                            title: "Your Hungary Citizenship Plan",  // was: "Hungary Pack"
                            description: "Simplified naturalization — Hungarian descent + language",
                            productId: PurchaseManager.productHungary,
                            countryId: "hungary"
                        )

                        purchaseCard(
                            emoji: "\u{1F1EC}\u{1F1E7}",
                            title: "Your UK Ancestry Plan",  // was: "UK Ancestry Pack"
                            description: "5-year work visa for Commonwealth citizens with a UK-born grandparent",
                            productId: PurchaseManager.productUkAncestry,
                            countryId: "uk_ancestry"
                        )

                        purchaseCard(
                            emoji: "\u{1F30D}",
                            title: "Unlock Every Country — All-Access",  // was: "All Countries"
                            description: "Spain + Canada free, plus 9 more countries",  // was: "Unlock everything - best value!"
                            productId: PurchaseManager.productAllCountries,
                            countryId: nil,
                            showBundleSavings: true
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

    private func purchaseCard(emoji: String, title: String, description: String, productId: String, countryId: String?, showBundleSavings: Bool = false) -> some View {
        let isUnlocked = countryId.map { purchaseManager.isCountryUnlocked($0) } ?? (purchaseManager.unlockedCountries.count >= 11)
        // Prefer the live-computed metric teaser when a countryId is present and CountryMetrics
        // produces one. Falls back to the static description for the bundle card and as a safety net.
        let displayDescription = countryId.flatMap { metricDescription(for: $0) } ?? description

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(emoji)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(displayDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.goSuccess)
                        .font(.title2)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(purchaseManager.formattedPrice(for: productId))
                            .font(.headline)
                            .foregroundColor(.goPrimary)
                        if showBundleSavings, let anchor = bundleSavingsAnchor() {
                            Text(anchor.individualSum)
                                .font(.caption)
                                .strikethrough()
                                .foregroundColor(.secondary)
                            Text("save \(anchor.savings)")
                                .font(.caption2.bold())
                                .foregroundColor(.goSuccess)
                        }
                    }
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

    /// Builds a short "N visa paths · M documents · K cities" teaser for a country card.
    /// Returns nil when none of the metric pieces are non-zero — caller falls back to the
    /// static description argument.
    private func metricDescription(for countryId: String) -> String? {
        let m = CountryMetricsService.compute(for: countryId)
        var parts: [String] = []
        if m.wizardTracksCount > 0 {
            parts.append("\(m.wizardTracksCount) step-by-step wizard\(m.wizardTracksCount == 1 ? "" : "s")")
        } else if m.visaPathsCount > 0 {
            parts.append("\(m.visaPathsCount) visa path\(m.visaPathsCount == 1 ? "" : "s")")
        }
        if m.documentsCount > 0 {
            parts.append("\(m.documentsCount) documents")
        }
        if m.citiesCovered > 0 {
            parts.append("\(m.citiesCovered) \(m.citiesCovered == 1 ? "city" : "cities")")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private struct BundleAnchor {
        let individualSum: String
        let savings: String
    }

    /// Computes the strikethrough sum-of-individual-packs and the savings vs. the bundle.
    /// Returns nil when StoreKit hasn't loaded products yet, or when the bundle isn't actually
    /// cheaper than the individual sum — never show a misleading anchor.
    private func bundleSavingsAnchor() -> BundleAnchor? {
        let individualProducts = purchaseManager.products.filter { $0.id != PurchaseManager.productAllCountries }
        guard !individualProducts.isEmpty,
              let bundle = purchaseManager.products.first(where: { $0.id == PurchaseManager.productAllCountries })
        else { return nil }

        let individualSum = individualProducts.map(\.price).reduce(Decimal(0), +)
        guard individualSum > bundle.price else { return nil }

        let savings = individualSum - bundle.price
        return BundleAnchor(
            individualSum: bundle.priceFormatStyle.format(individualSum),
            savings: bundle.priceFormatStyle.format(savings)
        )
    }
}
