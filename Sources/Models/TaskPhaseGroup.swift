import Foundation

/// Grouping of tasks by phase for UI sections
struct TaskPhaseGroup: Codable, Hashable {
    let phaseId: String
    let displayName: String
    let tasks: [DestinationTask]
    let completedCount: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case phaseId = "phase_id"
        case displayName = "display_name"
        case tasks
        case completedCount = "completed_count"
        case totalCount = "total_count"
    }
}
