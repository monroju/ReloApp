import SwiftUI

/// "Can I actually afford to move?" calculator. Targets the lower/middle-class user
/// who assumes relocation is out of reach. Shows a realistic, itemised landing budget
/// — flights, fees, legal, deposit + first months — with a ±20% ballpark band.
struct MoveCostCalculatorView: View {
    /// Optional pre-selected country (e.g. opened from a destination detail).
    let initialCountryId: String?

    @Environment(\.dismiss) private var dismiss

    @State private var countryId: String
    @State private var adults: Int = 1
    @State private var children: Int = 0
    @State private var lifestyle: MoveLifestyle = .moderate
    @State private var monthsRunway: Int = 3

    init(initialCountryId: String? = nil) {
        self.initialCountryId = initialCountryId
        let fallback = MoveCostData.profiles.first?.countryId ?? "spain"
        _countryId = State(initialValue: initialCountryId ?? fallback)
    }

    private var profile: MoveCostProfile? { MoveCostData.profile(for: countryId) }

    private var estimate: MoveCostEstimate? {
        guard let profile else { return nil }
        return MoveCostEstimate.compute(
            profile: profile, adults: adults, children: children,
            lifestyle: lifestyle, monthsRunway: monthsRunway
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                countryPicker
                householdControls
                lifestylePicker
                runwayStepper
                if let estimate, let profile {
                    resultCard(estimate, profile)
                }
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Cost to Move")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What it really costs to land")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("A realistic one-time budget to get there and stay afloat your first few months. Most people overestimate this wildly.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Destination").font(.caption.bold()).foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoveCostData.profiles, id: \.countryId) { p in
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
    }

    private var householdControls: some View {
        HStack(spacing: 12) {
            stepper(label: "Adults", value: $adults, range: 1...6)
            stepper(label: "Children", value: $children, range: 0...8)
        }
    }

    private func stepper(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.bold()).foregroundColor(.secondary)
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)").font(.headline).foregroundColor(.goPrimary)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }

    private var lifestylePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Lifestyle").font(.caption.bold()).foregroundColor(.secondary)
            Picker("Lifestyle", selection: $lifestyle) {
                ForEach(MoveLifestyle.allCases) { l in Text(l.rawValue).tag(l) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var runwayStepper: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Cash runway").font(.caption.bold()).foregroundColor(.secondary)
                Spacer()
                Text("\(monthsRunway) month\(monthsRunway == 1 ? "" : "s")")
                    .font(.caption.bold()).foregroundColor(.goPrimary)
            }
            Stepper(value: $monthsRunway, in: 1...12) {
                Text("Months to budget before income stabilises").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(10)
    }

    private func resultCard(_ e: MoveCostEstimate, _ p: MoveCostProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated landing budget").font(.caption).foregroundColor(.secondary)
                Text("$\(e.total.formatted())").font(.largeTitle.bold()).foregroundColor(.goPrimary)
                Text("Ballpark range: $\(e.lowBand.formatted()) – $\(e.highBand.formatted())")
                    .font(.caption).foregroundColor(.secondary)
            }
            Divider()
            lineItem("✈️ Flights (\(adults + children) ppl)", e.flights)
            lineItem("📄 Government fees", e.govtFees)
            lineItem("⚖️ Legal / gestor", e.legal)
            lineItem("🏠 Deposit + first month", e.upfrontRent)
            if e.firstMonthsLiving > 0 {
                lineItem("🍽️ Living runway (\(max(0, monthsRunway - 1)) mo)", e.firstMonthsLiving)
            }
            lineItem("📦 Setup & shipping", e.setup)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func lineItem(_ label: String, _ amount: Int) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Text("$\(amount.formatted())").font(.subheadline.weight(.medium)).foregroundColor(.secondary)
        }
    }

    private var disclaimer: some View {
        Text("Estimates only — actual costs vary by city, season, and visa track. Figures refreshed for 2025-2026. Not financial advice.")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}
