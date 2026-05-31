import SwiftUI

struct VisaCompareView: View {
    let initialCountryId: String?  // pre-filter to current country if non-nil
    let onStartWizard: (String) -> Void  // callback when user taps Start Wizard

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCountryFilter: String? = nil  // nil = all countries
    @State private var selectedCategoryFilter: VisaCategory? = nil
    @State private var selectedVisaIds: Set<String> = []
    @State private var maxMonthlyIncomeUSD: Double = 10000  // 10k = "any income"
    @State private var sortMode: SortMode = .default
    @State private var noDegreeOnly: Bool = false
    @State private var independentIncomeOnly: Bool = false
    private let maxSelection = 3

    /// Ordering for the visa list. `.lowestIncome` is the lower-class "what can I
    /// actually afford" win — it floats the cheapest income-bar tracks to the top.
    /// Visas with no structured income test (ancestry/work/points-based) sink to the
    /// bottom of the affordability sort because they can't be ranked on income.
    enum SortMode: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case lowestIncome = "Lowest income"
        var id: String { rawValue }
    }

    private static let eurToUsd = 1.08
    private static let incomeSliderMin: Double = 500
    private static let incomeSliderMax: Double = 10000
    private var incomeFilterActive: Bool { maxMonthlyIncomeUSD < Self.incomeSliderMax }

    init(initialCountryId: String? = nil, onStartWizard: @escaping (String) -> Void = { _ in }) {
        self.initialCountryId = initialCountryId
        self.onStartWizard = onStartWizard
        _selectedCountryFilter = State(initialValue: initialCountryId)
    }

    private var filteredVisas: [VisaInfo] {
        let filtered = VisaCatalog.all.filter { v in
            (selectedCountryFilter == nil || v.countryId == selectedCountryFilter)
            && (selectedCategoryFilter == nil || v.category == selectedCategoryFilter)
            && passesIncomeFilter(v)
            && (!noDegreeOnly || v.requiresNoDegree)
            && (!independentIncomeOnly || v.acceptsIndependentIncome)
        }
        switch sortMode {
        case .default:
            return filtered
        case .lowestIncome:
            // Cheapest income bar first; no-income-test visas (nil) sort last.
            return filtered.sorted {
                ($0.monthlyIncomeEUR ?? Int.max, $0.countryName) < ($1.monthlyIncomeEUR ?? Int.max, $1.countryName)
            }
        }
    }

    /// Income filter rule:
    ///   - Slider at max → no filter.
    ///   - Otherwise: keep visas with `monthlyIncomeEUR == nil` (ancestry/work/points-based — no income test)
    ///     OR converted USD threshold ≤ slider value.
    private func passesIncomeFilter(_ v: VisaInfo) -> Bool {
        guard incomeFilterActive else { return true }
        guard let eur = v.monthlyIncomeEUR else { return true }
        let usd = Double(eur) * Self.eurToUsd
        return usd <= maxMonthlyIncomeUSD
    }

    private var selectedVisas: [VisaInfo] {
        selectedVisaIds.compactMap { VisaCatalog.byId($0) }
            .sorted { $0.countryName < $1.countryName }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filterSection
                    listSection
                }
                .padding()
            }
            if selectedVisas.count >= 2 {
                compareBar
            }
        }
        .navigationTitle("Visa Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            ReviewPromptService.recordAndMaybeRequest(.visaCompareViewed)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Compare Visa Types")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Select 2-3 visas to see eligibility, cost, and citizenship paths side-by-side.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Country")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(title: "All", isSelected: selectedCountryFilter == nil) {
                        selectedCountryFilter = nil
                    }
                    ForEach(DestinationConfig.allDestinations) { dest in
                        chipButton(
                            title: "\(dest.flagEmoji) \(dest.name)",
                            isSelected: selectedCountryFilter == dest.id
                        ) {
                            selectedCountryFilter = (selectedCountryFilter == dest.id) ? nil : dest.id
                        }
                    }
                }
            }

            Text("Category")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.top, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(title: "All", isSelected: selectedCategoryFilter == nil) {
                        selectedCategoryFilter = nil
                    }
                    ForEach(VisaCategory.allCases) { cat in
                        chipButton(
                            title: cat.rawValue,
                            icon: cat.icon,
                            isSelected: selectedCategoryFilter == cat
                        ) {
                            selectedCategoryFilter = (selectedCategoryFilter == cat) ? nil : cat
                        }
                    }
                }
            }

            incomeFilter
                .padding(.top, 8)

            accessToggles
                .padding(.top, 4)

            sortControl
                .padding(.top, 4)
        }
    }

    /// Lower-income unlock filters: surface paths that don't need a degree and that
    /// accept freelance/self/savings income instead of an employer-sponsored salary.
    private var accessToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            chipButton(title: "No degree needed", icon: "graduationcap.circle",
                       isSelected: noDegreeOnly) { noDegreeOnly.toggle() }
            chipButton(title: "Freelance / self income OK", icon: "person.crop.circle.badge.checkmark",
                       isSelected: independentIncomeOnly) { independentIncomeOnly.toggle() }
        }
    }

    private var sortControl: some View {
        HStack(spacing: 8) {
            Text("Sort")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Picker("Sort", selection: $sortMode) {
                ForEach(SortMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var incomeFilter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Max monthly income required")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text(incomeFilterActive
                     ? "≤ $\(Int(maxMonthlyIncomeUSD))/mo"
                     : "Any")
                    .font(.caption.bold())
                    .foregroundColor(.goPrimary)
            }
            Slider(
                value: $maxMonthlyIncomeUSD,
                in: Self.incomeSliderMin...Self.incomeSliderMax,
                step: 100
            )
            .tint(.goPrimary)
            Text("Visas with no income test (ancestry, work, points-based) always show.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(10)
    }

    private func chipButton(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon).font(.caption2)
                }
                Text(title).font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .goPrimary : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.goPrimary : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - List of visa entries

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(filteredVisas.count) visa types")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                if !selectedVisaIds.isEmpty {
                    Button("Clear (\(selectedVisaIds.count))") {
                        selectedVisaIds.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.goPrimary)
                }
            }

            ForEach(filteredVisas) { visa in
                visaRow(visa)
            }
        }
    }

    private func visaRow(_ visa: VisaInfo) -> some View {
        let isSelected = selectedVisaIds.contains(visa.id)
        let atLimit = selectedVisaIds.count >= maxSelection && !isSelected

        return Button {
            toggleSelection(visa.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(visa.countryFlag)
                            .font(.title3)
                        Text(visa.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    }
                    Text("\(visa.shortName) · \(visa.category.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(visa.income)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.goPrimary : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.goPrimary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color.goPrimary.opacity(0.05) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.goPrimary.opacity(0.5) : .clear, lineWidth: 1)
            )
            .opacity(atLimit ? 0.4 : 1.0)
        }
        .disabled(atLimit)
        .buttonStyle(.plain)
    }

    private func toggleSelection(_ id: String) {
        if selectedVisaIds.contains(id) {
            selectedVisaIds.remove(id)
        } else if selectedVisaIds.count < maxSelection {
            selectedVisaIds.insert(id)
        }
    }

    // MARK: - Compare bar (bottom)

    private var compareBar: some View {
        VStack(spacing: 0) {
            Divider()
            NavigationLink {
                ComparisonTableView(visas: selectedVisas, onStartWizard: onStartWizard)
            } label: {
                HStack {
                    Image(systemName: "rectangle.split.3x1")
                    Text("Compare \(selectedVisas.count) Visas")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.goPrimary)
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Comparison Table

struct ComparisonTableView: View {
    let visas: [VisaInfo]
    let onStartWizard: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let labelColumnWidth: CGFloat = 130
    private let dataColumnWidth: CGFloat = 200

    // Rows in the comparison table — order matters (most-asked-first).
    private let rows: [(String, KeyPath<VisaInfo, String>)] = [
        ("Income / Funds", \.income),
        ("Processing time", \.processingTime),
        ("Duration", \.duration),
        ("Work allowed?", \.workAllowed),
        ("Path to PR", \.pathToPR),
        ("Path to citizenship", \.pathToCitizenship),
        ("Cost estimate", \.costEstimate),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row: visa names
                        HStack(alignment: .top, spacing: 0) {
                            cell(width: labelColumnWidth, isHeader: true) {
                                Text("Feature")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                            ForEach(visas) { v in
                                cell(width: dataColumnWidth, isHeader: true) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(v.countryFlag) \(v.shortName)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.goPrimary)
                                        Text(v.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))

                        // Feature rows
                        ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                            HStack(alignment: .top, spacing: 0) {
                                cell(width: labelColumnWidth, isHeader: false) {
                                    Text(row.0)
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                }
                                ForEach(visas) { v in
                                    cell(width: dataColumnWidth, isHeader: false) {
                                        Text(v[keyPath: row.1])
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .background(idx % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }

                // Pros/Cons per visa
                ForEach(visas) { v in
                    prosConsCard(v)
                }

                // Tax-optimization overlay — surfaces preferential regimes (Beckham,
                // IFICI, etc.) for visas that carry them. Upper-tier value; ends in an
                // advisor handoff because tax posture is decided by the authority, not us.
                let taxableVisas = visas.filter { !$0.taxRegimes.isEmpty }
                if !taxableVisas.isEmpty {
                    ForEach(taxableVisas) { v in
                        taxRegimeCard(v)
                    }
                    Text("Preferential tax regimes are time-sensitive and conditional — election windows are short. Confirm eligibility with a cross-border tax advisor before relying on a rate.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Action buttons
                VStack(spacing: 10) {
                    ForEach(visas) { v in
                        actionButton(for: v)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Side-by-Side")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cell<Content: View>(width: CGFloat, isHeader: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(width: width, alignment: .leading)
            .overlay(
                Rectangle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
    }

    private func prosConsCard(_ v: VisaInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(v.countryFlag) \(v.shortName)")
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
                Spacer()
            }
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Pros", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    ForEach(v.pros, id: \.self) { p in
                        Text("• \(p)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Cons", systemImage: "xmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    ForEach(v.cons, id: \.self) { c in
                        Text("• \(c)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func taxRegimeCard(_ v: VisaInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "percent")
                    .foregroundColor(.goPrimary)
                Text("\(v.countryFlag) \(v.shortName) — tax regimes")
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
            }
            ForEach(Array(v.taxRegimes.enumerated()), id: \.offset) { _, regime in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(regime.name).font(.footnote.bold()).foregroundColor(.primary)
                        Spacer()
                        if let rate = regime.flatRatePercent {
                            Text("\(Int(rate * 100))% flat")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color.goPrimary)
                                .cornerRadius(6)
                        }
                    }
                    ForEach(regime.eligibilityCriteria, id: \.self) { c in
                        Text("• \(c)").font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let window = regime.applicationWindow {
                        Text("⏱ \(window)").font(.caption2).foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(12)
    }

    private func actionButton(for v: VisaInfo) -> some View {
        Group {
            if let trackId = v.wizardTrackId {
                Button {
                    onStartWizard(trackId)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "list.clipboard.fill")
                        Text("Start Wizard — \(v.shortName)")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.goPrimary)
                    .cornerRadius(10)
                }
            } else if let url = URL(string: v.officialUrl) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Open Official — \(v.shortName)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.goPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.goPrimary.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.goPrimary.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }
}
