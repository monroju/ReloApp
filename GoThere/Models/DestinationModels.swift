import Foundation

/// Represents a destination country for relocation.
struct DestinationCountry: Identifiable, Hashable {
    let id: String
    let name: String
    let flagEmoji: String
    let region: String
    let description: String
    let visaTracks: [VisaTrack]
    let defaultVisaTrackId: String
    var seedVersion: Int = 1
    var officialImmigrationUrl: String?
}

/// Represents a visa track within a destination country.
struct VisaTrack: Identifiable, Hashable {
    let id: String
    let destinationId: String
    let name: String
    let shortName: String
    let description: String
    var requirements: [String] = []
    var estimatedProcessingTime: String?
    var officialUrl: String?
}

/// User's destination selection stored in Firestore.
struct UserDestination: Codable, Identifiable {
    var id: String { destinationId }
    var destinationId: String = ""
    var countryName: String = ""
    var activeVisaTrackId: String = ""
    var createdAt: Date = Date()
    var lastSeededAt: Date?
    var seedVersion: Int = 0
}

extension DestinationCountry {
    private static let regionCodes: [String: String] = [
        "spain": "ES", "portugal": "PT", "mexico": "MX", "canada": "CA", "ireland": "IE",
        "italy": "IT", "germany": "DE", "poland": "PL", "argentina": "AR", "hungary": "HU",
    ]

    /// Same as `displayName`, for views that carry only a country id (cost, family, health data).
    static func displayName(for countryId: String, fallback: String) -> String {
        DestinationConfig.getDestination(countryId)?.displayName ?? fallback
    }

    /// Country name in the app's UI language ("España" in Spanish). `name` stays English
    /// because it feeds data, seeds and analytics.
    var displayName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        guard code != "en" else { return name }
        if id == "uk_ancestry" { return name.uiLocalized }
        guard let region = Self.regionCodes[id],
              let local = Locale(identifier: code).localizedString(forRegionCode: region)
        else { return name }
        return local
    }
}
