import SwiftUI

/// Country-specific paywall preview ("show, don't hide"). Replaces the old behavior
/// where tapping a locked country opened the generic PaywallView shop. The preview
/// shows the actual depth of what's behind the lock — visa paths count, documents,
/// processing time, income range — pulled live from CountryMetricsService. The visa
/// names are blurred so the user can see *there is content* without giving it away.
///
/// v1.1 scope: header + metric tile grid + blurred visa list + blurred Decision Tree
/// city silhouettes + Cost Calc one-row teaser + CTAs.
struct LockedCountryPreviewView: View {
    let countryId: String
    let countryName: String
    let countryFlag: String

    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showFullPaywall = false

    private var metrics: CountryMetrics {
        CountryMetricsService.compute(for: countryId)
    }

    private var visas: [VisaInfo] {
        VisaCatalog.byCountry(countryId)
    }

    private var previewCities: [CountryMetricsService.PreviewCity] {
        CountryMetricsService.previewCities(for: countryId)
    }

    private var costTeaser: (city: String, studioEUR: Int)? {
        CountryMetricsService.costTeaser(for: countryId)
    }

    private var individualProductId: String? {
        switch countryId {
        case "portugal": return PurchaseManager.productPortugal
        case "mexico": return PurchaseManager.productMexico
        case "ireland": return PurchaseManager.productIreland
        case "italy": return PurchaseManager.productItaly
        case "germany": return PurchaseManager.productGermany
        case "poland": return PurchaseManager.productPoland
        case "argentina": return PurchaseManager.productArgentina
        case "hungary": return PurchaseManager.productHungary
        case "uk_ancestry": return PurchaseManager.productUkAncestry
        default: return nil  // Spain + Canada are always free
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    metricGrid
                    visaListPreview
                    decisionTreePreview
                    costTeaserPreview
                    ctaStack
                    restoreButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showFullPaywall) {
                PaywallView()
            }
            .onAppear {
                Analytics.log(.paywallViewed, country: countryId, extra: ["source": "locked_country_preview"])
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            Text(countryFlag)
                .font(.system(size: 56))
            VStack(alignment: .leading, spacing: 4) {
                Text("Your \(countryName) Move Plan")
                    .font(.title2.bold())
                Label("Locked", systemImage: "lock.fill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
    }

    private var metricGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            metricTile(value: "\(metrics.visaPathsCount)", label: "Visa paths")
            metricTile(value: "\(metrics.documentsCount)", label: "Required documents")
            if let income = CountryMetricsService.incomeRangeTeaser(metrics) {
                metricTile(value: income, label: "Income required")
            } else {
                metricTile(value: "—", label: "Income (varies)")
            }
            if let time = CountryMetricsService.processingTeaser(metrics) {
                metricTile(value: time, label: "Processing time")
            } else {
                metricTile(value: "—", label: "Processing time")
            }
            if metrics.wizardTracksCount > 0 {
                metricTile(value: "\(metrics.wizardTracksCount)", label: "Step-by-step wizard\(metrics.wizardTracksCount == 1 ? "" : "s")")
            }
            if metrics.citiesCovered > 0 {
                metricTile(value: "\(metrics.citiesCovered)", label: "Cities covered")
            }
        }
    }

    private func metricTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(.goPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .goCard()
    }

    private var visaListPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visa Tracks in this Plan")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(visas) { visa in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.goPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(visa.shortName)
                                .font(.subheadline.bold())
                            Text(visa.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .goCard()
            .blur(radius: 4)
            .overlay(
                Label("Unlock to view full guides", systemImage: "lock.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            )
        }
    }

    @ViewBuilder
    private var decisionTreePreview: some View {
        if !previewCities.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where you'd live")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                VStack(spacing: 6) {
                    ForEach(Array(previewCities.enumerated()), id: \.offset) { index, city in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.subheadline.bold())
                                .foregroundColor(.goPrimary)
                                .frame(width: 28, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name)
                                    .font(.subheadline.bold())
                                Text(city.region)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("·· pts")
                                .font(.subheadline.bold())
                                .foregroundColor(.goPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .goCard()
                .blur(radius: 4)
                .overlay(
                    Label("Decision Tree ranks these for your profile", systemImage: "list.clipboard.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                )
            }
        }
    }

    @ViewBuilder
    private var costTeaserPreview: some View {
        if let teaser = costTeaser {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample monthly cost")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.goPrimary)
                        Text("Studio in \(teaser.city)")
                            .font(.subheadline)
                        Spacer()
                        Text("≈ €\(teaser.studioEUR.formatted())/mo")
                            .font(.subheadline.bold())
                            .foregroundColor(.goPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        teaserPlaceholderRow(icon: "fork.knife", label: "Groceries")
                        teaserPlaceholderRow(icon: "tram.fill", label: "Transport")
                        teaserPlaceholderRow(icon: "cross.fill", label: "Healthcare")
                    }
                    .blur(radius: 4)
                    .overlay(
                        Label("Full breakdown with city dropdown unlocks here", systemImage: "lock.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .goCard()
            }
        }
    }

    private func teaserPlaceholderRow(icon: String, label: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.goPrimary)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("€···/mo")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
        }
    }

    private var ctaStack: some View {
        VStack(spacing: 10) {
            if let productId = individualProductId {
                Button {
                    if let product = purchaseManager.products.first(where: { $0.id == productId }) {
                        Task { try? await purchaseManager.purchase(product) }
                    } else {
                        // Products not loaded yet — surface the full shop as fallback.
                        showFullPaywall = true
                    }
                } label: {
                    HStack {
                        Text("Unlock \(countryName)")
                        Spacer()
                        Text(purchaseManager.formattedPrice(for: productId))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.goPrimary)
            }

            Button {
                showFullPaywall = true
            } label: {
                Label("Or see All-Access (bundle savings)", systemImage: "globe.americas.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.goPrimary)
        }
    }

    private var restoreButton: some View {
        Button("Already purchased? Restore") {
            Task { await purchaseManager.restorePurchases() }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
    }
}
