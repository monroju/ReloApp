import Foundation
import Combine

@MainActor
final class ResourcesViewModel: ObservableObject {
    @Published var items: [ResourceItem] = []
    @Published var isLoading = false
    @Published var selectedCountry = DestinationConfig.spain

    private let repo = ResourcesRepository.shared

    var groupedItems: [(String, [ResourceItem])] {
        let grouped = Dictionary(grouping: items) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    func loadDocuments() async {
        isLoading = true
        await repo.loadDocuments(for: selectedCountry)
        items = repo.items
        isLoading = false
    }

    func changeCountry(_ countryId: String) {
        selectedCountry = countryId
        Task { await loadDocuments() }
    }
}
