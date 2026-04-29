import Foundation

/// Static configuration for all supported destinations and their visa tracks.
enum DestinationConfig {

    // MARK: - Destination IDs
    static let spain = "spain"
    static let portugal = "portugal"
    static let mexico = "mexico"
    static let canada = "canada"
    static let ireland = "ireland"

    // MARK: - Visa Track IDs
    static let spainNonLucrative = "es_non_lucrative"
    static let spainDigitalNomad = "es_digital_nomad"
    static let portugalD7 = "pt_d7_passive_income"
    static let portugalD8 = "pt_d8_digital_nomad"
    static let mexicoTempResident = "mx_temp_resident_economic_solvency"
    static let mexicoTempRemote = "mx_temp_resident_remote_work"
    static let canadaCitizenshipDescent = "ca_citizenship_descent_billc3"
    static let irelandFBR = "ie_foreign_births_register"

    static let currentSeedVersion = 1

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

    // MARK: - All Destinations

    static let allDestinations: [DestinationCountry] = [
        spainDestination,
        portugalDestination,
        mexicoDestination,
        canadaDestination,
        irelandDestination
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
