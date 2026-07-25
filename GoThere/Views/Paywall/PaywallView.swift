import SwiftUI

/// Paywall layout for the freemium pivot (Item 11).
///
/// Order is deliberate — subscriptions surface first because they're the
/// recommended primary model per Phase 3 monetization research; lifetime is the
/// "pay once" alternative; region bundles split the territory for users who only
/// want one continent; individual country packs sit last so legacy per-country
/// buyers still have a clear path, framed as the cheapest entry point.
///
/// Cards for new SKUs are hidden when StoreKit hasn't loaded the product yet
/// (ASC config still pending — Item 13). The view degrades cleanly back to the
/// legacy 10-card layout until then.
struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    @State private var showReferral = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    referralSection
                    subscriptionSection
                    lifetimeSection
                    regionBundlesSection
                    individualCountriesSection
                    restoreButton
                }
                .padding()
            }
            .sheet(isPresented: $showReferral) {
                ReferralView().environmentObject(purchaseManager)
            }
            .navigationTitle("Unlock Destinations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                Analytics.log(.paywallViewed, properties: [
                    "unlocked_count": purchaseManager.unlockedCountries.count,
                    "has_all_access": purchaseManager.hasAllAccess,
                    "subscription_active": purchaseManager.subscriptionStatus.isActive
                ])
            }
        }
    }

    // MARK: - Sections

    /// Cross-sell: someone hesitating at the paywall can unlock a month free by
    /// inviting a friend instead. Presents the give-a-month/get-a-month sheet.
    private var referralSection: some View {
        Button {
            showReferral = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(.goPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prefer free? Invite a friend")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("You both get a month of All-Access when they redeem your code.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .goCard()
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 60))
                .foregroundColor(.goPrimary)

            Text("Unlock More Destinations")
                .font(.title2.bold())

            Text("Spain and Canada are free. Pick the plan that fits — subscribe for everything, pay once for lifetime, grab a region bundle, or unlock a single country.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        let monthlyAvailable = hasProduct(PurchaseManager.productAllAccessMonthly)
        let annualAvailable = hasProduct(PurchaseManager.productAllAccessAnnual)

        if monthlyAvailable || annualAvailable {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    "All-Access Subscription",
                    subtitle: "Every country, every visa path, every update — all-in for one price."
                )
                if annualAvailable {
                    subscriptionCard(
                        emoji: "\u{2B50}\u{FE0F}",
                        title: "Annual All-Access",
                        description: "Best value — locked-in price, every country, every update",
                        productId: PurchaseManager.productAllAccessAnnual,
                        periodSuffix: "/yr",
                        recommended: true
                    )
                }
                if monthlyAvailable {
                    subscriptionCard(
                        emoji: "\u{1F4C5}",
                        title: "Monthly All-Access",
                        description: "Flexible month-to-month access — cancel anytime",
                        productId: PurchaseManager.productAllAccessMonthly,
                        periodSuffix: "/mo",
                        recommended: false
                    )
                }
            }
        }
    }

    private var lifetimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Lifetime All-Access — Pay Once",
                subtitle: "One purchase covers every current and future country."
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
    }

    @ViewBuilder
    private var regionBundlesSection: some View {
        let europeAvailable = hasProduct(PurchaseManager.productEuropeBundle)
        let americasAvailable = hasProduct(PurchaseManager.productAmericasBundle)

        if europeAvailable || americasAvailable {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    "Region Bundles",
                    subtitle: "Only moving within one continent? Skip the rest."
                )
                if europeAvailable {
                    bundleCard(
                        emoji: "\u{1F1EA}\u{1F1FA}",
                        title: "Europe Bundle",
                        description: "Portugal, Ireland, Italy, Germany, Poland, Hungary, UK Ancestry",
                        productId: PurchaseManager.productEuropeBundle,
                        countries: PurchaseManager.europeBundleCountries
                    )
                }
                if americasAvailable {
                    bundleCard(
                        emoji: "\u{1F30E}",
                        title: "Americas Bundle",
                        description: "Mexico + Argentina (Spain & Canada are free)",
                        productId: PurchaseManager.productAmericasBundle,
                        countries: PurchaseManager.americasBundleCountries
                    )
                }
            }
        }
    }

    private var individualCountriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Individual Countries",
                subtitle: "Or pay once for a single country — the cheapest way to start."
            )

            // Titles renamed Pack → Plan per teardown finding: WhereNext / Going sell
            // named *deliverables*, not feature labels. Descriptions are metric-led
            // where a countryId is set — see metricDescription(for:) below.
            // Old strings kept inline as `// was: …` comments per operator safety rule.
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
        }
    }

    private var restoreButton: some View {
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

    // MARK: - Card helpers

    private func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.goPrimary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Card for an auto-renewable subscription. Shows period suffix (/mo, /yr) on the price,
    /// "Recommended" badge for the annual offer, and "Currently subscribed" state when active.
    private func subscriptionCard(
        emoji: String,
        title: String,
        description: String,
        productId: String,
        periodSuffix: String,
        recommended: Bool
    ) -> some View {
        let isActive = purchaseManager.subscriptionStatus.isActive

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(emoji)
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if recommended {
                            Text("BEST VALUE")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.goPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.goSuccess)
                        .font(.title2)
                } else {
                    HStack(spacing: 2) {
                        Text(purchaseManager.formattedPrice(for: productId))
                            .font(.headline)
                            .foregroundColor(.goPrimary)
                        Text(periodSuffix)
                            .font(.caption.bold())
                            .foregroundColor(.goPrimary)
                    }
                }
            }

            if isActive {
                Text("Currently subscribed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button {
                    if let product = purchaseManager.products.first(where: { $0.id == productId }) {
                        Task { try? await purchaseManager.purchase(product) }
                    }
                } label: {
                    Text("Subscribe")
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

    /// Card for a non-consumable region bundle (Europe / Americas). Shows a checkmark
    /// when the bundle is owned OR when the user already has all-access via subscription
    /// or the lifetime SKU — never push a redundant purchase.
    private func bundleCard(
        emoji: String,
        title: String,
        description: String,
        productId: String,
        countries: [String]
    ) -> some View {
        let isOwned = purchaseManager.ownedSKUs.contains(productId) || purchaseManager.hasAllAccess

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(emoji)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.goSuccess)
                        .font(.title2)
                } else {
                    Text(purchaseManager.formattedPrice(for: productId))
                        .font(.headline)
                        .foregroundColor(.goPrimary)
                }
            }

            if !isOwned {
                Button {
                    if let product = purchaseManager.products.first(where: { $0.id == productId }) {
                        Task { try? await purchaseManager.purchase(product) }
                    }
                } label: {
                    Text("Unlock \(countries.count) countries")
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

    private func purchaseCard(emoji: String, title: String, description: String, productId: String, countryId: String?, showBundleSavings: Bool = false) -> some View {
        let isUnlocked = countryId.map { purchaseManager.isCountryUnlocked($0) } ?? purchaseManager.hasAllAccess
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

    // MARK: - Pricing helpers

    private func hasProduct(_ id: String) -> Bool {
        purchaseManager.products.contains { $0.id == id }
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
    /// Returns nil when StoreKit hasn't loaded products yet, or when the bundle isn't
    /// actually cheaper than the individual sum — never show a misleading anchor.
    /// Only sums the legacy 9 per-country packs (region bundles + subscriptions are not
    /// "individual" alternatives to the lifetime SKU).
    private func bundleSavingsAnchor() -> BundleAnchor? {
        let legacyPackIds: Set<String> = [
            PurchaseManager.productPortugal,
            PurchaseManager.productMexico,
            PurchaseManager.productIreland,
            PurchaseManager.productItaly,
            PurchaseManager.productGermany,
            PurchaseManager.productPoland,
            PurchaseManager.productArgentina,
            PurchaseManager.productHungary,
            PurchaseManager.productUkAncestry
        ]
        let individualProducts = purchaseManager.products.filter { legacyPackIds.contains($0.id) }
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
