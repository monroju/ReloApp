import Foundation
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

    private init() {}

    private var tasksCollection: CollectionReference? {
        guard !isGuest, let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("tasks")
    }

    func startListening() {
        stopListening()

        // Guest mode — use local in-memory tasks
        if isGuest {
            tasks = localTasks
            return
        }

        guard let col = tasksCollection else {
            tasks = []
            return
        }

        listener = col.order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.tasks = docs.compactMap { doc in
                        var task = try? doc.data(as: TaskItem.self)
                        task?.id = doc.documentID
                        return task
                    }
                }
            }
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

    func deleteTask(_ task: TaskItem) async throws {
        if isGuest {
            localTasks.removeAll { $0.id == task.id }
            await MainActor.run { tasks = localTasks }
            return
        }
        guard let col = tasksCollection, let id = task.id else { return }
        try await col.document(id).delete()
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
