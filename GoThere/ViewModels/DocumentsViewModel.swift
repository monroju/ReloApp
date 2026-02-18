import Foundation
import Combine

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var documents: [UserDocument] = []
    @Published var isUploading = false
    @Published var errorMessage: String?

    private let repo = DocumentsRepository.shared
    private var cancellables = Set<AnyCancellable>()

    func startListening() {
        repo.startListening()
        repo.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: &$documents)
    }

    func upload(data: Data, fileName: String) {
        isUploading = true
        errorMessage = nil
        Task {
            do {
                try await repo.upload(data: data, fileName: fileName)
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
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
}
