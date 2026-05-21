import SwiftUI

struct CostCalculatorView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var countrySelection: CountrySelection

    @State private var selectedCountry: String = DestinationConfig.spain
    @State private var selectedCityId: String = "madrid"
    @State private var showInUSD = false
    @State private var housingType = 1 // 0=Studio, 1=1BR, 2=2BR
    @State private var mealsOutPerWeek: Double = 4
    @State private var publicTransport = true
    @State private var privateHealthInsurance = true
    @State private var gymMembership = false
    /// Wave 1 (T1c-finish) — dependents count feeds the affordability math
    /// via `VisaInfo.requiredMonthlyEUR(dependents:)`.
    @State private var dependents: Int = 0

    private var availableCities: [CityCostData] {
        CostDatabase.cities(for: selectedCountry)
    }

    private var selectedCity: CityCostData? {
        availableCities.first { $0.cityId == selectedCityId }
    }

    // EUR/USD approximate rate
    private var currencySymbol: String { showInUSD ? "$" : "€" }
    private var rate: Double { showInUSD ? 1.0 : 0.92 }

    private func formatted(_ amount: Int) -> String {
        let converted = Int(Double(amount) * rate)
        return "\(converted.formatted()) \(currencySymbol)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cost Calculator")
                            .font(.title2.bold())
                            .foregroundColor(.goPrimary)
                        Text("Estimate your monthly expenses")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // City picker — dropdown style
                VStack(alignment: .leading, spacing: 6) {
                    Text("City")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(DestinationConfig.allDestinations) { dest in
                            Section(dest.name) {
                                ForEach(CostDatabase.cities(for: dest.id)) { city in
                                    Button {
                                        selectedCountry = dest.id
                                        selectedCityId = city.cityId
                                    } label: {
                                        HStack {
                                            Text(city.cityName)
                                            if city.cityId == selectedCityId {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.goPrimary)
                            Text(selectedCity?.cityName ?? "Select city")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                // Show in USD toggle
                HStack {
                    Text("Show in USD")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $showInUSD)
                        .tint(.goPrimary)
                        .labelsHidden()
                }

                Divider()

                // Customize Your Lifestyle
                Text("Customize Your Lifestyle")
                    .font(.headline)

                // Housing Type — 3-option picker (matches Android: Studio/1BR/2BR)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Housing Type")
                        .font(.subheadline)
                    Picker("Housing", selection: $housingType) {
                        Text("Studio").tag(0)
                        Text("1 BR").tag(1)
                        Text("2 BR").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                // Meals out per week
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.secondary)
                    Text("Meals out per week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(mealsOutPerWeek))")
                        .font(.subheadline.bold())
                }
                Slider(value: $mealsOutPerWeek, in: 0...14, step: 1)
                    .tint(.goPrimary)

                // Lifestyle toggles
                VStack(spacing: 12) {
                    lifestyleToggle(icon: "bus.fill", label: "Public Transport", isOn: $publicTransport)
                    lifestyleToggle(icon: "heart.text.square.fill", label: "Private Health Insurance", isOn: $privateHealthInsurance)
                    lifestyleToggle(icon: "figure.strengthtraining.traditional", label: "Gym Membership", isOn: $gymMembership)
                }

                // Wave 1 (T1c-finish) — dependents affects the income threshold
                // shown in the affordable-visas section, not the cost breakdown
                // (lifestyle costs already scale via housing/groceries sliders).
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.goPrimary)
                        .frame(width: 24)
                    Text("Dependents (for visa threshold)")
                        .font(.subheadline)
                    Spacer()
                    Stepper(value: $dependents, in: 0...8) {
                        Text("\(dependents)")
                            .font(.subheadline.weight(.semibold))
                            .frame(minWidth: 18)
                    }
                    .labelsHidden()
                }

                Divider()

                // Monthly Cost Breakdown
                if let city = selectedCity {
                    monthlyCostBreakdown(city)
                    Divider()
                    affordableVisasSection(for: city)
                }
            }
            .padding()
        }
        .navigationTitle("Cost Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default to the global country selection on first open so the picker
            // matches the top-bar flag.
            selectedCountry = countrySelection.current
            if let first = availableCities.first {
                selectedCityId = first.cityId
            }
        }
        .onChange(of: selectedCountry) { _ in
            if let first = availableCities.first {
                selectedCityId = first.cityId
            }
        }
    }

    private func lifestyleToggle(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.goPrimary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.goPrimary)
                .labelsHidden()
        }
    }

    private func monthlyCostBreakdown(_ city: CityCostData) -> some View {
        let rent: Int = {
            switch housingType {
            case 0: return Int(Double(city.rent1Bed) * 0.75) // Studio ~75% of 1BR
            case 2: return city.rent3Bed
            default: return city.rent1Bed
            }
        }()
        let utilities = city.utilities
        let groceries = city.groceries
        let diningCost = Int(Double(city.dining) * (mealsOutPerWeek / 4.0))
        let transportCost = publicTransport ? city.transport : 0
        let healthCost = privateHealthInsurance ? city.healthcare : 0
        let gymCost = gymMembership ? 40 : 0
        let internet = city.internet
        let total = rent + utilities + groceries + diningCost + transportCost + healthCost + gymCost + internet

        return VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Cost Breakdown")
                .font(.headline)

            costRow(icon: "house.fill", label: "Rent", amount: rent)
            costRow(icon: "bolt.fill", label: "Utilities", amount: utilities)
            costRow(icon: "cart.fill", label: "Groceries", amount: groceries)
            costRow(icon: "fork.knife", label: "Dining Out", amount: diningCost)
            if publicTransport {
                costRow(icon: "bus.fill", label: "Transport", amount: transportCost)
            }
            if privateHealthInsurance {
                costRow(icon: "heart.text.square.fill", label: "Health Insurance", amount: healthCost)
            }
            if gymMembership {
                costRow(icon: "figure.strengthtraining.traditional", label: "Gym", amount: gymCost)
            }
            costRow(icon: "wifi", label: "Internet", amount: internet)

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(formatted(total))
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)
            }
        }
    }

    private func costRow(icon: String, label: String, amount: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(formatted(amount))
                .font(.subheadline)
        }
    }

    // MARK: - Affordable visas section (Item 7)

    /// USD-denominated monthly total. CostData ships in USD; we normalize to EUR at compare time
    /// since VisaInfo.monthlyIncomeEUR is the canonical comparison unit.
    private func totalMonthlyUSD(for city: CityCostData) -> Int {
        let rent: Int = {
            switch housingType {
            case 0: return Int(Double(city.rent1Bed) * 0.75)
            case 2: return city.rent3Bed
            default: return city.rent1Bed
            }
        }()
        let diningCost = Int(Double(city.dining) * (mealsOutPerWeek / 4.0))
        let transportCost = publicTransport ? city.transport : 0
        let healthCost = privateHealthInsurance ? city.healthcare : 0
        let gymCost = gymMembership ? 40 : 0
        return rent + city.utilities + city.groceries + diningCost + transportCost + healthCost + gymCost + city.internet
    }

    /// Match the same USD→EUR rate used elsewhere in the catalog (2026 approximate).
    private static let usdToEUR: Double = 0.92

    private func affordableVisasSection(for city: CityCostData) -> some View {
        let totalEUR = Int(Double(totalMonthlyUSD(for: city)) * Self.usdToEUR)
        let visas = VisaCatalog.byCountry(city.countryId).filter { $0.monthlyIncomeEUR != nil }
        // Wave 1 (T1c-finish) — bucket against the dependent-adjusted threshold
        // so a family of three sees the actual bar, not the single-applicant one.
        let comfortable = visas.filter { visa in
            let bar = visa.requiredMonthlyEUR(dependents: dependents) ?? visa.monthlyIncomeEUR!
            return totalEUR <= Int(Double(bar) * 0.75)
        }
        let tight = visas.filter { visa in
            let bar = visa.requiredMonthlyEUR(dependents: dependents) ?? visa.monthlyIncomeEUR!
            return totalEUR > Int(Double(bar) * 0.75) && totalEUR <= bar
        }
        let below = visas.filter { visa in
            let bar = visa.requiredMonthlyEUR(dependents: dependents) ?? visa.monthlyIncomeEUR!
            return totalEUR > bar
        }
        let pointsBased = VisaCatalog.byCountry(city.countryId).count - visas.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("Visas you could afford on €\(totalEUR.formatted())/mo")
                .font(.headline)

            if !comfortable.isEmpty {
                affordabilityGroup(
                    icon: "checkmark.circle.fill",
                    iconColor: .goSuccess,
                    label: "Comfortable fit",
                    visas: comfortable,
                    totalEUR: totalEUR
                )
            }
            if !tight.isEmpty {
                affordabilityGroup(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    label: "Tight — within 25% of threshold",
                    visas: tight,
                    totalEUR: totalEUR
                )
            }
            if !below.isEmpty {
                affordabilityGroup(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    label: "Below threshold",
                    visas: below,
                    totalEUR: totalEUR
                )
            }
            if visas.isEmpty {
                Text("No income-based visas for this country in the catalog — the available visas here use points / employer / ancestry criteria.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if pointsBased > 0 {
                Text("+ \(pointsBased) other visa\(pointsBased == 1 ? "" : "s") in this country uses non-income criteria (points / employer / ancestry).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func affordabilityGroup(icon: String, iconColor: Color, label: String, visas: [VisaInfo], totalEUR: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
            }
            ForEach(visas, id: \.id) { visa in
                NavigationLink {
                    visaDestination(for: visa)
                } label: {
                    visaRow(visa, totalEUR: totalEUR)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func visaRow(_ visa: VisaInfo, totalEUR: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(visa.countryFlag)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(visa.name) (\(visa.shortName))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if visa.wizardTrackId != nil {
                        Text("Wizard")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.goPrimary.opacity(0.15))
                            .foregroundColor(.goPrimary)
                            .cornerRadius(4)
                    }
                }
                if visa.monthlyIncomeEUR != nil {
                    let bar = visa.requiredMonthlyEUR(dependents: dependents) ?? visa.monthlyIncomeEUR!
                    let gap = bar - totalEUR
                    let dependentSuffix = dependents > 0 ? " (you + \(dependents))" : ""
                    if gap > 0 {
                        Text("requires €\(bar.formatted())/mo\(dependentSuffix) · short €\(gap.formatted())/mo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("requires €\(bar.formatted())/mo\(dependentSuffix)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(.leading, 8)
        .contentShape(Rectangle())
    }

    /// Mirrors DecisionTreeView.visaDestination — wizard if a track is wired,
    /// otherwise the full Compare table for that country.
    @ViewBuilder
    private func visaDestination(for visa: VisaInfo) -> some View {
        if let trackId = visa.wizardTrackId {
            VisaWizardView(countryId: visa.countryId, initialTrackId: trackId)
        } else {
            VisaCompareView(initialCountryId: visa.countryId)
        }
    }
}
