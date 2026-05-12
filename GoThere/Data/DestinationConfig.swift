import Foundation

/// Static configuration for all supported destinations and their visa tracks.
enum DestinationConfig {

    // MARK: - Destination IDs
    static let spain = "spain"
    static let portugal = "portugal"
    static let mexico = "mexico"
    static let canada = "canada"
    static let ireland = "ireland"
    static let italy = "italy"
    static let germany = "germany"
    static let poland = "poland"

    // MARK: - Visa Track IDs
    static let spainNonLucrative = "es_non_lucrative"
    static let spainDigitalNomad = "es_digital_nomad"
    static let portugalD7 = "pt_d7_passive_income"
    static let portugalD8 = "pt_d8_digital_nomad"
    static let mexicoTempResident = "mx_temp_resident_economic_solvency"
    static let mexicoTempRemote = "mx_temp_resident_remote_work"
    static let canadaCitizenshipDescent = "ca_citizenship_descent_billc3"
    static let irelandFBR = "ie_foreign_births_register"
    static let italyJureSanguinis = "it_jure_sanguinis"
    static let germanyArticle116 = "de_article_116"
    static let germanyStag15 = "de_stag_15"
    static let polandCitizenshipConfirmation = "pl_citizenship_confirmation"

    static let currentSeedVersion = 2

    // MARK: - Spain

    static let spainDestination = DestinationCountry(
        id: spain,
        name: "Spain",
        flagEmoji: "\u{1F1EA}\u{1F1F8}",
        region: "Europe",
        description: "Popular destination for Americans with excellent healthcare, rich culture, and multiple visa pathways.",
        visaTracks: [
            VisaTrack(
                id: spainNonLucrative,
                destinationId: spain,
                name: "Non-Lucrative Visa",
                shortName: "NLV",
                description: "For those with passive income who won't work in Spain. Requires proof of sufficient funds and health insurance.",
                requirements: [
                    "Proof of passive income or savings",
                    "Health insurance valid in Spain",
                    "Clean criminal record",
                    "No intention to work in Spain"
                ],
                estimatedProcessingTime: "2-3 months",
                officialUrl: "https://www.exteriores.gob.es/Consulados/"
            ),
            VisaTrack(
                id: spainDigitalNomad,
                destinationId: spain,
                name: "Digital Nomad Visa",
                shortName: "DNV",
                description: "For remote workers employed by non-Spanish companies. Requires proof of remote employment and income.",
                requirements: [
                    "Remote employment contract with non-Spanish company",
                    "Minimum income threshold",
                    "Health insurance",
                    "Clean criminal record"
                ],
                estimatedProcessingTime: "2-4 months",
                officialUrl: "https://www.exteriores.gob.es/Consulados/"
            )
        ],
        defaultVisaTrackId: spainNonLucrative,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.exteriores.gob.es/Consulados/"
    )

    // MARK: - Portugal

    static let portugalDestination = DestinationCountry(
        id: portugal,
        name: "Portugal",
        flagEmoji: "\u{1F1F5}\u{1F1F9}",
        region: "Europe",
        description: "English-friendly European destination with strong expat community, mild climate, and streamlined visa processes.",
        visaTracks: [
            VisaTrack(
                id: portugalD7,
                destinationId: portugal,
                name: "D7 Passive Income Visa",
                shortName: "D7",
                description: "For retirees and those with passive income. Most popular pathway for Americans.",
                requirements: [
                    "Proof of passive income (pension, dividends, rental)",
                    "Minimum monthly income threshold",
                    "Health insurance valid in Portugal",
                    "Clean criminal record with apostille",
                    "Proof of accommodation"
                ],
                estimatedProcessingTime: "2-4 months",
                officialUrl: "https://www.vistos.mne.gov.pt/"
            ),
            VisaTrack(
                id: portugalD8,
                destinationId: portugal,
                name: "D8 Digital Nomad Visa",
                shortName: "D8",
                description: "For remote workers with employment or self-employment income from outside Portugal.",
                requirements: [
                    "Remote employment contract or self-employment proof",
                    "Minimum monthly income (4x Portuguese minimum wage)",
                    "Health insurance valid in Portugal",
                    "Clean criminal record with apostille",
                    "Proof of accommodation"
                ],
                estimatedProcessingTime: "2-4 months",
                officialUrl: "https://www.vistos.mne.gov.pt/"
            )
        ],
        defaultVisaTrackId: portugalD7,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.vistos.mne.gov.pt/"
    )

