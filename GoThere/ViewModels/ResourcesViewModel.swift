import Foundation
import Combine

@MainActor
final class ResourcesViewModel: ObservableObject {
    @Published var items: [ResourceItem] = []
    @Published var isLoading = false

    private let repo = ResourcesRepository.shared

    var groupedItems: [(String, [ResourceItem])] {
        let grouped = Dictionary(grouping: items) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    func loadDocuments(for countryId: String) async {
        isLoading = true
        await repo.loadDocuments(for: countryId)
        items = repo.items
        isLoading = false
    }
}
