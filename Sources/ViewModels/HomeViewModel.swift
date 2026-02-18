import Foundation
import Observation

// MARK: - HomeViewModel

@Observable
final class HomeViewModel {

    // MARK: - User Profile

    var displayName: String = ""
    var email: String = ""
    var avatarUrl: String? = nil

    // MARK: - Destination State

    var destination: DestinationCountry? = nil
    var userDestination: UserDestination? = nil
    var activeVisaTrack: VisaTrack? = nil

    // MARK: - Dashboard Data

    var progressStats: ProgressStats = ProgressStats()
    var phaseGroups: [TaskPhaseGroup] = []
    var upcomingEvents: [EventItem] = []
    var recentDocuments: [Document] = []

    // MARK: - UI State

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showProfileSheet: Bool = false

    // MARK: - Computed Properties

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var destinationSummary: String? {
        guard let dest = destination, let track = activeVisaTrack else { return nil }
        return "\(dest.flagEmoji) \(dest.name) — \(track.shortName)"
    }

    var totalPhasesCompleted: Int {
        phaseGroups.filter { $0.completedCount == $0.totalCount && $0.totalCount > 0 }.count
    }

    var nextDeadlineEvent: EventItem? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return upcomingEvents
            .filter { $0.dateMillis > now }
            .sorted { $0.dateMillis < $1.dateMillis }
            .first
    }

    // MARK: - Actions

    func loadDashboard() {
        isLoading = true
        errorMessage = nil
        // Placeholder: Wire to your Firestore/network layer.
        // Call loadDestination(), loadTasks(), loadEvents(), etc.
        isLoading = false
    }

    func selectVisaTrack(_ track: VisaTrack) {
        activeVisaTrack = track
        reloadTasksForActiveTrack()
    }

    func toggleTaskCompleted(_ task: DestinationTask) {
        guard let groupIdx = phaseGroups.firstIndex(where: { $0.phaseId == task.phaseId }),
              let taskIdx = phaseGroups[groupIdx].tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        let toggled = DestinationTask(
            id: task.id,
            destinationId: task.destinationId,
            visaTrackId: task.visaTrackId,
            phaseId: task.phaseId,
            title: task.title,
            description: task.description,
            category: task.category,
            completed: !task.completed,
            dueAt: task.dueAt,
            createdAt: task.createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000),
            seeded: task.seeded,
            seedKey: task.seedKey,
            links: task.links,
            order: task.order
        )

        var updatedTasks = phaseGroups[groupIdx].tasks
        updatedTasks[taskIdx] = toggled

        let newCompleted = updatedTasks.filter(\.completed).count
        phaseGroups[groupIdx] = TaskPhaseGroup(
            phaseId: phaseGroups[groupIdx].phaseId,
            displayName: phaseGroups[groupIdx].displayName,
            tasks: updatedTasks,
            completedCount: newCompleted,
            totalCount: updatedTasks.count
        )

        recalculateProgress()
    }

    func updateProfile(name: String, email: String) {
        displayName = name
        self.email = email
        showProfileSheet = false
        // Placeholder: persist to Firestore
    }

    // MARK: - Private Helpers

    private func reloadTasksForActiveTrack() {
        // Placeholder: re-fetch tasks filtered by activeVisaTrack?.id
    }

    private func recalculateProgress() {
        let total = phaseGroups.reduce(0) { $0 + $1.totalCount }
        let completed = phaseGroups.reduce(0) { $0 + $1.completedCount }
        let pct = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
        progressStats = ProgressStats(
            totalTasks: total,
            completedTasks: completed,
            percentage: pct
        )
    }
}