    // MARK: - Mexico

    static let mexicoDestination = DestinationCountry(
        id: mexico,
        name: "Mexico",
        flagEmoji: "\u{1F1F2}\u{1F1FD}",
        region: "North America",
        description: "Close to the US with lower cost of living, no time zone challenges, and welcoming expat communities.",
        visaTracks: [
            VisaTrack(
                id: mexicoTempResident,
                destinationId: mexico,
                name: "Temporary Resident - Economic Solvency",
                shortName: "Temp Res",
                description: "For those with sufficient savings or income. Most common pathway for Americans relocating.",
                requirements: [
                    "Proof of economic solvency (bank statements)",
                    "Minimum balance or monthly income threshold",
                    "Valid passport",
                    "Application at Mexican consulate"
                ],
                estimatedProcessingTime: "1-3 weeks at consulate, then INM exchange",
                officialUrl: "https://consulmex.sre.gob.mx/"
            ),
            VisaTrack(
                id: mexicoTempRemote,
                destinationId: mexico,
                name: "Temporary Resident - Remote Work",
                shortName: "Remote",
                description: "Similar requirements to economic solvency, emphasizing remote work income.",
                requirements: [
                    "Proof of remote employment income",
                    "Bank statements showing consistent deposits",
                    "Valid passport",
                    "Application at Mexican consulate"
                ],
                estimatedProcessingTime: "1-3 weeks at consulate, then INM exchange",
                officialUrl: "https://consulmex.sre.gob.mx/"
            )
        ],
        defaultVisaTrackId: mexicoTempResident,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.inm.gob.mx/"
    )

    // MARK: - Canada (Citizenship by Descent)

    static let canadaDestination = DestinationCountry(
        id: canada,
        name: "Canada",
        flagEmoji: "\u{1F1E8}\u{1F1E6}",
        region: "North America",
        description: "Bill C-3 (effective Dec 15, 2025) removed the first-generation limit on Canadian citizenship by descent. If you have a Canadian-born or naturalized ancestor, you may already be Canadian.",
        visaTracks: [
            VisaTrack(
                id: canadaCitizenshipDescent,
                destinationId: canada,
                name: "Canadian Citizenship by Descent (Bill C-3)",
                shortName: "Bill C-3",
                description: "If you descend from a Canadian-born or naturalized ancestor, you may already be a Canadian citizen by operation of law. The Lost Canadians Act (Bill C-3, 2025) removed the first-generation limit and is retroactive for births before Dec 15, 2025.",
                requirements: [
                    "Canadian-born or naturalized ancestor in your direct line",
                    "Documentary chain (birth/marriage certificates) from you to that ancestor",
                    "If born on/after 2025-12-15 to a Canadian parent who is also a citizen by descent: parent must have spent ≥1,095 days physically in Canada before your birth (Substantial Connection test)",
                    "Apply to IRCC for proof of citizenship (Form CIT 0001)"
                ],
                estimatedProcessingTime: "6–12 months for proof of citizenship",
                officialUrl: "https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-citizenship/proof-citizenship.html"
            )
        ],
        defaultVisaTrackId: canadaCitizenshipDescent,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.canada.ca/en/immigration-refugees-citizenship.html"
    )

    // MARK: - Ireland (Foreign Births Register)

    static let irelandDestination = DestinationCountry(
        id: ireland,
        name: "Ireland",
        flagEmoji: "\u{1F1EE}\u{1F1EA}",
        region: "Europe",
        description: "Irish citizenship by descent through the Foreign Births Register. If you have a grandparent born on the island of Ireland, you can register and become an Irish (and EU) citizen.",
        visaTracks: [
            VisaTrack(
                id: irelandFBR,
                destinationId: ireland,
                name: "Foreign Births Register (Citizenship by Descent)",
                shortName: "FBR",
                description: "If you were born outside Ireland to a parent who was an Irish citizen at the time of your birth — most commonly because your grandparent was born on the island of Ireland — you can register on the Foreign Births Register and obtain Irish citizenship and a full EU passport.",
                requirements: [
                    "Grandparent born on the island of Ireland (or eligible parent)",
                    "Birth certificates for you, your Irish-citizen parent, and the Irish-born grandparent (GRO-issued certified copies)",
                    "Marriage certificates linking the chain where surnames change",
                    "Government-issued photo ID and address verification",
                    "Online application + signed paper copy posted with documents"
                ],
                estimatedProcessingTime: "Approximately 12 months",
                officialUrl: "https://fbr.dfa.ie/"
            )
        ],
        defaultVisaTrackId: irelandFBR,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.ireland.ie/en/dfa/citizenship/"
    )

