import Foundation

// MARK: - DestinationCountry

/// Represents a destination country for relocation.
/// This is the top-level entity that contains visa tracks and tasks.
struct DestinationCountry: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let flagEmoji: String
    let region: String
    let description: String
    let visaTracks: [VisaTrack]
    let defaultVisaTrackId: String
    let seedVersion: Int
    let officialImmigrationUrl: String?

    init(
        id: String,
        name: String,
        flagEmoji: String,
        region: String,
        description: String,
        visaTracks: [VisaTrack],
        defaultVisaTrackId: String,
        seedVersion: Int = 1,
        officialImmigrationUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.flagEmoji = flagEmoji
        self.region = region
        self.description = description
        self.visaTracks = visaTracks
        self.defaultVisaTrackId = defaultVisaTrackId
        self.seedVersion = seedVersion
        self.officialImmigrationUrl = officialImmigrationUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case flagEmoji = "flag_emoji"
        case region
        case description
        case visaTracks = "visa_tracks"
        case defaultVisaTrackId = "default_visa_track_id"
        case seedVersion = "seed_version"
        case officialImmigrationUrl = "official_immigration_url"
    }
}

// MARK: - UserDestination

/// User's destination selection stored in Firestore.
/// Path: /users/{uid}/destinations/{destinationId}
struct UserDestination: Codable, Hashable {
    let destinationId: String
    let countryName: String
    let activeVisaTrackId: String
    let createdAt: Int64
    let lastSeededAt: Int64?
    let seedVersion: Int

    init(
        destinationId: String = "",
        countryName: String = "",
        activeVisaTrackId: String = "",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastSeededAt: Int64? = nil,
        seedVersion: Int = 0
    ) {
        self.destinationId = destinationId
        self.countryName = countryName
        self.activeVisaTrackId = activeVisaTrackId
        self.createdAt = createdAt
        self.lastSeededAt = lastSeededAt
        self.seedVersion = seedVersion
    }

    enum CodingKeys: String, CodingKey {
        case destinationId = "destination_id"
        case countryName = "country_name"
        case activeVisaTrackId = "active_visa_track_id"
        case createdAt = "created_at"
        case lastSeededAt = "last_seeded_at"
        case seedVersion = "seed_version"
    }
}

// MARK: - DestinationTask

/// Extension of the existing Task model with destination scoping.
struct DestinationTask: Codable, Identifiable, Hashable {
    let id: String?
    let destinationId: String
    let visaTrackId: String
    let phaseId: String
    let title: String
    let description: String?
    let category: String?
    let completed: Bool
    let dueAt: Int64?
    let createdAt: Int64?
    let updatedAt: Int64?
    let seeded: Bool
    /// Deterministic key for deduplication
    let seedKey: String?
    let links: [Link]?
    /// For sorting within phase
    let order: Int

    init(
        id: String? = nil,
        destinationId: String = "",
        visaTrackId: String = "",
        phaseId: String = "",
        title: String = "",
        description: String? = nil,
        category: String? = "General",
        completed: Bool = false,
        dueAt: Int64? = nil,
        createdAt: Int64? = nil,
        updatedAt: Int64? = nil,
        seeded: Bool = false,
        seedKey: String? = nil,
        links: [Link]? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.destinationId = destinationId
        self.visaTrackId = visaTrackId
        self.phaseId = phaseId
        self.title = title
        self.description = description
        self.category = category
        self.completed = completed
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.seeded = seeded
        self.seedKey = seedKey
        self.links = links
        self.order = order
    }

    /// Convert to legacy TaskModel format for backward compatibility
    func toTaskModel() -> TaskModel {
        TaskModel(
            id: id,
            title: title,
            description: description,
            category: category,
            completed: completed,
            dueAt: dueAt,
            createdAt: createdAt,
            links: links
        )
    }

    /// Generate a deterministic seed key for deduplication
    static func generateSeedKey(
        destinationId: String,
        visaTrackId: String,
        phaseId: String,
        title: String
    ) -> String {
        let slug = title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .prefix(50)
        return "\(destinationId)::\(visaTrackId)::\(phaseId)::\(slug)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case destinationId = "destination_id"
        case visaTrackId = "visa_track_id"
        case phaseId = "phase_id"
        case title
        case description
        case category
        case completed
        case dueAt = "due_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case seeded
        case seedKey = "seed_key"
        case links
        case order
    }
}
