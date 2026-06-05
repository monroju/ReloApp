import Foundation
import Combine

/// Builds the `UserMoveState` read-model from the live stores and derives the
/// readiness score + insight cards via the pure `CoPilotEngine`. Rebuilds when
/// task/document/visa data changes and on demand (the UserDefaults-backed
/// inputs — cost, household, cita — are re-read each rebuild).
@MainActor
final class CoPilotViewModel: ObservableObject {
    @Published private(set) var state = UserMoveState()
    @Published private(set) var readiness = CoPilotEngine.readiness(UserMoveState())
    @Published private(set) var cards: [InsightCard] = []

    private let taskRepo = TaskRepository.shared
    private let docRepo = DocumentsRepository.shared
    private let destRepo = DestinationRepository.shared
    private var cancellables = Set<AnyCancellable>()

    func start() {
        taskRepo.startListening()
        docRepo.startListening()

        // Rebuild whenever any observed live source changes. Hop to the main
        // actor explicitly so the @MainActor `rebuild()` is always called safely
        // regardless of which thread the publisher emits on.
        let rebuildOnMain: () -> Void = { [weak self] in
            Task { @MainActor in self?.rebuild() }
        }
        taskRepo.$tasks.dropFirst().sink { _ in rebuildOnMain() }.store(in: &cancellables)
        docRepo.$documents.dropFirst().sink { _ in rebuildOnMain() }.store(in: &cancellables)
        docRepo.$slots.dropFirst().sink { _ in rebuildOnMain() }.store(in: &cancellables)
        destRepo.$activeVisaTrackId.dropFirst().sink { _ in rebuildOnMain() }.store(in: &cancellables)
        destRepo.$activeDestinationId.dropFirst().sink { _ in rebuildOnMain() }.store(in: &cancellables)

        rebuild()
    }

    /// Re-read everything and recompute. Call on appear so UserDefaults-backed
    /// inputs (calculator cost, cita monitors, household) pick up changes made on
    /// other screens.
    func rebuild() {
        state = buildState()
        readiness = CoPilotEngine.readiness(state)
        cards = CoPilotEngine.generateInsightCards(state)
    }

    private func buildState() -> UserMoveState {
        var s = UserMoveState()

        // Visa + country
        s.selectedCountryName = DestinationConfig.getDestination(destRepo.activeDestinationId)?.name
        s.selectedVisa = VisaCatalog.all.first { $0.wizardTrackId == destRepo.activeVisaTrackId }

        // Calculator / target / household
        s.targetMoveDate = MoveProfileStore.targetMoveDate
        s.estimatedMonthlyCostEUR = MoveProfileStore.estimatedMonthlyCostEUR
        s.estimateCity = MoveProfileStore.costCity
        s.dependents = MoveProfileStore.dependents

        // Tasks
        let tasks = taskRepo.tasks
        s.taskTotal = tasks.count
        s.taskCompleted = tasks.filter(\.completed).count
        s.earliestTaskDate = tasks.compactMap(\.createdAt).min()

        // Documents — counts + the specific docs nearing/past expiry.
        applyDocumentSummary(&s)

        // Cita monitors (active = reminders enabled)
        let monitors = CitaMonitorStore.load().filter(\.remindersEnabled)
        s.activeCitaMonitors = monitors.count
        if let first = monitors.first {
            s.citaSample = first.area.isEmpty ? first.type.label : "\(first.type.label) · \(first.area)"
        }
        return s
    }

    /// Mirrors DocumentsViewModel.vaultSummary so the dashboard and the vault
    /// header agree, and additionally collects the expiring/expired documents for
    /// per-document gap cards.
    private func applyDocumentSummary(_ s: inout UserMoveState) {
        let documents = docRepo.documents
        let slots = docRepo.slots
        var countedDocIds = Set<String>()

        func classify(_ doc: UserDocument) {
            if doc.isExpired { s.docExpired += 1 }
            else if doc.isExpiringSoon { s.docExpiringSoon += 1 }
            else { s.docComplete += 1 }
            if let days = doc.daysUntilExpiration, doc.isExpired || doc.isExpiringSoon {
                s.expiringDocuments.append(.init(name: doc.name, daysUntil: days))
            }
            // Apostille/translation outstanding — an operational signal independent
            // of expiry. Don't double-count expired docs (renew first).
            if doc.hasOutstandingPrep && !doc.isExpired {
                s.docPrepPending += 1
                s.prepDocuments.append(doc.name)
            }
        }

        for slot in slots {
            switch slot.status {
            case .pending:
                s.docMissing += 1
            case .uploaded:
                if let docId = slot.uploadedDocumentId,
                   let doc = documents.first(where: { $0.id == docId }) {
                    countedDocIds.insert(doc.id)
                    classify(doc)
                } else {
                    s.docComplete += 1
                }
            }
        }
        for doc in documents where !countedDocIds.contains(doc.id) {
            guard doc.expirationDate != nil || doc.hasOutstandingPrep else { continue }
            classify(doc)
        }
    }
}
