import SwiftUI

struct DecisionTreeView: View {
    @EnvironmentObject var countrySelection: CountrySelection
    @StateObject private var vm = DecisionViewModel()
    @State private var showCostCalculator = false
    @State private var showResults = false

    var body: some View {
        Group {
            if vm.showResults {
                resultsView
            } else {
                singlePageView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.profile.countryId = countrySelection.current }
        .onChange(of: countrySelection.current) { _, newId in
            vm.profile.countryId = newId
        }
        .sheet(isPresented: $showCostCalculator) {
            NavigationStack {
                CostCalculatorView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showCostCalculator = false }
                        }
                    }
            }
        }
    }

    // MARK: - Single-Page Filter Layout (matches Android)

    private var singlePageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title — teal, matches Android
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Decision Tree: Best Places")
                            .font(.title2.bold())
                            .foregroundColor(.goPrimary)
                        Text("in \(countryName)")
                            .font(.title2.bold())
                            .foregroundColor(.goPrimary)
                    }
                    Spacer()
                    Button {
                        vm.calculateResults()
                    } label: {
                        Image(systemName: "list.clipboard.fill")
                            .font(.title2)
                            .foregroundColor(.goPrimary)
                    }
                }

                // Household
                sectionHeader("Household")
                FlowLayout(spacing: 8) {
                    ForEach(Household.allCases) { h in
                        FilterChip(title: shortLabel(h.rawValue), isSelected: vm.profile.household == h.rawValue) {
                            vm.profile.household = h.rawValue
                        }
                    }
                }

                // Personal Considerations (multi-select)
                sectionHeader("Personal Considerations")
                Text("Select any that apply — affects safety, healthcare & rights scoring.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(PersonalConsideration.allCases) { c in
                        FilterChip(
                            title: c.rawValue,
                            isSelected: vm.profile.considerations.contains(c.rawValue)
                        ) {
                            if vm.profile.considerations.contains(c.rawValue) {
                                vm.profile.considerations.remove(c.rawValue)
                            } else {
                                vm.profile.considerations.insert(c.rawValue)
                            }
                        }
                    }
                }

                // Budget
                sectionHeader("Budget")
                FlowLayout(spacing: 8) {
                    ForEach(Budget.allCases) { b in
                        FilterChip(title: shortBudget(b.rawValue), isSelected: vm.profile.budget == b.rawValue) {
                            vm.profile.budget = b.rawValue
                        }
                    }
                }

                // Preferred Climate
                sectionHeader("Preferred Climate")
                FlowLayout(spacing: 8) {
                    ForEach(ClimatePref.allCases) { c in
                        FilterChip(title: c.rawValue, isSelected: vm.profile.climate == c.rawValue) {
                            vm.profile.climate = c.rawValue
                        }
                    }
                }

                // Toggles
                VStack(spacing: 12) {
                    Toggle("Prefer Coastal Living", isOn: $vm.profile.preferCoastal)
                        .tint(.goPrimary)
                    Toggle("Prefer Big Cities", isOn: $vm.profile.preferBigCity)
                        .tint(.goPrimary)
                    Toggle("Safety is Critical", isOn: $vm.profile.safetyCritical)
                        .tint(.goPrimary)
                }

                // Language
                sectionHeader("Language Comfort")
                FlowLayout(spacing: 8) {
                    ForEach(LanguageComfort.allCases) { l in
                        FilterChip(title: l.rawValue, isSelected: vm.profile.language == l.rawValue) {
                            vm.profile.language = l.rawValue
                        }
                    }
                }

                // Business Focus
                sectionHeader("Business Focus")
                FlowLayout(spacing: 8) {
                    ForEach(BusinessFocus.allCases) { b in
                        FilterChip(title: b.rawValue, isSelected: vm.profile.businessFocus == b.rawValue) {
                            vm.profile.businessFocus = b.rawValue
                        }
                    }
                }

                // See Results button
                Button {
                    vm.calculateResults()
                } label: {
                    Text("See Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.goPrimary)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Your Top Destinations")
                    .font(.title2.bold())
                    .padding(.top)

                ForEach(Array(vm.results.prefix(10).enumerated()), id: \.element.id) { index, ranked in
                    resultCard(ranked: ranked, rank: index + 1)
                }

                Button {
                    showCostCalculator = true
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Compare Costs")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.goPrimary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Button("Start Over") {
                    vm.reset()
                }
                .buttonStyle(.bordered)
                .tint(.goPrimary)
                .padding(.top, 4)
            }
            .padding()
        }
    }

    private func resultCard(ranked: RankedDestination, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)
                VStack(alignment: .leading) {
                    Text(ranked.destination.name)
                        .font(.headline)
                    Text(ranked.destination.region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(ranked.score)) pts")
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
            }

            if !ranked.reasons.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(ranked.reasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.goPrimary.opacity(0.1))
                            .foregroundColor(.goPrimary)
                            .cornerRadius(8)
                    }
                }
            }

            let tips = MicroAdvice.tips(for: ranked.destination.id, countryId: vm.profile.countryId)
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tips.prefix(2), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundColor(.goWarning)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                NavigationLink {
                    CityMapView(cityId: ranked.destination.id, countryId: vm.profile.countryId)
                } label: {
                    Label("View Map", systemImage: "map")
                        .font(.caption)
                }

                Button("Add starter tasks") {
                    Task { await vm.addStarterTasks(for: ranked) }
                }
                .font(.caption)
                .foregroundColor(.goPrimary)
            }
        }
        .goCard()
    }

    // MARK: - Helpers

    private var countryName: String {
        DestinationConfig.getDestination(vm.profile.countryId)?.name ?? "Spain"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func shortLabel(_ raw: String) -> String {
        switch raw {
        case "Family with Kids": return "FamilyKids"
        case "Single": return "Singles"
        case "Single Parent": return "SingleParent"
        default: return raw
        }
    }

    private func shortBudget(_ raw: String) -> String {
        switch raw {
        case "Budget-Friendly": return "Low"
        case "Mid-Range": return "Medium"
        case "Premium": return "High"
        default: return raw
        }
    }
}

// MARK: - Selection Button

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.goPrimary)
                }
            }
            .padding()
            .background(isSelected ? Color.goPrimary.opacity(0.1) : Color.secondary.opacity(0.05))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.goPrimary : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
