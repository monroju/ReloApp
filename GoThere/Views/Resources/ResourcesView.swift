import SwiftUI

// MARK: - Resource Data Types

struct WebResource: Identifiable {
    let id: String
    let title: String
    let description: String
    let url: String
    let type: String // official, service, marketplace, community, emergency
}

struct WebResourceCategory: Identifiable {
    let id: String
    let title: String
    let icon: String // SF Symbol name
    let resources: [WebResource]
}

// MARK: - Resources Screen

struct ResourcesView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = ResourcesViewModel()
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with refresh
                    HStack {
                        Text("\(countryFlag) \(countryName) Resources")
                            .font(.title3.bold())
                            .foregroundColor(.goPrimary)
                        Spacer()
                        Button {
                            Task { await vm.loadDocuments() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.goPrimary)
                        }
                    }

                    // Country picker
                    Picker("Country", selection: $vm.selectedCountry) {
                        ForEach(DestinationConfig.allDestinations) { dest in
                            Text("\(dest.flagEmoji) \(dest.name)").tag(dest.id)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Quick Links header
                    Text("Quick Links")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    // Expandable resource categories (matches Android ResourceCategoryCard)
                    ForEach(resourceCategories) { category in
                        resourceCategoryCard(category)
                    }

                    // Downloadable Documents section
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    } else if !vm.items.isEmpty {
                        Divider().padding(.vertical, 8)

                        Text("Downloadable Documents")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        ForEach(vm.groupedItems, id: \.0) { category, items in
                            storageDocumentsCard(title: category, items: items)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.largeTitle)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No downloadable documents yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Check back later for PDF guides and forms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
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

    // MARK: - Resource Category Card (matches Android ElevatedCard)

    private func resourceCategoryCard(_ category: WebResourceCategory) -> some View {
        let isExpanded = expandedCategories.contains(category.id)

        return VStack(spacing: 0) {
            // Header — tappable
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedCategories.remove(category.id)
                    } else {
                        expandedCategories.insert(category.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .foregroundColor(.goPrimary)
                        .frame(width: 24)
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }

            // Expanded resources
            if isExpanded {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 4) {
                    ForEach(category.resources) { resource in
                        Link(destination: URL(string: resource.url) ?? URL(string: "https://example.com")!) {
                            HStack(spacing: 12) {
                                Image(systemName: iconForType(resource.type))
                                    .foregroundColor(colorForType(resource.type))
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    if !resource.description.isEmpty {
                                        Text(resource.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.goPrimary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Storage Documents Card (matches Android StorageDocumentsCard)

    private func storageDocumentsCard(title: String, items: [ResourceItem]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.goPrimary)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                // Count badge
                Text("\(items.count)")
                    .font(.caption2.bold())
                    .foregroundColor(.goPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.goPrimaryContainer)
                    .cornerRadius(4)
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 4) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .foregroundColor(.goError)
                            .frame(width: 24)
                        Text(cleanDocName(item.name))
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer()
                        if let urlStr = item.downloadUrl, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                Text("View")
                                    .font(.caption.bold())
                                    .foregroundColor(.goPrimary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Helpers

    private var countryName: String {
        DestinationConfig.getDestination(vm.selectedCountry)?.name ?? "Spain"
    }

    private var countryFlag: String {
        DestinationConfig.getDestination(vm.selectedCountry)?.flagEmoji ?? "\u{1F1EA}\u{1F1F8}"
    }

    private func cleanDocName(_ name: String) -> String {
        name.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "official": return "checkmark.shield"
        case "service": return "building.2"
        case "marketplace": return "storefront"
        case "community": return "bubble.left.and.bubble.right"
        case "emergency": return "exclamationmark.triangle"
        default: return "link"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "official": return .goPrimary
        case "service": return Color(hex: 0x2E8BC0) // tertiary blue
        case "marketplace": return .goPrimaryDark
        case "community": return .secondary
        case "emergency": return .goError
        default: return .primary
        }
    }

    // MARK: - Country Resources (matches Android getResourcesForCountry)

    private var resourceCategories: [WebResourceCategory] {
        switch vm.selectedCountry {
        case "portugal": return portugalResources
        case "mexico": return mexicoResources
        default: return spainResources
        }
    }

    private var spainResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "visas", title: "Visas & Immigration", icon: "person.text.rectangle", resources: [
                WebResource(id: "spain-consulate", title: "Spanish Consulates in USA", description: "Find your assigned consulate", url: "https://www.exteriores.gob.es/en/EmbajadasConsulados/Paginas/index.aspx", type: "official"),
                WebResource(id: "spain-nie", title: "NIE/TIE Application Guide", description: "Foreigner identification numbers", url: "https://www.inclusion.gob.es/web/migraciones/w/extranjeria", type: "official"),
                WebResource(id: "spain-nomad", title: "Digital Nomad Visa", description: "Remote worker visa requirements", url: "https://www.exteriores.gob.es", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "idealista", title: "Idealista", description: "Spain's largest property portal", url: "https://www.idealista.com", type: "marketplace"),
                WebResource(id: "fotocasa", title: "Fotocasa", description: "Popular real estate website", url: "https://www.fotocasa.es", type: "marketplace"),
                WebResource(id: "spotahome", title: "Spotahome", description: "Medium-term rentals with virtual tours", url: "https://www.spotahome.com", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "n26", title: "N26 Bank", description: "Digital bank, easy online setup", url: "https://n26.com/en-es", type: "service"),
                WebResource(id: "bbva", title: "BBVA", description: "Major Spanish bank", url: "https://www.bbva.es", type: "service"),
                WebResource(id: "wise", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "seg-social", title: "Spanish Social Security", description: "Public healthcare registration", url: "https://www.seg-social.es", type: "official"),
                WebResource(id: "sanitas", title: "Sanitas", description: "Popular private insurance", url: "https://www.sanitas.es", type: "service"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations", title: "InterNations Spain", description: "Expat network with events", url: "https://www.internations.org/spain-expats", type: "community"),
                WebResource(id: "expat-forum", title: "Spain Expat Forum", description: "Discussion forum", url: "https://www.expatforum.com/forums/spain-expat-forum.22/", type: "community"),
            ]),
        ]
    }

    private var portugalResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "visas", title: "Visas & Immigration", icon: "person.text.rectangle", resources: [
                WebResource(id: "aima", title: "AIMA (Immigration Agency)", description: "Portuguese immigration portal", url: "https://www.aima.gov.pt", type: "official"),
                WebResource(id: "d7", title: "D7 Passive Income Visa", description: "Visa for retirees and passive income", url: "https://vistos.mne.gov.pt/en/national-visas/general-information/type-of-visa", type: "official"),
                WebResource(id: "d8", title: "D8 Digital Nomad Visa", description: "Remote worker visa", url: "https://www.aima.gov.pt", type: "official"),
                WebResource(id: "golden", title: "Golden Visa Program", description: "Residency by investment", url: "https://www.sef.pt/en/pages/conteudo-detalhe.aspx?nID=21", type: "official"),
            ]),
            WebResourceCategory(id: "nif", title: "NIF & Tax Registration", icon: "person.text.rectangle", resources: [
                WebResource(id: "nif", title: "Portal das Finanças", description: "Get your NIF tax number", url: "https://www.portaldasfinancas.gov.pt", type: "official"),
                WebResource(id: "bordr", title: "Bordr (NIF Service)", description: "Get NIF remotely", url: "https://bordr.io", type: "service"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "idealista-pt", title: "Idealista Portugal", description: "Largest property portal", url: "https://www.idealista.pt", type: "marketplace"),
                WebResource(id: "imovirtual", title: "Imovirtual", description: "Popular real estate site", url: "https://www.imovirtual.com", type: "marketplace"),
                WebResource(id: "casa-sapo", title: "Casa Sapo", description: "Portuguese listings", url: "https://casa.sapo.pt", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "activobank", title: "ActivoBank", description: "No-fee digital bank", url: "https://www.activobank.pt", type: "service"),
                WebResource(id: "millennium", title: "Millennium BCP", description: "Largest private bank", url: "https://www.millenniumbcp.pt", type: "service"),
                WebResource(id: "wise", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
                WebResource(id: "revolut", title: "Revolut", description: "Digital banking app", url: "https://www.revolut.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "sns", title: "SNS (National Health Service)", description: "Public healthcare", url: "https://www.sns.gov.pt", type: "official"),
                WebResource(id: "medis", title: "Médis", description: "Private health insurance", url: "https://www.medis.pt", type: "service"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "americans-pt", title: "Americans & FriendsPT", description: "Facebook community", url: "https://www.facebook.com/groups/AmericansAndFriendsPT", type: "community"),
                WebResource(id: "internations-pt", title: "InterNations Portugal", description: "Expat network", url: "https://www.internations.org/portugal-expats", type: "community"),
                WebResource(id: "reddit-pt", title: "r/PortugalExpats", description: "Reddit community", url: "https://www.reddit.com/r/PortugalExpats/", type: "community"),
            ]),
            WebResourceCategory(id: "utilities", title: "Utilities & Services", icon: "bolt", resources: [
                WebResource(id: "edp", title: "EDP (Electricity)", description: "Main electricity provider", url: "https://www.edp.pt", type: "service"),
                WebResource(id: "meo", title: "MEO", description: "Phone, internet, TV", url: "https://www.meo.pt", type: "service"),
                WebResource(id: "nos", title: "NOS", description: "Mobile and home services", url: "https://www.nos.pt", type: "service"),
            ]),
        ]
    }

    private var mexicoResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "visas", title: "Visas & Immigration", icon: "person.text.rectangle", resources: [
                WebResource(id: "inm", title: "INM (Immigration Agency)", description: "Instituto Nacional de Migración", url: "https://www.gob.mx/inm", type: "official"),
                WebResource(id: "temp-resident", title: "Temporary Resident Visa", description: "1-4 year residency", url: "https://www.gob.mx/tramites/ficha/visa-de-residente-temporal/SRE273", type: "official"),
                WebResource(id: "inm-citas", title: "INM Appointments", description: "Schedule card exchange", url: "https://citas.inm.gob.mx/", type: "official"),
            ]),
            WebResourceCategory(id: "curp", title: "CURP & RFC Registration", icon: "person.text.rectangle", resources: [
                WebResource(id: "curp", title: "CURP (Population Registry)", description: "Get your unique ID number", url: "https://www.gob.mx/curp/", type: "official"),
                WebResource(id: "sat", title: "SAT - RFC (Tax ID)", description: "Tax registration", url: "https://www.sat.gob.mx", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "inmuebles24", title: "Inmuebles24", description: "Mexico's largest property portal", url: "https://www.inmuebles24.com", type: "marketplace"),
                WebResource(id: "segundamano", title: "Segundamano", description: "Classifieds with property listings", url: "https://www.segundamano.mx", type: "marketplace"),
                WebResource(id: "vivanuncios", title: "Vivanuncios", description: "Property listings", url: "https://www.vivanuncios.com.mx", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "bbva-mx", title: "BBVA México", description: "Major bank, English app", url: "https://www.bbva.mx", type: "service"),
                WebResource(id: "santander-mx", title: "Santander México", description: "International bank", url: "https://www.santander.com.mx", type: "service"),
                WebResource(id: "nu-mx", title: "Nu México", description: "Digital bank", url: "https://www.nu.com.mx", type: "service"),
                WebResource(id: "wise", title: "Wise", description: "International transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "imss", title: "IMSS (Public Health)", description: "Mexican Social Security", url: "http://www.imss.gob.mx", type: "official"),
                WebResource(id: "imss-vol", title: "IMSS Voluntario", description: "Voluntary enrollment for expats", url: "http://www.imss.gob.mx/tramites/imss02025a", type: "official"),
                WebResource(id: "gnp", title: "GNP Seguros", description: "Private health insurance", url: "https://www.gnp.com.mx", type: "service"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "expats-cdmx", title: "Expats in Mexico City", description: "Facebook community", url: "https://www.facebook.com/groups/expatsinmexicocity", type: "community"),
                WebResource(id: "internations-mx", title: "InterNations Mexico", description: "Expat network", url: "https://www.internations.org/mexico-expats", type: "community"),
                WebResource(id: "sma-civil", title: "San Miguel Civil List", description: "Famous SMA expat list", url: "https://www.civillist.org", type: "community"),
            ]),
            WebResourceCategory(id: "utilities", title: "Utilities & Services", icon: "bolt", resources: [
                WebResource(id: "cfe", title: "CFE (Electricity)", description: "National electricity company", url: "https://www.cfe.mx", type: "service"),
                WebResource(id: "telmex", title: "Telmex", description: "Home internet and phone", url: "https://www.telmex.com", type: "service"),
                WebResource(id: "telcel", title: "Telcel", description: "Largest mobile carrier", url: "https://www.telcel.com", type: "service"),
            ]),
            WebResourceCategory(id: "safety", title: "Safety & Emergency", icon: "shield", resources: [
                WebResource(id: "us-embassy", title: "US Embassy Mexico", description: "Consular services", url: "https://mx.usembassy.gov", type: "official"),
                WebResource(id: "step", title: "STEP Enrollment", description: "Smart Traveler Enrollment", url: "https://step.state.gov", type: "official"),
            ]),
        ]
    }
}
