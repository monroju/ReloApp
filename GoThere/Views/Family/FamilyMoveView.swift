import SwiftUI

/// "Moving with kids" guide — middle-class family core. Answers the schooling /
/// healthcare / child-visa questions parents actually lose sleep over. Driven by
/// FamilyMoveData; opened per-country from Resources.
struct FamilyMoveView: View {
    let initialCountryId: String?

    @Environment(\.dismiss) private var dismiss
    @State private var countryId: String

    init(initialCountryId: String? = nil) {
        self.initialCountryId = initialCountryId
        let fallback = FamilyMoveData.profiles.first?.countryId ?? "spain"
        _countryId = State(initialValue: initialCountryId ?? fallback)
    }

    private var profile: FamilyMoveProfile? { FamilyMoveData.profile(for: countryId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                countryPicker
                if let p = profile {
                    section("🎒 Public schooling", p.publicSchooling)
                    section("🏫 International schools", p.internationalSchooling)
                    section("🏠 Homeschooling", p.homeschooling)
                    section("🩺 Children's healthcare", p.childHealthcare)
                    section("🛂 Kids on your visa", p.childVisaNote)
                    tipsCard("👪 \(p.name) parent tips", p.tips)
                }
                tipsCard("✅ Before you leave the US (any country)", FamilyMoveData.universalTips)
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Moving with Kids")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Moving abroad with children")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Schooling, healthcare, and visa status for your kids — the questions every relocating parent asks first.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var countryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FamilyMoveData.profiles, id: \.countryId) { p in
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

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.bold()).foregroundColor(.primary)
            Text(body).font(.footnote).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private func tipsCard(_ title: String, _ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold()).foregroundColor(.goPrimary)
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundColor(.goPrimary)
                    Text(tip).font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(10)
    }

    private var disclaimer: some View {
        Text("Informational only — school fees and rules change. Confirm with each school and consulate. Not legal advice.")
            .font(.caption2).foregroundColor(.secondary)
    }
}
