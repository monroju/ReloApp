import Foundation
import Combine

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedCountry: String?
    @Published var showCompleted = false
    @Published var filterDueThisWeek = false

    private let repo = TaskRepository.shared
    private var cancellables = Set<AnyCancellable>()

    var tasks: [TaskItem] {
        repo.tasks
    }

    var filteredTasks: [TaskItem] {
        var result = tasks

        if !searchQuery.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }

        if let country = selectedCountry {
            result = result.filter { $0.countryId == country }
        }

        if !showCompleted {
            result = result.filter { !$0.completed }
        }

        if filterDueThisWeek {
            let (start, end) = weekBounds()
            result = result.filter { task in
                guard let due = task.dueAt else { return false }
                return due >= start && due <= end
            }
        }

        return result
    }

    var tasksByPhase: [(String, [TaskItem])] {
        let grouped = Dictionary(grouping: filteredTasks) { task in
            Phases.categoryToPhaseId(task.category)
        }
        return Phases.allPhases.compactMap { phase in
            guard let tasks = grouped[phase.id], !tasks.isEmpty else { return nil }
            return (phase.displayName, tasks)
        }
    }

    func startListening() {
        repo.startListening()
    }

    func toggleCompleted(_ task: TaskItem) {
        Task { try? await repo.toggleCompleted(task) }
    }

    func setDue(_ task: TaskItem, date: Date?) {
        Task { try? await repo.setDue(task, date: date) }
    }

    func addToCalendar(_ task: TaskItem) {
        Task { try? await EventsRepository.shared.addEventFromTask(task) }
    }

    private func weekBounds() -> (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? now
        return (start, end)
    }
}
