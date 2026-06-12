import SwiftUI

/// "Continuity of Care" — per-country medication & treatment availability
/// (care_continuity_profiles.json). Answers the question nobody checks until it's
/// a crisis: can I refill my ADHD meds / HRT / insulin there, and what am I allowed
/// to carry through the border?
/// Section order adapts to the user's stored PersonalConsiderations (trans → HRT first,
/// neurodivergent → ADHD first).
struct CareContinuityView: View {
    @State private var countryId: String

    init(countryId: String = "spain") {
        _countryId = State(initialValue: countryId)
    }

    private var destinations: [DestinationCountry] { DestinationConfig.allDestinations }

    private struct Section: Identifiable {
        let id: String
        let title: String
        let icon: String
        let note: String
    }

    private var sections: [Section] {
        guard let profile = CareContinuityProfiles.profile(for: countryId) else { return [] }
        var out: [Section] = []
        if let adhd = profile.adhd {
            out.append(Section(id: "adhd", title: "ADHD medication", icon: "brain.head.profile", note: adhd))
        }
        if let hrt = profile.hrt {
            out.append(Section(id: "hrt", title: "Hormone therapy (HRT)", icon: "cross.case", note: hrt))
        }
        if let insulin = profile.insulin {
            out.append(Section(id: "insulin", title: "Insulin & diabetes care", icon: "syringe", note: insulin))
        }
        if let bringIn = profile.bring_in {
            out.append(Section(id: "bring_in", title: "What you can carry in", icon: "airplane", note: bringIn))
        }
        // Persona-aware ordering: surface the section the user most likely came for.
        let considerations = UserConsiderationsStore.load().considerations
        if considerations.contains(.trans) {
            out.sort { a, _ in a.id == "hrt" }
        } else if considerations.contains(.neurodivergent) {
            out.sort { a, _ in a.id == "adhd" }
        }
        return out
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                countryPicker
                if sections.isEmpty {
                    Text("No continuity data for this country yet.")
                        .font(.footnote).foregroundColor(.secondary)
                } else {
                    ForEach(sections) { section in
                        sectionCard(section)
                    }
                }
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Meds & Care Abroad")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Will your treatment travel with you?")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Availability of your meds, who can prescribe them, and what you're allowed to bring through the border.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Destination")
                .font(.caption.bold()).foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(destinations) { dest in
                        let isOn = countryId == dest.id
                        Button {
                            countryId = dest.id
                        } label: {
                            Text("\(dest.flagEmoji) \(dest.name)")
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

    private func sectionCard(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .foregroundColor(.goPrimary)
                Text(section.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
            }
            Text(section.note)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.goPrimary.opacity(0.05))
        .cornerRadius(12)
    }

    private var disclaimer: some View {
        Text("Sourced from INCB country regulations, national medicine agencies, and the CDC Yellow Book. Informational only — always confirm with the destination's customs authority and a clinician before travelling with medication.")
            .font(.caption2).foregroundColor(.secondary)
    }
}
