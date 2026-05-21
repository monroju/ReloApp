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
        // Foundation Wave 1 — fix: previously wizard-emitted events skipped the
        // notification scheduler, so users never got reminders for tasks the
        // wizard generated (only for events they added manually in Calendar).
        // Schedule a 9:00am local-time reminder on the due date.
        var ev = EventItem(
            id: "task_\(task.id ?? UUID().uuidString)",
            title: task.title,
            dateMillis: dueAt.timeIntervalSince1970 * 1000
        )
        ev.source = source
        NotificationManager.shared.scheduleNotification(for: ev)
    }

    /// Persist a milestone event and schedule a push if the rule asks for one.
    /// Uses the milestone's deterministic id (`milestone_<trackId>_<key>`) so
    /// re-running the wizard upserts rather than duplicates.
    func addEventFromMilestone(_ event: EventItem) async throws {
        if isGuest {
            // For guests, dedupe by id locally.
            if let idx = localEvents.firstIndex(where: { $0.id == event.id }) {
                localEvents[idx] = event
            } else {
                localEvents.append(event)
            }
            await MainActor.run { events = localEvents }
            if event.notificationEnabled == true {
                NotificationManager.shared.scheduleNotification(for: event)
            }
            return
        }
        guard let col = eventsCollection else { return }
        var data: [String: Any] = [
            "title": event.title,
            "dateMillis": event.dateMillis,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let notes = event.notes { data["notes"] = notes }
        if let source = event.source { data["source"] = source }
        if let category = event.category { data["category"] = category }
        if let offset = event.daysOffsetFromAnchor { data["daysOffsetFromAnchor"] = offset }
        if let notif = event.notificationEnabled { data["notificationEnabled"] = notif }
        if let trackId = event.visaTrackId { data["visaTrackId"] = trackId }
        // Set with merge so a wizard re-run updates the same doc id rather
        // than creating a duplicate alongside it.
        try await col.document(event.id).setData(data, merge: true)
        if event.notificationEnabled == true {
            NotificationManager.shared.scheduleNotification(for: event)
        } else {
            // If the rule was previously notification-enabled and the user
            // re-ran the wizard with it off, cancel any prior schedule.
            NotificationManager.shared.cancelNotification(eventId: event.id)
        }
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
