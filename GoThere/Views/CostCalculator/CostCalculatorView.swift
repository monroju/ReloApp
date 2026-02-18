import SwiftUI

struct CostCalculatorView: View {
    @State private var selectedCountry = DestinationConfig.spain
    @State private var selectedCities: Set<String> = []
    @State private var showFamily = false
    @State private var housingType: HousingType = .oneBed

    enum HousingType: String, CaseIterable {
        case oneBed = "1-Bed Apartment"
        case threeBed = "3-Bed Apartment"
    }

    private var availableCities: [CityCostData] {
        CostDatabase.cities(for: selectedCountry)
    }

    private var comparedCities: [CityCostData] {
        CostDatabase.all.filter { selectedCities.contains($0.cityId) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Country picker
                Picker("Country", selection: $selectedCountry) {
                    ForEach(DestinationConfig.allDestinations) { dest in
                        Text("\(dest.flagEmoji) \(dest.name)").tag(dest.id)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedCountry) { _ in
                    selectedCities.removeAll()
                }

                // Housing type picker
                Picker("Housing", selection: $housingType) {
                    ForEach(HousingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Lifestyle toggles
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Include family costs", isOn: $showFamily)
                        .tint(.goPrimary)
                }
                .padding(.horizontal)

                // City selection chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select cities to compare")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableCities) { city in
                                FilterChip(
                                    title: city.cityName,
                                    isSelected: selectedCities.contains(city.cityId)
                                ) {
                                    if selectedCities.contains(city.cityId) {
                                        selectedCities.remove(city.cityId)
                                    } else {
                                        selectedCities.insert(city.cityId)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Comparison cards
                if comparedCities.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.largeTitle)
                            .foregroundColor(.goPrimary.opacity(0.5))
                        Text("Select cities above to compare costs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(comparedCities) { city in
                        costCard(city)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Cost Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func costCard(_ city: CityCostData) -> some View {
        let useFamily = housingType == .threeBed || showFamily
        let rent = useFamily ? city.rent3Bed : city.rent1Bed
        let total = rent + city.groceries + city.dining + city.transport + city.utilities + city.internet + city.healthcare

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(city.cityName)
                    .font(.headline)
                Spacer()
                Text("$\(total)/mo")
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)
            }

            VStack(spacing: 6) {
                costRow("Rent", rent, pct: Double(rent) / Double(total))
                costRow("Groceries", city.groceries, pct: Double(city.groceries) / Double(total))
                costRow("Dining Out", city.dining, pct: Double(city.dining) / Double(total))
                costRow("Transport", city.transport, pct: Double(city.transport) / Double(total))
                costRow("Utilities", city.utilities, pct: Double(city.utilities) / Double(total))
                costRow("Internet", city.internet, pct: Double(city.internet) / Double(total))
                costRow("Healthcare", city.healthcare, pct: Double(city.healthcare) / Double(total))
            }
        }
        .goCard()
        .padding(.horizontal)
    }

    private func costRow(_ label: String, _ amount: Int, pct: Double) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(amount)")
                    .font(.caption.bold())
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.goPrimary.opacity(0.3))
                    .frame(width: geo.size.width * min(pct, 1.0))
            }
            .frame(height: 4)
        }
    }
}
