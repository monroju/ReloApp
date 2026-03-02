import SwiftUI

struct ResourcesView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = ResourcesViewModel()
    @State private var expandedCategories: Set<String> = []

    private var resourceCategories: [(String, String, [(String, String, String)])] {
        switch vm.selectedCountry {
        case "portugal":
            return [
                ("Visas & Immigration", "doc.text.fill", [
                    ("Portugal SEF/AIMA", "https://www.vistos.mne.gov.pt/", "Official visa portal"),
                    ("D7 Passive Income Visa Info", "https://www.vistos.mne.gov.pt/", "Retirement & passive income"),
                    ("D8 Digital Nomad Visa", "https://www.vistos.mne.gov.pt/", "Remote workers"),
                ]),
                ("Housing", "house.fill", [
                    ("Idealista Portugal", "https://www.idealista.pt/", "Rental & property listings"),
                ]),
                ("Banking", "building.columns.fill", [
                    ("ActivoBank", "https://www.activobank.pt/", "Free Portuguese bank account"),
                ]),
                ("Healthcare", "heart.text.square.fill", [
                    ("SNS Portal", "https://www.sns.gov.pt/", "National health service"),
                ]),
                ("Expat Communities", "person.3.fill", [
                    ("Americans in Portugal", "https://www.facebook.com/groups/americansinportugal/", "Facebook community"),
                ]),
            ]
        case "mexico":
            return [
                ("Visas & Immigration", "doc.text.fill", [
                    ("Mexico INM", "https://www.inm.gob.mx/", "National immigration institute"),
                    ("Mexican Consulate Services", "https://consulmex.sre.gob.mx/", "Consulate applications"),
                ]),
                ("Housing", "house.fill", [
                    ("Inmuebles24", "https://www.inmuebles24.com/", "Rental listings"),
                ]),
                ("Banking", "building.columns.fill", [
                    ("BBVA Mexico", "https://www.bbva.mx/", "Major bank for expats"),
                ]),
                ("Healthcare", "heart.text.square.fill", [
                    ("IMSS", "https://www.imss.gob.mx/", "Social security healthcare"),
                ]),
                ("Expat Communities", "person.3.fill", [
                    ("Expats in Mexico", "https://www.expatsinmexico.com/", "Online community"),
                ]),
            ]
        default:
            return [
                ("Visas & Immigration", "doc.text.fill", [
                    ("Spain Immigration (Exteriores)", "https://www.exteriores.gob.es/Consulados/", "Official consulate portal"),
                    ("Digital Nomad Visa Info", "https://www.exteriores.gob.es/Consulados/", "DNV requirements"),
                    ("Non-Lucrative Visa Info", "https://www.exteriores.gob.es/Consulados/", "NLV requirements"),
                ]),
                ("Housing", "house.fill", [
                    ("Idealista Spain", "https://www.idealista.com/", "Rental & property listings"),
                    ("Fotocasa", "https://www.fotocasa.es/", "Alternative property portal"),
                ]),
                ("Banking", "building.columns.fill", [
                    ("CaixaBank", "https://www.caixabank.es/", "Major Spanish bank"),
                ]),
                ("Healthcare", "heart.text.square.fill", [
                    ("Spanish Healthcare System", "https://www.sanidad.gob.es/", "Ministry of Health"),
                ]),
                ("Expat Communities", "person.3.fill", [
                    ("Expat Forum Spain", "https://www.expatforum.com/spain/", "Community forums"),
                ]),
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Country picker
                    Picker("Country", selection: $vm.selectedCountry) {
                        ForEach(DestinationConfig.allDestinations) { dest in
                            Text("\(dest.flagEmoji) \(dest.name)").tag(dest.id)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Expandable resource categories (matches Android accordion)
                    ForEach(resourceCategories, id: \.0) { category, icon, resources in
                        expandableSection(category: category, icon: icon, resources: resources)
                    }

                    // Downloadable Documents header (teal, matches Android)
                    if vm.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading documents...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    } else if !vm.items.isEmpty {
                        Text("Downloadable Documents")
                            .font(.headline)
                            .foregroundColor(.goPrimary)
                            .padding(.top, 8)

                        ForEach(vm.groupedItems, id: \.0) { category, items in
                            VStack(alignment: .leading, spacing: 0) {
                                // Category header with count badge
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.goPrimary)
                                    Text(category)
                                        .font(.subheadline.weight(.medium))
                                    // Count badge (matches Android)
                                    Text("\(items.count)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.goPrimary)
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                .padding(.vertical, 8)

                                ForEach(items) { item in
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        Text(item.name)
                                            .font(.subheadline)
                                        Spacer()
                                        if let urlStr = item.downloadUrl, let url = URL(string: urlStr) {
                                            Link(destination: url) {
                                                Text("View")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.goPrimary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)

                                    if item.id != items.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .goCard()
                        }
                    }
                }
                .padding()
            }
            .goTopBar(showThemeToggle: false)
            .onChange(of: vm.selectedCountry) { _ in
                expandedCategories.removeAll()
                Task { await vm.loadDocuments() }
            }
            .task {
                await vm.loadDocuments()
            }
        }
    }

    private func expandableSection(category: String, icon: String, resources: [(String, String, String)]) -> some View {
        VStack(spacing: 0) {
            // Header row — tappable to expand
            Button {
                withAnimation {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(.goPrimary)
                        .frame(width: 24)
                    Text(category)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: expandedCategories.contains(category) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            // Expanded content
            if expandedCategories.contains(category) {
                VStack(spacing: 0) {
                    ForEach(resources, id: \.0) { title, url, subtitle in
                        if let linkUrl = URL(string: url) {
                            Link(destination: linkUrl) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("View")
                                        .font(.caption.bold())
                                        .foregroundColor(.goPrimary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
