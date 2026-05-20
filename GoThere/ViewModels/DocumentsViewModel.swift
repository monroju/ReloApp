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
        Task {
            do {
                _ = try await repo.upload(data: data, fileName: fileName)
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
        Task {
            do {
                let docId = try await repo.upload(
                    data: data, fileName: fileName,
                    forSlotKey: slot.key, forSlotTrackId: slot.visaTrackId
                )
                if let docId {
                    try await repo.attachUpload(slotId: slot.firestoreId, documentId: docId)
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

    /// "Other uploads" — documents that aren't attached to any slot.
    var unattachedDocuments: [UserDocument] {
        documents.filter { $0.slotKey == nil }
    }

    func document(forSlot slot: DocumentSlot) -> UserDocument? {
        guard let docId = slot.uploadedDocumentId else { return nil }
        return documents.first { $0.id == docId }
    }
}
