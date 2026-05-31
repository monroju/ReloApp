import SwiftUI

/// Healthcare cost comparison vs the US — middle-class pain point made concrete.
/// Shows the destination's public system + typical private premiums next to a US anchor.
struct HealthcareCompareView: View {
    let initialCountryId: String?

    @Environment(\.dismiss) private var dismiss
    @State private var countryId: String

    init(initialCountryId: String? = nil) {
        self.initialCountryId = initialCountryId
        let fallback = HealthcareCostData.profiles.first?.countryId ?? "spain"
        _countryId = State(initialValue: initialCountryId ?? fallback)
    }

    private var profile: HealthcareProfile? { HealthcareCostData.profile(for: countryId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                countryPicker
                if let p = profile {
                    comparisonCard(p)
                    publicCard(p)
                    Text(p.note)
                        .font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                }
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Healthcare Costs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What healthcare really costs")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Typical private premiums vs the US — plus what the public system covers once you're a resident.")
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

    private func comparisonCard(_ p: HealthcareProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Private insurance — monthly")
                .font(.caption.bold()).foregroundColor(.secondary)

            compareRow("\(p.flag) Single", p.privateMonthlySingleUSD,
                       "🇺🇸 US marketplace", HealthcareCostData.usSingleMarketplaceMonthlyUSD)
            Divider()
            compareRow("\(p.flag) Family of 4", p.privateMonthlyFamilyUSD,
                       "🇺🇸 US family (total)", HealthcareCostData.usFamilyMonthlyTotalUSD)

            if let savings = familySavings(p) {
                Text("≈ $\(savings.formatted())/yr less than a US family plan")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func compareRow(_ destLabel: String, _ destUSD: Int, _ usLabel: String, _ usUSD: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(destLabel).font(.subheadline).foregroundColor(.primary)
                Text("$\(destUSD.formatted())/mo").font(.title3.bold()).foregroundColor(.goPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(usLabel).font(.caption).foregroundColor(.secondary)
                Text("$\(usUSD.formatted())/mo").font(.subheadline).foregroundColor(.secondary)
            }
        }
    }

    private func publicCard(_ p: HealthcareProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🏥 Public system").font(.subheadline.bold()).foregroundColor(.goPrimary)
            Text(p.publicSystem).font(.footnote).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(10)
    }

    private func familySavings(_ p: HealthcareProfile) -> Int? {
        let diff = (HealthcareCostData.usFamilyMonthlyTotalUSD - p.privateMonthlyFamilyUSD) * 12
        return diff > 0 ? diff : nil
    }

    private var disclaimer: some View {
        Text("Estimates only — premiums vary by age, health, and plan. US figures from 2024 KFF/marketplace averages. Not insurance advice.")
            .font(.caption2).foregroundColor(.secondary)
    }
}
