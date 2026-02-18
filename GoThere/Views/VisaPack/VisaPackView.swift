import SwiftUI

struct VisaPackView: View {
    @State private var selectedCountry = DestinationConfig.spain

    private var categories: [(String, [VisaPackItem])] {
        let items = visaPackItems(for: selectedCountry)
        let grouped = Dictionary(grouping: items) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Country", selection: $selectedCountry) {
                    ForEach(DestinationConfig.allDestinations) { dest in
                        Text("\(dest.flagEmoji) \(dest.name)").tag(dest.id)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ForEach(categories, id: \.0) { category, items in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.headline)

                        ForEach(items) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .foregroundColor(.goPrimary)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let url = item.url {
                                    Link(destination: URL(string: url)!) {
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(.goPrimary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .goCard()
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Visa Packs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data

struct VisaPackItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let icon: String
    var url: String?
}

private func visaPackItems(for countryId: String) -> [VisaPackItem] {
    switch countryId {
    case "spain":
        return [
            VisaPackItem(title: "Criminal Background Check (FBI)", description: "Required for all visa types", category: "Government Documents", icon: "shield.checkered"),
            VisaPackItem(title: "Apostille", description: "For all US-issued documents", category: "Government Documents", icon: "stamp"),
            VisaPackItem(title: "Health Insurance Certificate", description: "Must cover Spain, no co-pays", category: "Insurance", icon: "heart.text.square"),
            VisaPackItem(title: "Bank Statements (12 months)", description: "Proof of financial solvency", category: "Financial", icon: "banknote"),
            VisaPackItem(title: "Passive Income Proof", description: "NLV: pension, dividends, rental income", category: "Financial", icon: "chart.line.uptrend.xyaxis"),
            VisaPackItem(title: "Remote Work Contract", description: "DNV: employment with non-Spanish company", category: "Employment", icon: "doc.text.fill"),
            VisaPackItem(title: "Passport Photos (white background)", description: "Recent, specific dimensions", category: "Identity", icon: "person.crop.rectangle"),
            VisaPackItem(title: "EX-01 Application Form", description: "Completed and signed", category: "Application Forms", icon: "doc.plaintext"),
        ]
    case "portugal":
        return [
            VisaPackItem(title: "Criminal Background Check (FBI)", description: "With apostille", category: "Government Documents", icon: "shield.checkered"),
            VisaPackItem(title: "Proof of Accommodation", description: "Rental contract or property deed", category: "Housing", icon: "house"),
            VisaPackItem(title: "Health Insurance (SEF-compliant)", description: "Valid in Portugal, full coverage", category: "Insurance", icon: "heart.text.square"),
            VisaPackItem(title: "NIF (Tax Number)", description: "Portuguese tax identification", category: "Tax", icon: "number"),
            VisaPackItem(title: "Bank Statements", description: "Proof of income/savings", category: "Financial", icon: "banknote"),
            VisaPackItem(title: "D7/D8 Application Form", description: "From Portuguese consulate", category: "Application Forms", icon: "doc.plaintext"),
            VisaPackItem(title: "Passport Photos", description: "Recent, biometric format", category: "Identity", icon: "person.crop.rectangle"),
        ]
    case "mexico":
        return [
            VisaPackItem(title: "Bank Statements (6 months)", description: "Min balance or monthly income", category: "Financial", icon: "banknote"),
            VisaPackItem(title: "Employment Letter", description: "If applying as remote worker", category: "Employment", icon: "doc.text.fill"),
            VisaPackItem(title: "Passport (6+ months validity)", description: "Required for all visa types", category: "Identity", icon: "person.crop.rectangle"),
            VisaPackItem(title: "Consulate Application Form", description: "Complete online or in-person", category: "Application Forms", icon: "doc.plaintext"),
            VisaPackItem(title: "Passport Photos", description: "White background, specific size", category: "Identity", icon: "person.crop.rectangle"),
            VisaPackItem(title: "INM Card Exchange", description: "Complete within 30 days of arrival", category: "Post-Arrival", icon: "creditcard"),
        ]
    default:
        return []
    }
}
