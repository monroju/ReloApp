import Foundation
import FirebaseFirestore

/// Manages calendar events in Firestore.
final class EventsRepository: ObservableObject {
    static let shared = EventsRepository()

    @Published var events: [EventItem] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    private var eventsCollection: CollectionReference? {
        guard let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("events")
    }

    func startListening() {
        stopListening()
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

    func addEvent(title: String, date: Date, notes: String? = nil) async throws {
        guard let col = eventsCollection else { return }
        var data: [String: Any] = [
            "title": title,
            "dateMillis": date.timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let notes = notes { data["notes"] = notes }
        try await col.addDocument(data: data)
    }

    func addEventFromTask(_ task: TaskItem) async throws {
        guard let dueAt = task.dueAt else { return }
        try await addEvent(title: task.title, date: dueAt)
    }

    func updateTitle(eventId: String, title: String) async throws {
        guard let col = eventsCollection else { return }
        try await col.document(eventId).updateData(["title": title])
    }

    func updateDate(eventId: String, date: Date) async throws {
        guard let col = eventsCollection else { return }
        try await col.document(eventId).updateData([
            "dateMillis": date.timeIntervalSince1970 * 1000
        ])
    }

    func deleteEvent(eventId: String) async throws {
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
