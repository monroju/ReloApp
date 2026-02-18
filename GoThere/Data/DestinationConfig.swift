import Foundation

/// Static configuration for all supported destinations and their visa tracks.
enum DestinationConfig {

    // MARK: - Destination IDs
    static let spain = "spain"
    static let portugal = "portugal"
    static let mexico = "mexico"

    // MARK: - Visa Track IDs
    static let spainNonLucrative = "es_non_lucrative"
    static let spainDigitalNomad = "es_digital_nomad"
    static let portugalD7 = "pt_d7_passive_income"
    static let portugalD8 = "pt_d8_digital_nomad"
    static let mexicoTempResident = "mx_temp_resident_economic_solvency"
    static let mexicoTempRemote = "mx_temp_resident_remote_work"

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

    // MARK: - All Destinations

    static let allDestinations: [DestinationCountry] = [spainDestination, portugalDestination, mexicoDestination]

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
