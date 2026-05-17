import Foundation
import FirebaseCore
import FirebaseFirestore
import Combine

/// Manages user tasks in Firestore, with local fallback for guest mode.
final class TaskRepository: ObservableObject {
    static let shared = TaskRepository()

    @Published var tasks: [TaskItem] = []

    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// In-memory store used when the user is a guest (no Firestore access).
    private var localTasks: [TaskItem] = []
    private var localIdCounter = 0

    private var isGuest: Bool { AuthService.shared.isGuest }

    /// Guards autoSeedFreeCountries against re-running on every snapshot.
    private var freeSeedAttempted = false

    private init() {}

    private var tasksCollection: CollectionReference? {
        guard FirebaseApp.app() != nil, !isGuest, let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("tasks")
    }

    func startListening() {
        stopListening()

        // Guest mode — use local in-memory tasks
        if isGuest {
            tasks = localTasks
            Task { await autoSeedFreeCountries() }
            return
        }

        guard let col = tasksCollection else {
            tasks = []
            return
        }

        listener = col.order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self.tasks = docs.compactMap { doc in
                        var task = try? doc.data(as: TaskItem.self)
                        task?.id = doc.documentID
                        return task
                    }
                }
                // First snapshot tells us auth is ready — kick off seed for
                // free countries (Spain, Canada) if they have no tasks yet.
                Task { await self.autoSeedFreeCountries() }
            }
    }

    /// Seeds Spain + Canada tasks (the free countries) once per app session,
    /// after auth + Firestore are confirmed available. Idempotent: a second
    /// call is a no-op once `freeSeedAttempted` is true.
    private func autoSeedFreeCountries() async {
        if freeSeedAttempted { return }
        freeSeedAttempted = true
        await autoSeedIfNeeded(for: "spain")
        await autoSeedIfNeeded(for: "canada")
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addTask(_ task: TaskItem) async throws {
        if isGuest {
            localIdCounter += 1
            var t = task
            t.id = "local_\(localIdCounter)"
            t.createdAt = Date()
            localTasks.append(t)
            await MainActor.run { tasks = localTasks }
            return
        }
        guard let col = tasksCollection else { return }
        var data: [String: Any] = [
            "title": task.title,
            "completed": task.completed,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let desc = task.description { data["description"] = desc }
        if let cat = task.category { data["category"] = cat }
        if let dueAt = task.dueAt { data["dueAt"] = Timestamp(date: dueAt) }
        if let cityId = task.cityId { data["cityId"] = cityId }
        if let cityName = task.cityName { data["cityName"] = cityName }
        if let countryId = task.countryId { data["countryId"] = countryId }
        try await col.addDocument(data: data)
    }

    func toggleCompleted(_ task: TaskItem) async throws {
        if isGuest {
            if let idx = localTasks.firstIndex(where: { $0.id == task.id }) {
                localTasks[idx].completed.toggle()
                await MainActor.run { tasks = localTasks }
            }
            return
        }
        guard let col = tasksCollection, let id = task.id else { return }
        try await col.document(id).updateData(["completed": !task.completed])
    }

    func setDue(_ task: TaskItem, date: Date?) async throws {
        if isGuest {
            if let idx = localTasks.firstIndex(where: { $0.id == task.id }) {
                localTasks[idx].dueAt = date
                await MainActor.run { tasks = localTasks }
            }
            return
        }
        guard let col = tasksCollection, let id = task.id else { return }
        if let date = date {
            try await col.document(id).updateData(["dueAt": Timestamp(date: date)])
        } else {
            try await col.document(id).updateData(["dueAt": FieldValue.delete()])
        }
    }

    func setNotes(_ task: TaskItem, notes: String?) async throws {
        if isGuest {
            if let idx = localTasks.firstIndex(where: { $0.id == task.id }) {
                localTasks[idx].notes = notes
                await MainActor.run { tasks = localTasks }
            }
            return
        }
        guard let col = tasksCollection, let id = task.id else { return }
        if let notes = notes, !notes.isEmpty {
            try await col.document(id).updateData(["notes": notes])
        } else {
            try await col.document(id).updateData(["notes": FieldValue.delete()])
        }
    }

    func deleteTask(_ task: TaskItem) async throws {
        if isGuest {
            localTasks.removeAll { $0.id == task.id }
            await MainActor.run { tasks = localTasks }
            return
        }
        guard let col = tasksCollection, let id = task.id else { return }
        try await col.document(id).delete()
    }

    /// Auto-seeds tasks for a country if none exist yet for that country.
    ///
    /// Source of truth: actual task data (Firestore docs for signed-in users,
    /// localTasks for guests). No UserDefaults flag — a previously-failed seed
    /// attempt (e.g. auth not ready) won't poison future runs.
    /// Safe to call repeatedly: if tasks already exist for the country, this no-ops.
    func autoSeedIfNeeded(for countryId: String) async {
        if isGuest {
            // Guest: check in-memory store
            if localTasks.contains(where: { $0.countryId == countryId }) { return }
        } else {
            // Authenticated: need a valid Firestore collection. If auth isn't
            // ready yet (uid still nil), bail silently — the caller will retry
            // once the listener fires.
            guard let col = tasksCollection else { return }
            let existing = try? await col
                .whereField("countryId", isEqualTo: countryId)
                .limit(to: 1)
                .getDocuments()
            if let docs = existing?.documents, !docs.isEmpty { return }
        }

        // Load seed JSON
        let fileName = "\(countryId)_tasks"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "Seeds")
                ?? Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seedTasks = try? JSONDecoder().decode([AutoSeedTask].self, from: data),
              !seedTasks.isEmpty else {
            return
        }

        let taskItems = seedTasks.map { seed in
            TaskItem(
                title: seed.title,
                description: seed.description,
                category: Phases.getDisplayName(seed.phaseId),
                countryId: countryId,
                links: seed.links?.map { AppLink(label: $0.label, url: $0.url) }
            )
        }

        try? await insertTasks(taskItems)
    }

    func insertTasks(_ tasks: [TaskItem]) async throws {
        if isGuest {
            for task in tasks {
                localIdCounter += 1
                var t = task
                t.id = "local_\(localIdCounter)"
                t.createdAt = Date()
                localTasks.append(t)
            }
            await MainActor.run { self.tasks = localTasks }
            return
        }
        guard let col = tasksCollection else { return }
        let batch = db.batch()
        for task in tasks {
            let ref = col.document()
            var data: [String: Any] = [
                "title": task.title,
                "completed": false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            if let cat = task.category { data["category"] = cat }
            if let cityId = task.cityId { data["cityId"] = cityId }
            if let cityName = task.cityName { data["cityName"] = cityName }
            if let countryId = task.countryId { data["countryId"] = countryId }
            batch.setData(data, forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: - Auto Seed JSON Model

    private struct AutoSeedTask: Codable {
        let title: String
        let description: String?
        let phaseId: String
        let visaTrackId: String?
        let order: Int?
        let links: [AutoSeedLink]?
    }

    private struct AutoSeedLink: Codable {
        let label: String?
        let url: String?
    }

    func starterTasks(for cityId: String, cityName: String, countryId: String) -> [TaskItem] {
        let countryLabel: String
        switch countryId {
        case "portugal": countryLabel = "Portugal"
        case "mexico": countryLabel = "Mexico"
        default: countryLabel = "Spain"
        }
        return [
            TaskItem(title: "Research neighborhoods in \(cityName)", category: "Phase 1: Research & Planning", cityId: cityId, cityName: cityName, countryId: countryId),
            TaskItem(title: "Compare rentals and schools in \(cityName)", category: "Phase 1: Research & Planning", cityId: cityId, cityName: cityName, countryId: countryId),
            TaskItem(title: "Shortlist 10 apartments in \(cityName)", category: "Phase 3: Pre-Move Preparations", cityId: cityId, cityName: cityName, countryId: countryId),
            TaskItem(title: "Book 3-5 viewings in \(cityName) (or request video tours)", category: "Phase 3: Pre-Move Preparations", cityId: cityId, cityName: cityName, countryId: countryId),
            TaskItem(title: "Research visa requirements for \(countryLabel)", category: "Phase 2: Documentation", cityId: cityId, cityName: cityName, countryId: countryId),
        ]
    }
}
