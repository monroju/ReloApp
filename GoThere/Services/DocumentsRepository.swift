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
    ///
    /// Differentiation Wave: on upload we best-effort match the filename to a
    /// known document type and pre-fill validity/apostille/translation + a
    /// computed expiration date (issue date assumed = upload date; user can
    /// override in the detail screen). When uploading into a wizard slot we also
    /// inherit that slot's apostille/translation requirements.
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

        // Auto-fill expiration metadata from the validity-rules lookup.
        if let rule = DocumentValidityRules.match(fileName: fileName) {
            payload["category"] = rule.category.rawValue
            payload["validityPeriodDays"] = rule.validityDays
            payload["apostilleRequired"] = rule.apostilleRequired
            payload["swornTranslationRequired"] = rule.swornTranslationRequired
            if let exp = DocumentValidityRules.expiration(from: Date(), validityDays: rule.validityDays) {
                payload["expirationDate"] = Timestamp(date: exp)
            }
            // Auto-suggest a readable name for loose uploads so the vault shows
            // "FBI Background Check" rather than "scan_001.pdf". Slot uploads keep
            // the filename (the slot label already names the requirement). The
            // detail screen lets the user rename either way.
            if slotKey == nil {
                payload["name"] = rule.canonicalName
            }
        }
        // Inherit the slot's explicit requirements (they win over the lookup).
        if let key = slotKey,
           let slot = slots.first(where: { $0.key == key && $0.visaTrackId == slotTrackId }) {
            if let a = slot.apostilleRequired { payload["apostilleRequired"] = a }
            if let s = slot.swornTranslationRequired { payload["swornTranslationRequired"] = s }
        }

        let docRef = try await col.addDocument(data: payload)
        return docRef.documentID
    }

    /// Persist user-edited expiration metadata for a document. Writes only the
    /// editable fields; a `nil` value clears the stored field via FieldValue.delete().
    func updateDocumentMeta(_ doc: UserDocument) async throws {
        guard let col = docsCollection else { return }
        // Helper: optional → value, or a delete sentinel. Keeps the dict literal
        // free of `?? FieldValue.delete()` (which won't type-check across types).
        func orDelete(_ value: Any?) -> Any { value ?? FieldValue.delete() }

        var update: [String: Any] = [
            "name": doc.name,
            "apostilleDone": doc.apostilleDone ?? false,
            "translationDone": doc.translationDone ?? false
        ]
        update["expirationDate"] = orDelete(doc.expirationDate.map { Timestamp(date: $0) })
        update["validityPeriodDays"] = orDelete(doc.validityPeriodDays)
        update["category"] = orDelete(doc.category?.rawValue)
        update["apostilleRequired"] = orDelete(doc.apostilleRequired)
        update["swornTranslationRequired"] = orDelete(doc.swornTranslationRequired)
        update["issuingCountry"] = orDelete(doc.issuingCountry)
        update["notes"] = orDelete(doc.notes)
        if let r = doc.reminderDays { update["reminderDays"] = r }
        try await col.document(doc.id).updateData(update)
    }

    /// Replace the file backing an existing document in place — overwrites the
    /// Storage object, refreshes the download URL, and recomputes the expiration
    /// from today using the document's known validity window. Preserves the
    /// document id and all other metadata.
    func replaceFile(_ doc: UserDocument, data: Data, fileName: String) async throws {
        guard let uid = AuthService.shared.uid, let col = docsCollection else { return }
        let path = doc.path.isEmpty ? "users/\(uid)/documents/\(fileName)" : doc.path
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        var update: [String: Any] = [
            "downloadUrl": url.absoluteString,
            "path": path,
            "name": fileName
        ]
        if let days = doc.validityPeriodDays,
           let exp = DocumentValidityRules.expiration(from: Date(), validityDays: days) {
            update["expirationDate"] = Timestamp(date: exp)
        }
        try await col.document(doc.id).updateData(update)
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
