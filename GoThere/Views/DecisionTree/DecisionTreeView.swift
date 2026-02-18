import SwiftUI

struct DecisionTreeView: View {
    @StateObject private var vm = DecisionViewModel()
    @State private var showCostCalculator = false

    var body: some View {
        Group {
            if vm.showResults {
                resultsView
            } else {
                questionnaireView
            }
        }
        .navigationTitle("Find Your City")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Questionnaire

    private var questionnaireView: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(vm.currentStep + 1), total: Double(vm.totalSteps))
                .tint(.goPrimary)
                .padding()

            Text("Step \(vm.currentStep + 1) of \(vm.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 24) {
                    stepContent
                }
                .padding()
            }

            // Navigation
            HStack {
                if vm.currentStep > 0 {
                    Button("Back") { vm.previousStep() }
                        .buttonStyle(.bordered)
                        .tint(.goPrimary)
                }
                Spacer()
                Button(vm.currentStep == vm.totalSteps - 1 ? "See Results" : "Next") {
                    vm.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(.goPrimary)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case 0:
            questionCard(title: "Which country?") {
                ForEach(DestinationConfig.allDestinations) { dest in
                    SelectionButton(
                        title: "\(dest.flagEmoji) \(dest.name)",
                        isSelected: vm.profile.countryId == dest.id
                    ) { vm.profile.countryId = dest.id }
                }
            }
        case 1:
            questionCard(title: "Who's moving?") {
                // Filter chips style
                FlowLayout(spacing: 8) {
                    ForEach(Household.allCases) { h in
                        FilterChip(title: h.rawValue, isSelected: vm.profile.household == h.rawValue) {
                            vm.profile.household = h.rawValue
                        }
                    }
                }
            }
        case 2:
            questionCard(title: "What's your budget?") {
                FlowLayout(spacing: 8) {
                    ForEach(Budget.allCases) { b in
                        FilterChip(title: b.rawValue, isSelected: vm.profile.budget == b.rawValue) {
                            vm.profile.budget = b.rawValue
                        }
                    }
                }
            }
        case 3:
            questionCard(title: "Preferred climate?") {
                FlowLayout(spacing: 8) {
                    ForEach(ClimatePref.allCases) { c in
                        FilterChip(title: c.rawValue, isSelected: vm.profile.climate == c.rawValue) {
                            vm.profile.climate = c.rawValue
                        }
                    }
                }
            }
        case 4:
            questionCard(title: "Location preferences") {
                VStack(spacing: 12) {
                    Toggle("Prefer coastal areas", isOn: $vm.profile.preferCoastal)
                        .tint(.goPrimary)
                    Toggle("Prefer big cities", isOn: $vm.profile.preferBigCity)
                        .tint(.goPrimary)
                    Toggle("Safety is critical", isOn: $vm.profile.safetyCritical)
                        .tint(.goPrimary)
                }
            }
        case 5:
            questionCard(title: "Language comfort?") {
                ForEach(LanguageComfort.allCases) { l in
                    SelectionButton(title: l.rawValue, isSelected: vm.profile.language == l.rawValue) {
                        vm.profile.language = l.rawValue
                    }
                }
            }
        case 6:
            questionCard(title: "Business focus?") {
                FlowLayout(spacing: 8) {
                    ForEach(BusinessFocus.allCases) { b in
                        FilterChip(title: b.rawValue, isSelected: vm.profile.businessFocus == b.rawValue) {
                            vm.profile.businessFocus = b.rawValue
                        }
                    }
                }
            }
        case 7:
            questionCard(title: "Nightlife importance?") {
                ForEach(NightlifePref.allCases) { n in
                    SelectionButton(title: n.rawValue, isSelected: vm.profile.nightlife == n.rawValue) {
                        vm.profile.nightlife = n.rawValue
                    }
                }
            }
        case 8:
            questionCard(title: "Expat community size?") {
                ForEach(DensityPref.allCases) { d in
                    SelectionButton(title: d.rawValue, isSelected: vm.profile.density == d.rawValue) {
                        vm.profile.density = d.rawValue
                    }
                }
            }
        default:
            EmptyView()
        }
    }

    private func questionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
            content()
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

                // Cost Calculator button
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

            // Micro advice
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

            Button("Add starter tasks") {
                Task { await vm.addStarterTasks(for: ranked) }
            }
            .font(.caption)
            .foregroundColor(.goPrimary)
        }
        .goCard()
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
