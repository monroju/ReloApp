import Foundation
import Combine

@MainActor
final class DestinationsViewModel: ObservableObject {
    @Published var activeDestinationId: String = DestinationConfig.spain
    @Published var activeVisaTrackId: String = DestinationConfig.spainNonLucrative
    @Published var destinationTasks: [DestinationTask] = []
    @Published var searchQuery = ""
    @Published var filterPhase: String?
    @Published var showCompleted = false

    private let repo = DestinationRepository.shared
    private var cancellables = Set<AnyCancellable>()

    var activeDestination: DestinationCountry? {
        DestinationConfig.getDestination(activeDestinationId)
    }

    var activeVisaTrack: VisaTrack? {
        DestinationConfig.getVisaTrack(destinationId: activeDestinationId, trackId: activeVisaTrackId)
    }

    var filteredTasks: [DestinationTask] {
        var result = repo.destinationTasks

        if !searchQuery.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }

        if let phase = filterPhase {
            result = result.filter { $0.phaseId == phase }
        }

        if !showCompleted {
            result = result.filter { !$0.completed }
        }

        return result
    }

    var tasksByPhase: [(Phases.PhaseInfo, [DestinationTask])] {
        let grouped = Dictionary(grouping: filteredTasks) { $0.phaseId }
        return Phases.allPhases.compactMap { phase in
            guard let tasks = grouped[phase.id], !tasks.isEmpty else { return nil }
            return (phase, tasks)
        }
    }

    func phaseProgress(_ phaseId: String) -> (completed: Int, total: Int) {
        let tasks = repo.destinationTasks.filter { $0.phaseId == phaseId }
        return (tasks.filter(\.completed).count, tasks.count)
    }

    func loadDestination() async {
        await repo.loadActiveDestination()
        activeDestinationId = repo.activeDestinationId
        activeVisaTrackId = repo.activeVisaTrackId
        repo.startListeningTasks()

        repo.$destinationTasks
            .receive(on: DispatchQueue.main)
            .assign(to: &$destinationTasks)
    }

    func selectDestination(_ id: String) async {
        await repo.setActiveDestination(id)
        activeDestinationId = id
        activeVisaTrackId = repo.activeVisaTrackId
    }

    func selectVisaTrack(_ trackId: String) async {
        await repo.setActiveVisaTrack(trackId)
        activeVisaTrackId = trackId
    }

    func toggleTask(_ task: DestinationTask) {
        Task { try? await repo.toggleTaskCompleted(task) }
    }
}
