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
