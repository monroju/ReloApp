import Foundation
import Combine

/// Cross-feature event bus. Foundation Wave 1.
///
/// Existing code paths continue to use direct service calls (e.g.
/// `VisaWizardViewModel.saveTasks` fans out to TaskRepository,
/// EventsRepository, DocumentsRepository). This bus is additive: it lets
/// Wave 2+ features subscribe to wizard/task/visa state without modifying
/// the existing fan-out. Subscribers MUST be idempotent — the bus does not
/// guarantee delivery order across subscribers and may replay on cold start
/// for analytics correctness.
final class IntegrationEvents {
    static let shared = IntegrationEvents()

    private let subject = PassthroughSubject<Event, Never>()
    var publisher: AnyPublisher<Event, Never> { subject.eraseToAnyPublisher() }

    private init() {}

    func publish(_ event: Event) {
        subject.send(event)
    }

    enum Event {
        /// User completed the wizard and tasks have been saved.
        case visaCompletion(trackId: String, countryId: String, anchorDate: Date)
        /// User marked a destination task complete or incomplete.
        case visaTaskCompletion(taskId: String, completed: Bool)
        /// Visa catalog data changed (e.g. annual income threshold refresh).
        /// Subscribers like the Cost Calculator should re-render against the
        /// new data without forcing a relaunch.
        case visaUpdate(visaId: String)
        /// Document slot status changed.
        case documentSlotStatusChanged(slotId: String, status: SlotStatus)
    }
}