    // MARK: - Italy (Jure Sanguinis)

    static let italyDestination = DestinationCountry(
        id: italy,
        name: "Italy",
        flagEmoji: "\u{1F1EE}\u{1F1F9}",
        region: "Europe",
        description: "Italian citizenship by descent (jure sanguinis). The March 2025 reform limits eligibility to applicants with an Italian-born parent or grandparent — but those who qualify gain Italian (and EU) citizenship for life.",
        visaTracks: [
            VisaTrack(
                id: italyJureSanguinis,
                destinationId: italy,
                name: "Italian Citizenship by Descent (Jure Sanguinis)",
                shortName: "Jure Sanguinis",
                description: "Italian citizenship is transmitted by blood (jure sanguinis). Decree-Law 36/2025 (in force March 28, 2025) restricted eligibility to applicants with at least one Italian-born parent or grandparent for applications filed on or after that date. The unbroken citizenship chain must be intact (no ancestor naturalized as a US citizen before passing citizenship to the next generation in the line).",
                requirements: [
                    "Italian-born parent or grandparent in your direct line (post-2025 reform)",
                    "Unbroken citizenship chain — Italian ancestor did not naturalize as a US citizen before the next generation in the line was born (or if they did, only after that birth)",
                    "Certified vital records (birth, marriage, death) for each generation, with Apostille + sworn Italian translation",
                    "Application filed at the Italian consulate having jurisdiction over your US residence (or via 1948 case in Italian court if descent passes through a female ancestor before 1948)",
                    "Proof of residence in the consular jurisdiction (utility bills, lease)"
                ],
                estimatedProcessingTime: "12–24 months at consulate; 18–36 months for 1948 court route",
                officialUrl: "https://www.esteri.it/en/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/"
            )
        ],
        defaultVisaTrackId: italyJureSanguinis,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.esteri.it/en/servizi-consolari-e-visti/italiani-all-estero/cittadinanza/"
    )

    // MARK: - Germany (Article 116 + StAG §15)

    static let germanyDestination = DestinationCountry(
        id: germany,
        name: "Germany",
        flagEmoji: "\u{1F1E9}\u{1F1EA}",
        region: "Europe",
        description: "Germany offers two citizenship restoration pathways for descendants of Germans persecuted by the Nazi regime (Article 116(2) Basic Law) or barred from citizenship by historic discriminatory laws (StAG §15). Both routes grant German and EU citizenship for life with no language test, residency, or fee.",
        visaTracks: [
            VisaTrack(
                id: germanyArticle116,
                destinationId: germany,
                name: "Article 116(2) Restoration (Nazi-era Persecution)",
                shortName: "Article 116",
                description: "If your ancestor was a German citizen who lost citizenship between January 30, 1933 and May 8, 1945 for political, racial, or religious reasons (most commonly: German Jews stripped of citizenship under the 1941 11th Reich Citizenship Ordinance), you and their descendants have a constitutional right to restoration. No language test, no residency requirement, no fee.",
                requirements: [
                    "Direct-line descent from a German citizen persecuted between 1933 and 1945",
                    "Evidence ancestor was a German citizen (pre-1941 passport, residence registration, vital records)",
                    "Evidence of persecution (e.g., emigration after 1933, listing in 1941 expatriation gazette, Yad Vashem record, naturalization documents in country of refuge)",
                    "Unbroken documentary chain of descent (birth + marriage certificates) from the persecuted ancestor to you",
                    "Application form (BVA-Antrag) to the Bundesverwaltungsamt in Cologne",
                    "Dual citizenship permitted — you keep your US citizenship"
                ],
                estimatedProcessingTime: "18–36 months at Bundesverwaltungsamt",
                officialUrl: "https://www.bva.bund.de/EN/Services/Citizens/Migration-Citizenship/Citizenship/Restoration-of-citizenship/restoration-of-citizenship_node.html"
            ),
            VisaTrack(
                id: germanyStag15,
                destinationId: germany,
                name: "StAG §15 Restoration",
                shortName: "StAG §15",
                description: "Added in 2021, StAG §15 closes loopholes in Article 116. It covers descendants of Germans who were barred from acquiring or transmitting citizenship by historic discriminatory laws — most commonly: children of German mothers and foreign fathers born before April 1, 1953 (pre-equality law); children born out of wedlock to German fathers before July 1, 1993; descendants who would have been Article 116 eligible but for technical gaps.",
                requirements: [
                    "Descent from a person who was excluded from German citizenship by discriminatory pre-1953 law, or otherwise barred by technical gaps in earlier statutes",
                    "Documentary chain (birth + marriage certificates) showing the excluded ancestor and your line of descent",
                    "Application to the Bundesverwaltungsamt under StAG §15 (separate form from Article 116)",
                    "Dual citizenship permitted",
                    "No language test, no residency requirement, no fee"
                ],
                estimatedProcessingTime: "18–36 months at Bundesverwaltungsamt",
                officialUrl: "https://www.bva.bund.de/EN/Services/Citizens/Migration-Citizenship/Citizenship/Restoration-of-citizenship/restoration-of-citizenship_node.html"
            )
        ],
        defaultVisaTrackId: germanyArticle116,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.bva.bund.de/EN/Home/home_node.html"
    )

