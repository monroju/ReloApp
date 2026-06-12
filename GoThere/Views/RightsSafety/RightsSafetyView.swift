import SwiftUI

/// "Rights & Safety" — promotes the inclusivity/safety data (country_safety_profiles.json)
/// from the wizard-gated "For You" section to a top-level, always-accessible comparison.
/// A right-now US driver: weight destinations on the protections that matter to you.
/// Selections persist to UserConsiderationsStore so the Resources "For You" section
/// and DecisionTree results stay in sync.
struct RightsSafetyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<PersonalConsideration>

    init() {
        let stored = UserConsiderationsStore.load().considerations
        _selected = State(initialValue: stored.isEmpty ? [.lgbtq] : stored)
    }

    private var destinations: [DestinationCountry] { DestinationConfig.allDestinations }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                considerationPicker
                if selected.isEmpty {
                    Text("Pick at least one consideration to compare destinations.")
                        .font(.footnote).foregroundColor(.secondary)
                } else {
                    ForEach(orderedSelected, id: \.self) { consideration in
                        considerationSection(consideration)
                    }
                }
                careContinuityCTA
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Rights & Safety")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onDisappear { persist() }
    }

    private var orderedSelected: [PersonalConsideration] {
        let order: [PersonalConsideration] = [.lgbtq, .trans, .disabled, .veteran, .pregnant, .neurodivergent, .senior]
        return order.filter { selected.contains($0) }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight your move on what matters")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Compare destinations on the protections most relevant to you and your family — not just cost and visas.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var considerationPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This applies to me / my family")
                .font(.caption.bold()).foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PersonalConsideration.allCases) { c in
                        let isOn = selected.contains(c)
                        Button {
                            if isOn { selected.remove(c) } else { selected.insert(c) }
                        } label: {
                            Text(c.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(isOn ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
                                .foregroundColor(isOn ? .goPrimary : .primary)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(isOn ? Color.goPrimary : .clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func considerationSection(_ c: PersonalConsideration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(c.rawValue).font(.subheadline.bold()).foregroundColor(.goPrimary)
            ForEach(destinations) { dest in
                if let note = CountrySafetyProfiles.profile(for: dest.id)?
                    .note(for: c, householdIsSingleParent: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(dest.flagEmoji) \(dest.name)")
                            .font(.caption.bold()).foregroundColor(.primary)
                        Text(note).font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.goPrimary.opacity(0.05))
        .cornerRadius(12)
    }

    private func persist() {
        let (_, isSingleParent) = UserConsiderationsStore.load()
        let household = isSingleParent ? Household.singleParent.rawValue : ""
        UserConsiderationsStore.save(Set(selected.map { $0.rawValue }), household: household)
    }

    private var careContinuityCTA: some View {
        NavigationLink {
            CareContinuityView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundColor(.goPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your meds & care abroad")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("ADHD meds, HRT, insulin — what's available and what you can carry in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var disclaimer: some View {
        Text("Sourced from ILGA-Europe, EU directives, OECD, and SSA data. Informational only — laws change; verify current protections before deciding.")
            .font(.caption2).foregroundColor(.secondary)
    }
}
