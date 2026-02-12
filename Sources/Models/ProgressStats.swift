import Foundation

/// Overall progress statistics
struct ProgressStats: Codable, Hashable {
    let totalTasks: Int
    let completedTasks: Int
    let percentage: Int

    init(totalTasks: Int = 0, completedTasks: Int = 0, percentage: Int = 0) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.percentage = percentage
    }

    enum CodingKeys: String, CodingKey {
        case totalTasks = "total_tasks"
        case completedTasks = "completed_tasks"
        case percentage
    }
}
