import SwiftUI

/// Money & Insurance — a country-aware directory of visa-compliant health
/// insurance and expat banking. Leads with the destination's actual visa
/// insurance requirement (from HealthcareCostData) so the recommendations are
/// contextual, not generic. Links are affiliate-ready (see MoneyInsuranceProviders).
struct MoneyInsuranceView: View {
    let initialCountryId: String?

    @Environment(\.dismiss) private var dismiss
    @State private var countryId: String

    init(initialCountryId: String? = nil) {
        self.initialCountryId = initialCountryId
        let fallback = HealthcareCostData.profiles.first?.countryId ?? "spain"
        _countryId = State(initialValue: initialCountryId ?? fallback)
    }

    private var region: String? { DestinationConfig.getDestination(countryId)?.region }
    private var insuranceNote: String? { HealthcareCostData.profile(for: countryId)?.note }
    private var countryName: String { DestinationConfig.getDestination(countryId)?.name ?? "your destination" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                countryPicker

                requirementBanner

                section(title: "Health insurance",
                        subtitle: "Cover accepted for visas, plus options for nomads and shorter stays.",
                        providers: MoneyInsuranceProviders.insurance(forRegion: region))

                section(title: "Banking",
                        subtitle: "Open a multi-currency account before you land, then a local one once you're settled.",
                        providers: MoneyInsuranceProviders.banking(forRegion: region))

                disclaimer
            }
            .padding()
        }
        .navigationTitle("Money & Insurance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Get set up abroad")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("The insurance and banking you'll need for \(countryName) — starting with what your visa actually requires.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var countryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HealthcareCostData.profiles, id: \.countryId) { p in
                    Button {
                        countryId = p.countryId
                    } label: {
                        Text("\(p.flag) \(p.name)")
                            .font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(countryId == p.countryId ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
                            .foregroundColor(countryId == p.countryId ? .goPrimary : .primary)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(countryId == p.countryId ? Color.goPrimary : .clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var requirementBanner: some View {
        if let note = insuranceNote, !note.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.goPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your \(countryName) visa insurance requirement")
                        .font(.caption.bold())
                        .foregroundColor(.goPrimary)
                    Text(note)
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.goPrimary.opacity(0.08))
            .cornerRadius(12)
        }
    }

    private func section(title: String, subtitle: String, providers: [MoneyProvider]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            ForEach(providers) { providerCard($0) }
        }
        .padding(.top, 4)
    }

    private func providerCard(_ p: MoneyProvider) -> some View {
        Link(destination: URL(string: p.url) ?? URL(string: "https://getgothere.app")!) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(p.blurb)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(p.bestFor)
                        .font(.caption2.bold())
                        .foregroundColor(.goPrimary)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.goPrimary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var disclaimer: some View {
        Text("This is an informational directory, not financial advice or an endorsement. Coverage rules differ by visa — always confirm a policy meets your specific visa's requirements before you buy, and check fees and terms with each provider.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
}
