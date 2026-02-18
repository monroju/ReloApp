import Foundation
import FirebaseStorage
import FirebaseFirestore

/// Manages user document uploads/downloads via Firebase Storage.
final class DocumentsRepository: ObservableObject {
    static let shared = DocumentsRepository()

    @Published var documents: [UserDocument] = []

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    private init() {}

    private var docsCollection: CollectionReference? {
        guard let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("documents")
    }

    func startListening() {
        stopListening()
        guard let col = docsCollection else {
            documents = []
            return
        }

        listener = col.addSnapshotListener { [weak self] snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            DispatchQueue.main.async {
                self?.documents = docs.compactMap { doc in
                    var d = try? doc.data(as: UserDocument.self)
                    d?.id = doc.documentID
                    return d
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func upload(data: Data, fileName: String) async throws {
        guard let uid = AuthService.shared.uid, let col = docsCollection else { return }
        let path = "users/\(uid)/documents/\(fileName)"
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()

        try await col.addDocument(data: [
            "name": fileName,
            "downloadUrl": url.absoluteString,
            "path": path
        ])
    }

    func deleteDocument(_ doc: UserDocument) async throws {
        guard let col = docsCollection else { return }
        // Delete from Storage
        if !doc.path.isEmpty {
            try? await storage.reference().child(doc.path).delete()
        }
        // Delete from Firestore
        try await col.document(doc.id).delete()
    }
}
