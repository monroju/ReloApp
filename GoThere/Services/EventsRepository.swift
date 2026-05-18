import Foundation
import FirebaseCore
import FirebaseFirestore

/// Manages calendar events in Firestore, with local fallback for guest mode.
final class EventsRepository: ObservableObject {
    static let shared = EventsRepository()

    @Published var events: [EventItem] = []

    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var localEvents: [EventItem] = []
    private var localIdCounter = 0

    private var isGuest: Bool { AuthService.shared.isGuest }

    private init() {}

    private var eventsCollection: CollectionReference? {
        guard FirebaseApp.app() != nil, !isGuest, let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("events")
    }

    func startListening() {
        stopListening()

        if isGuest {
            events = localEvents
            return
        }

        guard let col = eventsCollection else {
            events = []
            return
        }

        listener = col.order(by: "dateMillis")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.events = docs.compactMap { doc in
                        var event = try? doc.data(as: EventItem.self)
                        event?.id = doc.documentID
                        return event
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addEvent(title: String, date: Date, notes: String? = nil, source: String? = nil) async throws {
        if isGuest {
            localIdCounter += 1
            var event = EventItem(
                id: "local_\(localIdCounter)",
                title: title,
                dateMillis: date.timeIntervalSince1970 * 1000,
                notes: notes
            )
            event.source = source
            localEvents.append(event)
            await MainActor.run { events = localEvents }
            return
        }
        guard let col = eventsCollection else { return }
        var data: [String: Any] = [
            "title": title,
            "dateMillis": date.timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let notes = notes { data["notes"] = notes }
        if let source = source { data["source"] = source }
        try await col.addDocument(data: data)
    }

    func addEventFromTask(_ task: TaskItem, source: String = "wizard") async throws {
        guard let dueAt = task.dueAt else { return }
        try await addEvent(title: task.title, date: dueAt, source: source)
    }

    func updateTitle(eventId: String, title: String) async throws {
        if isGuest {
            if let idx = localEvents.firstIndex(where: { $0.id == eventId }) {
                localEvents[idx].title = title
                await MainActor.run { events = localEvents }
            }
            return
        }
        guard let col = eventsCollection else { return }
        try await col.document(eventId).updateData(["title": title])
    }

    func updateDate(eventId: String, date: Date) async throws {
        if isGuest {
            if let idx = localEvents.firstIndex(where: { $0.id == eventId }) {
                localEvents[idx].dateMillis = date.timeIntervalSince1970 * 1000
                await MainActor.run { events = localEvents }
            }
            return
        }
        guard let col = eventsCollection else { return }
        try await col.document(eventId).updateData([
            "dateMillis": date.timeIntervalSince1970 * 1000
        ])
    }

    func deleteEvent(eventId: String) async throws {
        if isGuest {
            localEvents.removeAll { $0.id == eventId }
            await MainActor.run { events = localEvents }
            return
        }
        guard let col = eventsCollection else { return }
        try await col.document(eventId).delete()
    }

    func upcomingEvents(limit: Int = 5) -> [EventItem] {
        let now = Date().timeIntervalSince1970 * 1000
        return events
            .filter { $0.dateMillis >= now }
            .prefix(limit)
            .map { $0 }
    }
}
