import Foundation
import FirebaseFirestore
import Combine

/// Manages user destination selections and destination-scoped tasks.
final class DestinationRepository: ObservableObject {
    static let shared = DestinationRepository()

    @Published var activeDestinationId: String = DestinationConfig.spain
    @Published var activeVisaTrackId: String = DestinationConfig.spainNonLucrative
    @Published var destinationTasks: [DestinationTask] = []

    private let db = Firestore.firestore()
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
