import Foundation
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore

/// Manages user document uploads/downloads via Firebase Storage and the
/// Wizard-generated documentSlots that organize them by visa track.
final class DocumentsRepository: ObservableObject {
    static let shared = DocumentsRepository()

    @Published var documents: [UserDocument] = []
    @Published var slots: [DocumentSlot] = []

    private lazy var db = Firestore.firestore()
    private lazy var storage = Storage.storage()
    private var listener: ListenerRegistration?
    private var slotsListener: ListenerRegistration?

    private init() {}

    private var docsCollection: CollectionReference? {
        guard FirebaseApp.app() != nil,
              !AuthService.shared.isGuest,
              let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("documents")
    }

    private var slotsCollection: CollectionReference? {
        guard FirebaseApp.app() != nil,
              !AuthService.shared.isGuest,
              let uid = AuthService.shared.uid else { return nil }
        return db.collection("users").document(uid).collection("documentSlots")
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

        startListeningSlots()
    }

    private func startListeningSlots() {
        guard let col = slotsCollection else {
            slots = []
            return
        }
        slotsListener = col.addSnapshotListener { [weak self] snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            DispatchQueue.main.async {
                self?.slots = docs.compactMap { doc in
                    var s = try? doc.data(as: DocumentSlot.self)
                    s?.id = doc.documentID
                    return s
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        slotsListener?.remove()
        slotsListener = nil
    }

    // MARK: - Documents

    /// Legacy upload — used by the "Other uploads" section. Returns the new
    /// Firestore document id so callers that need to link can do so.
    @discardableResult
    func upload(data: Data, fileName: String,
                forSlotKey slotKey: String? = nil,
                forSlotTrackId slotTrackId: String? = nil) async throws -> String? {
        guard let uid = AuthService.shared.uid, let col = docsCollection else { return nil }
        let path = "users/\(uid)/documents/\(fileName)"
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()

        var payload: [String: Any] = [
            "name": fileName,
            "downloadUrl": url.absoluteString,
            "path": path
        ]
        if let k = slotKey { payload["slotKey"] = k }
        if let t = slotTrackId { payload["slotTrackId"] = t }

        let docRef = try await col.addDocument(data: payload)
        return docRef.documentID
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

    // MARK: - Document slots (Item 21)

    /// Idempotent insert — keying by (visaTrackId, key) means re-running the
    /// wizard upserts rather than duplicating. Existing status + uploadedDocumentId
    /// are preserved on re-run because we set with merge.
    func upsertSlots(_ slots: [DocumentSlot]) async throws {
        guard let col = slotsCollection else { return }
        let batch = db.batch()
        for slot in slots {
            let docRef = col.document(slot.firestoreId)
            // Persist a payload that does NOT clobber status/uploadedDocumentId on re-run.
            var payload: [String: Any] = [
                "key": slot.key,
                "label": slot.label,
                "countryId": slot.countryId,
                "visaTrackId": slot.visaTrackId,
                "generatedAt": Timestamp(date: slot.generatedAt)
            ]
            if let d = slot.slotDescription { payload["slotDescription"] = d }
            // Foundation Wave 1 — persist enriched slot metadata. All optional,
            // so existing slots in Firestore don't break when we merge these in.
            if let w = slot.whereToObtain { payload["whereToObtain"] = w }
            if let v = slot.validityPeriod { payload["validityPeriod"] = v }
            if let a = slot.apostilleRequired { payload["apostilleRequired"] = a }
            if let s = slot.swornTranslationRequired { payload["swornTranslationRequired"] = s }
            if let t = slot.sourceTaskRuleKey { payload["sourceTaskRuleKey"] = t }
            // Status defaults to .pending on FIRST write; on merge we keep existing.
            payload["status"] = SlotStatus.pending.rawValue
            batch.setData(payload, forDocument: docRef, merge: true)
        }
        try await batch.commit()
    }

    /// Attach an uploaded document to a slot — flips status to .uploaded and
    /// stores the uploaded document's id.
    func attachUpload(slotId: String, documentId: String) async throws {
        guard let col = slotsCollection else { return }
        try await col.document(slotId).updateData([
            "status": SlotStatus.uploaded.rawValue,
            "uploadedDocumentId": documentId
        ])
        IntegrationEvents.shared.publish(
            .documentSlotStatusChanged(slotId: slotId, status: .uploaded)
        )
    }

    /// Detach a previously attached document — flips status back to .pending.
    /// (The uploaded UserDocument itself is left intact; user can re-attach or
    /// keep it as a free document.)
    func detachUpload(slotId: String) async throws {
        guard let col = slotsCollection else { return }
        try await col.document(slotId).updateData([
            "status": SlotStatus.pending.rawValue,
            "uploadedDocumentId": FieldValue.delete()
        ])
        IntegrationEvents.shared.publish(
            .documentSlotStatusChanged(slotId: slotId, status: .pending)
        )
    }
}
