import SwiftUI

/// Investment-migration view — upper-tier "Plan B / second passport via capital".
/// Surfaces in-catalog golden/investor visas + Caribbean CBI programs, with an
/// honest ended-programs callout and an advisor handoff.
struct InvestmentMigrationView: View {
    let onStartWizard: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    init(onStartWizard: @escaping (String) -> Void = { _ in }) {
        self.onStartWizard = onStartWizard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro

                Text("🏛️ Residency by investment (EU & LatAm)")
                    .font(.subheadline.bold()).foregroundColor(.secondary)
                ForEach(InvestmentMigration.residencyByInvestment) { visa in
                    residencyCard(visa)
                }

                Text("🛂 Citizenship by investment (second passport)")
                    .font(.subheadline.bold()).foregroundColor(.secondary)
                    .padding(.top, 4)

                // The $0 version: claim a passport you may already be entitled to.
                NavigationLink {
                    AncestryCheckerView()
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.goPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Have EU or Latin heritage? Claim it for ~$0")
                                .font(.footnote.bold()).foregroundColor(.primary)
                            Text("Citizenship by descent is the free version of a second passport — check your eligibility first.")
                                .font(.caption).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.goPrimary.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                ForEach(InvestmentMigration.cbiPrograms) { p in
                    cbiCard(p)
                }

                endedCallout

                Text(InvestmentMigration.disclaimer)
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Investment Routes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Buy your optionality")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Residency and second-passport routes via investment — for diversification, mobility, and a real Plan B.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func residencyCard(_ v: VisaInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(v.countryFlag) \(v.name)").font(.subheadline.bold()).foregroundColor(.primary)
                Spacer()
            }
            Text(v.income).font(.caption).foregroundColor(.goPrimary)
            Text("Citizenship: \(v.pathToCitizenship) · Processing: \(v.processingTime)")
                .font(.caption2).foregroundColor(.secondary)
            if let url = URL(string: v.officialUrl) {
                Link("Official program ↗", destination: url)
                    .font(.caption.bold()).foregroundColor(.goPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func cbiCard(_ p: InvestmentMigration.CBIProgram) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(p.flag) \(p.country)").font(.subheadline.bold()).foregroundColor(.primary)
                Spacer()
                Text("from $\(p.minInvestmentUSD.formatted())")
                    .font(.caption.bold()).foregroundColor(.goPrimary)
            }
            Text(p.route).font(.caption).foregroundColor(.secondary)
            Text("⏱ \(p.timelineMonths) · \(p.perks)")
                .font(.caption2).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = URL(string: p.officialUrl) {
                Link("Official program ↗", destination: url)
                    .font(.caption.bold()).foregroundColor(.goPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var endedCallout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📉 Recently ended / changed").font(.caption.bold()).foregroundColor(.orange)
            ForEach(InvestmentMigration.endedPrograms, id: \.self) { line in
                Text(line).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(10)
    }
}
