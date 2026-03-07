import Foundation
import FirebaseFirestore
import Combine

/// Manages user destination selections and destination-scoped tasks.
final class DestinationRepository: ObservableObject {
    static let shared = DestinationRepository()

    @Published var activeDestinationId: String = DestinationConfig.spain
    @Published var activeVisaTrackId: String = DestinationConfig.spainNonLucrative
    @Published var destinationTasks: [DestinationTask] = []

    private lazy var db = Firestore.firestore()
    private var taskListener: ListenerRegistration?

    private init() {}

    private var userDoc: DocumentReference? {
        guard let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid)
    }

    func loadActiveDestination() async {
        guard let doc = userDoc else { return }
        do {
            let snapshot = try await doc.getDocument()
            if let data = snapshot.data() {
                await MainActor.run {
                    self.activeDestinationId = data["activeDestinationId"] as? String ?? DestinationConfig.spain
                    self.activeVisaTrackId = data["activeVisaTrackId"] as? String ?? DestinationConfig.spainNonLucrative
                }
            }
            // Seed tasks for the active destination if needed
            await seedDestinationIfNeeded(activeDestinationId)
        } catch {
            print("Error loading active destination: \(error)")
        }
    }

    func setActiveDestination(_ destinationId: String) async {
        guard let doc = userDoc else { return }
        let defaultTrack = DestinationConfig.getDefaultVisaTrack(destinationId: destinationId)?.id ?? ""
        await MainActor.run {
            self.activeDestinationId = destinationId
            self.activeVisaTrackId = defaultTrack
        }
        try? await doc.setData([
            "activeDestinationId": destinationId,
            "activeVisaTrackId": defaultTrack
        ], merge: true)
        // Seed tasks for this destination if needed
        await seedDestinationIfNeeded(destinationId)
        startListeningTasks()
    }

    func setActiveVisaTrack(_ trackId: String) async {
        guard let doc = userDoc else { return }
        await MainActor.run { self.activeVisaTrackId = trackId }
        try? await doc.setData(["activeVisaTrackId": trackId], merge: true)
    }

    func startListeningTasks() {
        stopListeningTasks()
        guard let uid = AuthService.shared.uid else { return }

        let col = db.collection("users").document(uid)
            .collection("destinations").document(activeDestinationId)
            .collection("tasks")

        taskListener = col.order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.destinationTasks = docs.compactMap { doc in
                        var task = try? doc.data(as: DestinationTask.self)
                        task?.id = doc.documentID
                        return task
                    }
                }
            }
    }

    func stopListeningTasks() {
        taskListener?.remove()
        taskListener = nil
    }

    // MARK: - Seed Tasks

    /// Seeds destination tasks from bundled JSON if the destination has no tasks yet.
    func seedDestinationIfNeeded(_ destinationId: String) async {
        guard let uid = AuthService.shared.uid else { return }

        let tasksCol = db.collection("users").document(uid)
            .collection("destinations").document(destinationId)
            .collection("tasks")

        do {
            // Check if tasks already exist
            let existing = try await tasksCol.limit(to: 1).getDocuments()
            guard existing.documents.isEmpty else { return }

            // Load seed JSON from bundle
            guard let seedTasks = Self.loadSeedJSON(for: destinationId) else {
                print("No seed file for \(destinationId)")
                return
            }

            // Batch write seed tasks
            let batch = db.batch()
            for seed in seedTasks {
                let ref = tasksCol.document()
                var data: [String: Any] = [
                    "destinationId": destinationId,
                    "visaTrackId": seed.visaTrackId,
                    "phaseId": seed.phaseId,
                    "title": seed.title,
                    "completed": false,
                    "seeded": true,
                    "order": seed.order,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                if let desc = seed.description { data["description"] = desc }
                if let links = seed.links {
                    data["links"] = links.map { ["label": $0.label, "url": $0.url] }
                }
                let seedKey = DestinationTask.generateSeedKey(
                    destinationId: destinationId,
                    visaTrackId: seed.visaTrackId,
                    phaseId: seed.phaseId,
                    title: seed.title
                )
                data["seedKey"] = seedKey
                batch.setData(data, forDocument: ref)
            }
            try await batch.commit()
            print("Seeded \(seedTasks.count) tasks for \(destinationId)")
        } catch {
            print("Error seeding \(destinationId): \(error)")
        }
    }

    private static func loadSeedJSON(for destinationId: String) -> [SeedTask]? {
        // Try with subdirectory first, then without (XcodeGen may flatten resources)
        let url = Bundle.main.url(forResource: "\(destinationId)_tasks", withExtension: "json", subdirectory: "Seeds")
            ?? Bundle.main.url(forResource: "\(destinationId)_tasks", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode([SeedTask].self, from: data)
    }

    func toggleTaskCompleted(_ task: DestinationTask) async throws {
        guard let uid = AuthService.shared.uid, let id = task.id else { return }
        let ref = db.collection("users").document(uid)
            .collection("destinations").document(activeDestinationId)
            .collection("tasks").document(id)
        try await ref.updateData([
            "completed": !task.completed,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func setTaskDueDate(_ task: DestinationTask, date: Date?) async throws {
        guard let uid = AuthService.shared.uid, let id = task.id else { return }
        let ref = db.collection("users").document(uid)
            .collection("destinations").document(activeDestinationId)
            .collection("tasks").document(id)
        if let date = date {
            try await ref.updateData(["dueAt": Timestamp(date: date)])
        } else {
            try await ref.updateData(["dueAt": FieldValue.delete()])
        }
    }
}

// MARK: - Seed Task JSON Model

private struct SeedTask: Decodable {
    let title: String
    let description: String?
    let phaseId: String
    let visaTrackId: String
    let order: Int
    let links: [SeedLink]?
}

private struct SeedLink: Decodable {
    let label: String
    let url: String
}
