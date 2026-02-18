import Foundation

/// Represents a visa track within a destination country.
/// Each destination can have multiple visa tracks (e.g., Digital Nomad, Passive Income, etc.)
struct VisaTrack: Codable, Identifiable, Hashable {
    let id: String
    let destinationId: String
    let name: String
    let shortName: String
    let description: String
    let requirements: [String]
    let estimatedProcessingTime: String?
    let officialUrl: String?

    init(
        id: String,
        destinationId: String,
        name: String,
        shortName: String,
        description: String,
        requirements: [String] = [],
        estimatedProcessingTime: String? = nil,
        officialUrl: String? = nil
    ) {
        self.id = id
        self.destinationId = destinationId
        self.name = name
        self.shortName = shortName
        self.description = description
        self.requirements = requirements
        self.estimatedProcessingTime = estimatedProcessingTime
        self.officialUrl = officialUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case destinationId = "destination_id"
        case name
        case shortName = "short_name"
        case description
        case requirements
        case estimatedProcessingTime = "estimated_processing_time"
        case officialUrl = "official_url"
    }
}
