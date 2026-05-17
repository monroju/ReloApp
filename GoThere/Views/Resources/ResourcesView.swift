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
    @EnvironmentObject var countrySelection: CountrySelection
    @StateObject private var vm = ResourcesViewModel()
    @State private var expandedCategories: Set<String> = []
    @State private var showPaywall = false

    private var isUnlocked: Bool {
        purchaseManager.isCountryUnlocked(countrySelection.current)
    }

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
                            Task { await vm.loadDocuments(for: countrySelection.current) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.goPrimary)
                        }
                    }

                    if !isUnlocked {
                        lockedCountryCard
                    } else {
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

                    // Cross-promotion: Localista (always visible)
                    Divider().padding(.vertical, 8)

                    Button {
                        if let url = URL(string: "https://apps.apple.com/app/localista-spain-expat-news/id6760856341") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "newspaper")
                                .font(.title2)
                                .foregroundColor(.goPrimary)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Try Localista")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("Spain news in English — 30+ cities, emergency alerts, expat guides")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .goTopBar(showThemeToggle: false)
            .onChange(of: countrySelection.current) { _ in
                expandedCategories.removeAll()
                Task { await vm.loadDocuments(for: countrySelection.current) }
            }
            .task {
                await vm.loadDocuments(for: countrySelection.current)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Locked Country Card

    private var lockedCountryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(.goPrimary)
            Text("\(countryName) is locked")
                .font(.headline)
            Text("Unlock the \(countryName) Pack to access immigration portals, housing sites, banking, healthcare, and expat communities — plus downloadable PDF guides.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showPaywall = true
            } label: {
                Text("Unlock \(countryName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.goPrimary)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.top, 8)
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
        DestinationConfig.getDestination(countrySelection.current)?.name ?? "Spain"
    }

    private var countryFlag: String {
        DestinationConfig.getDestination(countrySelection.current)?.flagEmoji ?? "\u{1F1EA}\u{1F1F8}"
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
        switch countrySelection.current {
        case "portugal": return portugalResources
        case "mexico": return mexicoResources
        case "canada": return canadaResources
        case "ireland": return irelandResources
        case "italy": return italyResources
        case "germany": return germanyResources
        case "poland": return polandResources
        case "argentina": return argentinaResources
        case "hungary": return hungaryResources
        case "uk_ancestry": return ukAncestryResources
        default: return spainResources
        }
    }

    private var canadaResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "ircc", title: "IRCC (Immigration Canada)", description: "Immigration, Refugees and Citizenship Canada", url: "https://www.canada.ca/en/immigration-refugees-citizenship.html", type: "official"),
                WebResource(id: "consulates-ca", title: "Canadian Consulates in USA", description: "Find your assigned consulate", url: "https://travel.gc.ca/assistance/embassies-consulates", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "ID & Tax Registration", icon: "person.text.rectangle", resources: [
                WebResource(id: "sin", title: "SIN (Social Insurance Number)", description: "Required to work and pay taxes", url: "https://www.canada.ca/en/employment-social-development/services/sin.html", type: "official"),
                WebResource(id: "cra", title: "Canada Revenue Agency", description: "Federal taxes for residents", url: "https://www.canada.ca/en/revenue-agency.html", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "realtor-ca", title: "Realtor.ca", description: "MLS national property search", url: "https://www.realtor.ca", type: "marketplace"),
                WebResource(id: "rentals-ca", title: "Rentals.ca", description: "Apartment and home rentals", url: "https://rentals.ca", type: "marketplace"),
                WebResource(id: "kijiji", title: "Kijiji", description: "Classifieds with rentals", url: "https://www.kijiji.ca", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "rbc", title: "RBC Royal Bank", description: "Largest Canadian bank", url: "https://www.rbc.com", type: "service"),
                WebResource(id: "td", title: "TD Canada Trust", description: "Cross-border friendly", url: "https://www.td.com", type: "service"),
                WebResource(id: "wise", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "health-canada", title: "Health Canada", description: "Provincial healthcare overview", url: "https://www.canada.ca/en/health-canada/services/health-care-system/canada-health-care-system-medicare.html", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "reddit-can", title: "r/PersonalFinanceCanada", description: "Reddit community", url: "https://www.reddit.com/r/PersonalFinanceCanada/", type: "community"),
                WebResource(id: "internations-ca", title: "InterNations Canada", description: "Expat network", url: "https://www.internations.org/canada-expats", type: "community"),
            ]),
        ]
    }

    private var irelandResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "dfa", title: "Department of Foreign Affairs", description: "Citizenship + foreign births portal", url: "https://www.ireland.ie/en/dfa/citizenship/", type: "official"),
                WebResource(id: "isd", title: "Irish Immigration Service", description: "Visas, Stamps, residence permissions", url: "https://www.irishimmigration.ie/", type: "official"),
                WebResource(id: "consulates-ie", title: "Irish Consulates in USA", description: "Find your assigned consulate", url: "https://www.ireland.ie/en/usa/", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "ID & Tax Registration", icon: "person.text.rectangle", resources: [
                WebResource(id: "pps", title: "PPS Number Service", description: "Personal Public Service Number", url: "https://www.gov.ie/en/service/12e6de-get-a-personal-public-service-pps-number/", type: "official"),
                WebResource(id: "revenue-ie", title: "Revenue (Irish Tax)", description: "Tax registration for residents", url: "https://www.revenue.ie", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "daft", title: "Daft.ie", description: "Ireland's largest property portal", url: "https://www.daft.ie", type: "marketplace"),
                WebResource(id: "myhome-ie", title: "MyHome.ie", description: "Property and rentals", url: "https://www.myhome.ie", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "boi", title: "Bank of Ireland", description: "Largest retail bank", url: "https://www.bankofireland.com", type: "service"),
                WebResource(id: "aib", title: "AIB", description: "Allied Irish Banks", url: "https://www.aib.ie", type: "service"),
                WebResource(id: "revolut-ie", title: "Revolut", description: "Digital banking, popular in Ireland", url: "https://www.revolut.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "hse", title: "HSE (Health Service Executive)", description: "Public healthcare", url: "https://www.hse.ie", type: "official"),
                WebResource(id: "vhi", title: "Vhi Healthcare", description: "Largest private insurer", url: "https://www.vhi.ie", type: "service"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "boards-ie", title: "Boards.ie", description: "Ireland's largest forum", url: "https://www.boards.ie", type: "community"),
                WebResource(id: "internations-ie", title: "InterNations Ireland", description: "Expat network", url: "https://www.internations.org/ireland-expats", type: "community"),
            ]),
        ]
    }

    private var italyResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "esteri", title: "Italian MFA Citizenship", description: "Jure sanguinis + visa types portal", url: "https://www.esteri.it/en/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/", type: "official"),
                WebResource(id: "vistoperitalia", title: "Visto per l'Italia", description: "Italian visa portal — all national visas", url: "https://vistoperitalia.esteri.it/", type: "official"),
                WebResource(id: "prenotami", title: "Prenot@mi", description: "Book consulate appointments", url: "https://prenotami.esteri.it/", type: "official"),
                WebResource(id: "consulates-it", title: "Italian Consulates in USA", description: "Find your assigned consulate", url: "https://www.esteri.it/en/ministero/laministero/lerappresentanze/", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "Codice Fiscale & Anagrafe", icon: "person.text.rectangle", resources: [
                WebResource(id: "codice-fiscale", title: "Agenzia delle Entrate (Codice Fiscale)", description: "Italian tax code", url: "https://www.agenziaentrate.gov.it/portale/codice-fiscale-tessera-sanitaria", type: "official"),
                WebResource(id: "anagrafe", title: "Anagrafe Nazionale", description: "National residents registry", url: "https://www.anagrafenazionale.interno.it/", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "immobiliare-it", title: "Immobiliare.it", description: "Italy's largest property portal", url: "https://www.immobiliare.it", type: "marketplace"),
                WebResource(id: "idealista-it", title: "Idealista Italia", description: "Property and rentals", url: "https://www.idealista.it", type: "marketplace"),
                WebResource(id: "subito-it", title: "Subito.it", description: "Classifieds with rentals", url: "https://www.subito.it", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "intesa", title: "Intesa Sanpaolo", description: "Largest Italian bank", url: "https://www.intesasanpaolo.com", type: "service"),
                WebResource(id: "unicredit", title: "UniCredit", description: "Major bank, English support", url: "https://www.unicredit.it", type: "service"),
                WebResource(id: "wise-it", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "ssn", title: "SSN (Servizio Sanitario Nazionale)", description: "National Health Service", url: "https://www.salute.gov.it", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations-it", title: "InterNations Italy", description: "Expat network", url: "https://www.internations.org/italy-expats", type: "community"),
                WebResource(id: "reddit-it", title: "r/ItalyExpat", description: "Reddit community", url: "https://www.reddit.com/r/ItalyExpat/", type: "community"),
            ]),
        ]
    }

    private var germanyResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "bva", title: "Bundesverwaltungsamt (BVA)", description: "Citizenship restoration (Art. 116, StAG §15)", url: "https://www.bva.bund.de/EN/Services/Citizens/Migration-Citizenship/Citizenship/Restoration-of-citizenship/restoration-of-citizenship_node.html", type: "official"),
                WebResource(id: "make-it-de", title: "Make it in Germany", description: "Official visa portal — Blue Card, Freelancer, Chancenkarte, etc.", url: "https://www.make-it-in-germany.com/en/visa-residence/", type: "official"),
                WebResource(id: "consulates-de", title: "German Consulates in USA", description: "Find your assigned consulate", url: "https://www.germany.info/us-en", type: "official"),
                WebResource(id: "yadvashem", title: "Yad Vashem", description: "Persecution evidence research (StAG §15)", url: "https://www.yadvashem.org/", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "Anmeldung & Tax", icon: "person.text.rectangle", resources: [
                WebResource(id: "anmeldung", title: "Anmeldung Registration", description: "Required address registration", url: "https://service.berlin.de/dienstleistung/120335/", type: "official"),
                WebResource(id: "elster", title: "ELSTER (Finanzamt)", description: "German tax portal", url: "https://www.elster.de", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "immoscout", title: "ImmoScout24", description: "Germany's largest property portal", url: "https://www.immobilienscout24.de", type: "marketplace"),
                WebResource(id: "immowelt", title: "Immowelt", description: "Property and rentals", url: "https://www.immowelt.de", type: "marketplace"),
                WebResource(id: "wg-gesucht", title: "WG-Gesucht", description: "Shared apartments and rentals", url: "https://www.wg-gesucht.de", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "n26-de", title: "N26", description: "Berlin-based digital bank", url: "https://n26.com/en-de", type: "service"),
                WebResource(id: "dkb", title: "DKB", description: "Online bank, free account", url: "https://www.dkb.de", type: "service"),
                WebResource(id: "deutsche-bank", title: "Deutsche Bank", description: "Major retail bank", url: "https://www.deutsche-bank.de", type: "service"),
                WebResource(id: "wise-de", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "tk", title: "TK (Techniker Krankenkasse)", description: "Largest public health insurer", url: "https://www.tk.de/en", type: "official"),
                WebResource(id: "aok", title: "AOK", description: "Public health insurance", url: "https://www.aok.de", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "toytown", title: "Toytown Germany", description: "English-speaking expat forum", url: "https://www.toytowngermany.com", type: "community"),
                WebResource(id: "internations-de", title: "InterNations Germany", description: "Expat network", url: "https://www.internations.org/germany-expats", type: "community"),
            ]),
        ]
    }

    private var polandResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "gov-pl", title: "Polish Government Citizenship Portal", description: "Confirmation of Polish citizenship", url: "https://www.gov.pl/web/usa-en/citizenship", type: "official"),
                WebResource(id: "udsc", title: "Office for Foreigners (UDSC)", description: "Residence permits + work permits portal", url: "https://www.gov.pl/web/udsc", type: "official"),
                WebResource(id: "voivode", title: "Mazowiecki Voivode", description: "Diaspora applicant office", url: "https://www.gov.pl/web/uw-mazowiecki", type: "official"),
                WebResource(id: "consulates-pl", title: "Polish Consulates in USA", description: "Find your assigned consulate", url: "https://www.gov.pl/web/usa-en", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "PESEL & Tax", icon: "person.text.rectangle", resources: [
                WebResource(id: "pesel", title: "PESEL Number Application", description: "Polish personal ID number", url: "https://www.gov.pl/web/gov/uzyskaj-numer-pesel-dla-cudzoziemcow", type: "official"),
                WebResource(id: "us-pl", title: "Urząd Skarbowy (Tax Office)", description: "Tax registration in Poland", url: "https://www.podatki.gov.pl", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "otodom", title: "Otodom", description: "Poland's largest property portal", url: "https://www.otodom.pl", type: "marketplace"),
                WebResource(id: "olx-pl", title: "OLX Nieruchomości", description: "Classifieds with rentals", url: "https://www.olx.pl/nieruchomosci/", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "mbank", title: "mBank", description: "Online bank, English app", url: "https://www.mbank.pl", type: "service"),
                WebResource(id: "pko", title: "PKO Bank Polski", description: "Largest Polish bank", url: "https://www.pkobp.pl", type: "service"),
                WebResource(id: "revolut-pl", title: "Revolut", description: "Digital banking", url: "https://www.revolut.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "nfz", title: "NFZ (National Health Fund)", description: "Public healthcare", url: "https://www.nfz.gov.pl", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations-pl", title: "InterNations Poland", description: "Expat network", url: "https://www.internations.org/poland-expats", type: "community"),
                WebResource(id: "reddit-pl", title: "r/poland", description: "Reddit community", url: "https://www.reddit.com/r/poland/", type: "community"),
            ]),
        ]
    }

    private var argentinaResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "cancilleria", title: "Argentine MFA Citizenship", description: "Citizenship by option (Ley 346) portal", url: "https://www.cancilleria.gob.ar/en/services/argentinians-abroad/argentine-citizenship", type: "official"),
                WebResource(id: "ar-migraciones", title: "Argentine Migrations Portal", description: "Residence permits — Rentista, Pensionado, Investor", url: "https://www.argentina.gob.ar/migraciones", type: "official"),
                WebResource(id: "consulates-ar", title: "Argentine Consulates in USA", description: "Find your assigned consulate", url: "https://www.cancilleria.gob.ar/en/foreign-policy/embassies-and-consulates", type: "official"),
                WebResource(id: "renaper", title: "RENAPER", description: "National Persons Registry (DNI)", url: "https://www.argentina.gob.ar/interior/renaper", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "DNI & Tax", icon: "person.text.rectangle", resources: [
                WebResource(id: "dni", title: "DNI Application", description: "Argentine national ID card", url: "https://www.argentina.gob.ar/interior/renaper/dni", type: "official"),
                WebResource(id: "afip", title: "AFIP", description: "Tax authority (CUIT/CUIL)", url: "https://www.afip.gob.ar/", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "zonaprop", title: "ZonaProp", description: "Argentina's largest property portal", url: "https://www.zonaprop.com.ar", type: "marketplace"),
                WebResource(id: "argenprop", title: "ArgenProp", description: "Property and rentals", url: "https://www.argenprop.com", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "santander-ar", title: "Santander Argentina", description: "International bank", url: "https://www.santander.com.ar", type: "service"),
                WebResource(id: "galicia", title: "Banco Galicia", description: "Major private bank", url: "https://www.bancogalicia.com", type: "service"),
                WebResource(id: "wise-ar", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "obras-sociales", title: "Public Healthcare Argentina", description: "Universal coverage overview", url: "https://www.argentina.gob.ar/salud", type: "official"),
                WebResource(id: "osde", title: "OSDE", description: "Largest private health plan", url: "https://www.osde.com.ar", type: "service"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations-ar", title: "InterNations Argentina", description: "Expat network", url: "https://www.internations.org/argentina-expats", type: "community"),
                WebResource(id: "reddit-ba", title: "r/buenosaires", description: "Reddit community", url: "https://www.reddit.com/r/buenosaires/", type: "community"),
            ]),
        ]
    }

    private var hungaryResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "citizenship", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "allampolgarsag", title: "Hungarian Citizenship Portal", description: "Simplified naturalization application", url: "https://allampolgarsag.gov.hu/", type: "official"),
                WebResource(id: "oif-hu", title: "Office for Immigration (OIF)", description: "D-Visa, White Card, residence permits", url: "https://oif.gov.hu/", type: "official"),
                WebResource(id: "nemzetikartya", title: "Nemzeti Kártya", description: "Guest Investor + White Card portal", url: "https://nemzetikartya.gov.hu/", type: "official"),
                WebResource(id: "kormanyablak", title: "Kormányablak (Govt Office)", description: "One-stop government office", url: "https://kormanyablak.hu/en", type: "official"),
                WebResource(id: "embassy-hu", title: "Hungarian Embassy USA", description: "Washington DC consulate", url: "https://washington.mfa.gov.hu/eng", type: "official"),
            ]),
            WebResourceCategory(id: "documents", title: "Documents & Translation", icon: "doc.text", resources: [
                WebResource(id: "offi", title: "OFFI (Translation Office)", description: "Official Hungarian translations", url: "https://www.offi.hu/", type: "service"),
                WebResource(id: "balassi", title: "Hungarian Cultural Institute", description: "Language courses & resources", url: "https://newyork.balassiintezet.hu/en/", type: "official"),
                WebResource(id: "familysearch-hu", title: "FamilySearch — Hungary", description: "Ancestor records research", url: "https://www.familysearch.org/en/search/collection/list?page=1&place=Hungary", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "ID Cards & Tax", icon: "person.text.rectangle", resources: [
                WebResource(id: "nyilvantarto", title: "Nyilvántartó", description: "ID card and address registry", url: "https://nyilvantarto.hu/", type: "official"),
                WebResource(id: "nav-hu", title: "NAV (Tax Authority)", description: "Hungarian taxation", url: "https://www.nav.gov.hu/", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "ingatlan", title: "Ingatlan.com", description: "Hungary's largest property portal", url: "https://ingatlan.com", type: "marketplace"),
                WebResource(id: "otthonterkep", title: "Otthontérkép", description: "Property listings", url: "https://www.otthonterkep.hu", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "otp", title: "OTP Bank", description: "Largest Hungarian bank", url: "https://www.otpbank.hu", type: "service"),
                WebResource(id: "revolut-hu", title: "Revolut", description: "Digital banking, popular in Hungary", url: "https://www.revolut.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "neak", title: "NEAK (Health Insurance Fund)", description: "Public healthcare (TAJ card)", url: "https://neak.gov.hu/", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations-hu", title: "InterNations Hungary", description: "Expat network", url: "https://www.internations.org/hungary-expats", type: "community"),
                WebResource(id: "xpatloop", title: "XpatLoop", description: "English-language Hungary news/community", url: "https://xpatloop.com", type: "community"),
            ]),
        ]
    }

    private var ukAncestryResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "visa", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "ukvi", title: "UK Visas and Immigration (UKVI)", description: "Official UKVI portal — all visa categories", url: "https://www.gov.uk/government/organisations/uk-visas-and-immigration", type: "official"),
                WebResource(id: "ilr", title: "ILR (Settlement) Guidance", description: "Indefinite Leave to Remain after 5yr", url: "https://www.gov.uk/ancestry-visa/settle-in-the-uk", type: "official"),
                WebResource(id: "ihs-info", title: "Immigration Health Surcharge", description: "Paid as part of visa application", url: "https://www.gov.uk/healthcare-immigration-application", type: "official"),
            ]),
            WebResourceCategory(id: "documents", title: "Birth Certificates & Records", icon: "doc.text", resources: [
                WebResource(id: "gro", title: "GRO (England & Wales)", description: "Order birth/marriage certificates", url: "https://www.gro.gov.uk/gro/content/certificates/", type: "official"),
                WebResource(id: "scotlandspeople", title: "ScotlandsPeople", description: "Scottish family records", url: "https://www.scotlandspeople.gov.uk/", type: "official"),
                WebResource(id: "groni", title: "GRONI (Northern Ireland)", description: "Order NI certificates", url: "https://www.nidirect.gov.uk/articles/general-register-office", type: "official"),
                WebResource(id: "tb-test", title: "TB Test Country List", description: "Required pre-visa health check", url: "https://www.gov.uk/tb-test-visa", type: "official"),
            ]),
            WebResourceCategory(id: "id", title: "NIN & Tax", icon: "person.text.rectangle", resources: [
                WebResource(id: "nin", title: "National Insurance Number", description: "Apply post-arrival", url: "https://www.gov.uk/apply-national-insurance-number", type: "official"),
                WebResource(id: "hmrc", title: "HMRC", description: "UK tax authority", url: "https://www.gov.uk/government/organisations/hm-revenue-customs", type: "official"),
            ]),
            WebResourceCategory(id: "housing", title: "Housing & Rentals", icon: "house", resources: [
                WebResource(id: "rightmove", title: "Rightmove", description: "UK's largest property portal", url: "https://www.rightmove.co.uk", type: "marketplace"),
                WebResource(id: "zoopla", title: "Zoopla", description: "Property and rentals", url: "https://www.zoopla.co.uk", type: "marketplace"),
                WebResource(id: "spareroom", title: "SpareRoom", description: "Flatshare and rooms", url: "https://www.spareroom.co.uk", type: "marketplace"),
            ]),
            WebResourceCategory(id: "banking", title: "Banking & Finance", icon: "building.columns", resources: [
                WebResource(id: "monzo", title: "Monzo", description: "Popular UK digital bank", url: "https://monzo.com", type: "service"),
                WebResource(id: "starling", title: "Starling Bank", description: "Digital bank, easy setup", url: "https://www.starlingbank.com", type: "service"),
                WebResource(id: "hsbc-uk", title: "HSBC UK", description: "Major retail bank", url: "https://www.hsbc.co.uk", type: "service"),
                WebResource(id: "wise-uk", title: "Wise", description: "Multi-currency transfers", url: "https://wise.com", type: "service"),
            ]),
            WebResourceCategory(id: "healthcare", title: "Healthcare", icon: "cross.case", resources: [
                WebResource(id: "nhs", title: "NHS", description: "National Health Service", url: "https://www.nhs.uk", type: "official"),
                WebResource(id: "ihs", title: "Immigration Health Surcharge", description: "Paid as part of visa fee", url: "https://www.gov.uk/healthcare-immigration-application", type: "official"),
            ]),
            WebResourceCategory(id: "community", title: "Expat Communities", icon: "person.3", resources: [
                WebResource(id: "internations-uk", title: "InterNations UK", description: "Expat network", url: "https://www.internations.org/united-kingdom-expats", type: "community"),
                WebResource(id: "reddit-uk", title: "r/AskUK", description: "Reddit community", url: "https://www.reddit.com/r/AskUK/", type: "community"),
            ]),
        ]
    }

    private var spainResources: [WebResourceCategory] {
        [
            WebResourceCategory(id: "visas", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "spain-consulate", title: "Spanish Consulates in USA", description: "Find your assigned consulate", url: "https://www.exteriores.gob.es/en/EmbajadasConsulados/Paginas/index.aspx", type: "official"),
                WebResource(id: "spain-nie", title: "NIE/TIE Application Guide", description: "Foreigner identification numbers", url: "https://www.inclusion.gob.es/web/migraciones/w/extranjeria", type: "official"),
                WebResource(id: "spain-migr", title: "Spanish Immigration Portal", description: "Official Inclusión y Migraciones", url: "https://www.inclusion.gob.es/web/migraciones", type: "official"),
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
            WebResourceCategory(id: "visas", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "aima", title: "AIMA (Immigration Agency)", description: "Portuguese immigration portal", url: "https://www.aima.gov.pt", type: "official"),
                WebResource(id: "pt-mne", title: "Portuguese MFA Visas Portal", description: "All national visas (D7, D8, D2, etc.)", url: "https://vistos.mne.gov.pt/en/national-visas/general-information/type-of-visa", type: "official"),
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
            WebResourceCategory(id: "visas", title: "Government & Immigration Portals", icon: "person.text.rectangle", resources: [
                WebResource(id: "inm", title: "INM (Immigration Agency)", description: "Instituto Nacional de Migración", url: "https://www.gob.mx/inm", type: "official"),
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