    // MARK: - Poland (Citizenship Confirmation)

    static let polandDestination = DestinationCountry(
        id: poland,
        name: "Poland",
        flagEmoji: "\u{1F1F5}\u{1F1F1}",
        region: "Europe",
        description: "Confirmation of Polish citizenship (potwierdzenie posiadania obywatelstwa polskiego) for descendants of Polish citizens. If you can trace an unbroken line to a Polish citizen ancestor who emigrated after Poland's 1920 citizenship law took effect, you may already be a Polish citizen by operation of law — and gain EU citizenship by confirmation.",
        visaTracks: [
            VisaTrack(
                id: polandCitizenshipConfirmation,
                destinationId: poland,
                name: "Confirmation of Polish Citizenship",
                shortName: "Confirmation",
                description: "Polish citizenship is hereditary and was not automatically lost by emigration. The voivode (provincial governor) of the relevant Polish province issues a decision confirming that you are a Polish citizen — based on an unbroken chain of citizenship from your Polish ancestor. Key cut-off: Polish citizenship law took effect in January 1920; emigration before then is harder to trace. Subsequent loss-of-citizenship events (1951 law, military service for a foreign state, etc.) can break the chain — careful pre-screening is essential.",
                requirements: [
                    "Polish ancestor with proven Polish citizenship after January 31, 1920 (or earlier under conditions of the 1920 law)",
                    "No break in the citizenship chain — ancestor must not have lost Polish citizenship by foreign naturalization before 1951, by serving in a foreign army or accepting a foreign public office, or by other statutory triggers",
                    "Ancestor's Polish documents: passport, military service book (książeczka wojskowa), civil registry records, residence registration (zameldowanie), naturalization records from country of emigration",
                    "Unbroken vital records chain (birth, marriage, death) from the Polish ancestor to you, with apostille and sworn Polish translation",
                    "Application (wniosek o potwierdzenie posiadania obywatelstwa polskiego) to the voivode of the appropriate Polish province (typically Mazowieckie for diaspora applicants), or via consulate",
                    "Dual citizenship permitted"
                ],
                estimatedProcessingTime: "6–18 months at voivode; longer if archives need to be searched",
                officialUrl: "https://www.gov.pl/web/usa-en/citizenship"
            )
        ],
        defaultVisaTrackId: polandCitizenshipConfirmation,
        seedVersion: currentSeedVersion,
        officialImmigrationUrl: "https://www.gov.pl/web/usa-en/citizenship"
    )

    // MARK: - All Destinations

    static let allDestinations: [DestinationCountry] = [
        spainDestination,
        portugalDestination,
        mexicoDestination,
        canadaDestination,
        irelandDestination,
        italyDestination,
        germanyDestination,
        polandDestination
    ]

    static func getDestination(_ id: String) -> DestinationCountry? {
        allDestinations.first { $0.id == id }
    }

    static func getVisaTrack(destinationId: String, trackId: String) -> VisaTrack? {
        getDestination(destinationId)?.visaTracks.first { $0.id == trackId }
    }

    static func getDefaultVisaTrack(destinationId: String) -> VisaTrack? {
        guard let destination = getDestination(destinationId) else { return nil }
        return destination.visaTracks.first { $0.id == destination.defaultVisaTrackId }
    }
}
