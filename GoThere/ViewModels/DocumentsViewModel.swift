import Foundation
import Combine

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var documents: [UserDocument] = []
    @Published var slots: [DocumentSlot] = []
    @Published var isUploading = false
    @Published var errorMessage: String?

    private let repo = DocumentsRepository.shared
    private var cancellables = Set<AnyCancellable>()

    func startListening() {
        repo.startListening()
        repo.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: &$documents)
        repo.$slots
            .receive(on: DispatchQueue.main)
            .assign(to: &$slots)
    }

    func upload(data: Data, fileName: String) {
        isUploading = true
        errorMessage = nil
        NotificationManager.shared.requestPermissionIfNeeded()
        Task {
            do {
                let docId = try await repo.upload(data: data, fileName: fileName)
                if let docId { scheduleExpiryAfterUpload(docId: docId, fileName: fileName) }
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }

    /// Upload + attach to a specific slot in one shot. The new UserDocument
    /// gets the slotKey/slotTrackId stamped on it for traceability.
    func uploadForSlot(_ slot: DocumentSlot, data: Data, fileName: String) {
        isUploading = true
        errorMessage = nil
        NotificationManager.shared.requestPermissionIfNeeded()
        Task {
            do {
                let docId = try await repo.upload(
                    data: data, fileName: fileName,
                    forSlotKey: slot.key, forSlotTrackId: slot.visaTrackId
                )
                if let docId {
                    try await repo.attachUpload(slotId: slot.firestoreId, documentId: docId)
                    scheduleExpiryAfterUpload(docId: docId, fileName: fileName)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }

    /// Schedule local expiry reminders right after upload using the same lookup
    /// the repository used to stamp the document, so reminders are live without
    /// waiting on a Firestore snapshot round-trip.
    private func scheduleExpiryAfterUpload(docId: String, fileName: String) {
        guard let rule = DocumentValidityRules.match(fileName: fileName),
              let exp = DocumentValidityRules.expiration(from: Date(), validityDays: rule.validityDays)
        else { return }
        let doc = UserDocument(id: docId, name: rule.canonicalName, expirationDate: exp)
        NotificationManager.shared.scheduleDocumentExpiry(doc)
    }

    /// Persist edited metadata and (re)schedule that document's reminders.
    func updateMeta(_ doc: UserDocument) {
        Task {
            do {
                try await repo.updateDocumentMeta(doc)
                NotificationManager.shared.scheduleDocumentExpiry(doc)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Re-evaluate all reminders against current data. Call on foreground / when
    /// the document list loads. Guarded so a pre-load empty snapshot can't wipe
    /// already-scheduled reminders (the Firestore listener delivers `[]` before
    /// the first real snapshot on cold start).
    func refreshNotifications() {
        guard !documents.isEmpty else { return }
        NotificationManager.shared.rescheduleAllDocuments(documents)
    }

    /// Replace a document's underlying file, then reschedule its reminders
    /// against the recomputed expiration.
    func replaceFile(_ doc: UserDocument, data: Data, fileName: String) {
        isUploading = true
        Task {
            do {
                try await repo.replaceFile(doc, data: data, fileName: fileName)
                if let days = doc.validityPeriodDays,
                   let exp = DocumentValidityRules.expiration(from: Date(), validityDays: days) {
                    var updated = doc
                    updated.expirationDate = exp
                    NotificationManager.shared.scheduleDocumentExpiry(updated)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }

    func detachSlot(_ slot: DocumentSlot) {
        Task {
            do {
                try await repo.detachUpload(slotId: slot.firestoreId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteDocument(_ doc: UserDocument) {
        NotificationManager.shared.cancelDocumentExpiry(documentId: doc.id)
        Task {
            do {
                try await repo.deleteDocument(doc)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Slot view helpers

    /// Slots grouped by visaTrackId for the "Documents you need" section.
    var slotsByTrack: [(trackId: String, slots: [DocumentSlot])] {
        let grouped = Dictionary(grouping: slots, by: { $0.visaTrackId })
        return grouped
            .map { (trackId: $0.key, slots: $0.value.sorted { $0.label < $1.label }) }
            .sorted { $0.trackId < $1.trackId }
    }

    /// "Other uploads" — documents that aren't attached to any slot, sorted by
    /// urgency (expired/expiring first) then name.
    var unattachedDocuments: [UserDocument] {
        documents
            .filter { $0.slotKey == nil }
            .sorted { lhs, rhs in
                if lhs.urgency != rhs.urgency { return lhs.urgency < rhs.urgency }
                let l = lhs.daysUntilExpiration ?? Int.max
                let r = rhs.daysUntilExpiration ?? Int.max
                if l != r { return l < r }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func document(forSlot slot: DocumentSlot) -> UserDocument? {
        guard let docId = slot.uploadedDocumentId else { return nil }
        return documents.first { $0.id == docId }
    }

    // MARK: - Vault summary (Differentiation Wave)

    /// Status counts surfaced in the vault header. `complete` = uploaded + valid
    /// (no expiry concern, no outstanding apostille/translation); `expiringSoon`
    /// = within the nearest reminder window; `expired` = past expiry; `missing` =
    /// required wizard slots with nothing uploaded.
    struct VaultSummary {
        var complete = 0
        var expiringSoon = 0
        var expired = 0
        var missing = 0
        var hasAnything: Bool { complete + expiringSoon + expired + missing > 0 }
    }

    var vaultSummary: VaultSummary {
        var s = VaultSummary()
        var countedDocIds = Set<String>()

        // Required wizard slots drive missing / (attached doc) bands.
        for slot in slots {
            switch slot.status {
            case .pending:
                s.missing += 1
            case .uploaded:
                if let doc = document(forSlot: slot) {
                    countedDocIds.insert(doc.id)
                    classify(doc, into: &s)
                } else {
                    s.complete += 1   // uploaded flag set but doc record gone
                }
            }
        }

        // Loose uploads that carry an expiration date also count toward the bands.
        for doc in documents where !countedDocIds.contains(doc.id) {
            guard doc.expirationDate != nil || doc.hasOutstandingPrep else { continue }
            classify(doc, into: &s)
        }
        return s
    }

    private func classify(_ doc: UserDocument, into s: inout VaultSummary) {
        if doc.isExpired { s.expired += 1 }
        else if doc.isExpiringSoon { s.expiringSoon += 1 }
        else { s.complete += 1 }
    }
}
