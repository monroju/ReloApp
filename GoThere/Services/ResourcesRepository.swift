import Foundation
import FirebaseStorage

/// Fetches public documents from Firebase Storage organized by country.
final class ResourcesRepository: ObservableObject {
    static let shared = ResourcesRepository()

    @Published var items: [ResourceItem] = []
    @Published var isLoading = false

    private let storage = Storage.storage()
    private let folders = ["Arrival", "Resources", "Templates", "VisaForms"]

    private init() {}

    @MainActor
    func loadDocuments(for countryId: String) async {
        isLoading = true
        var allItems: [ResourceItem] = []

        for folder in folders {
            let path = "\(folder)/\(countryId)"
            let ref = storage.reference().child(path)
            do {
                let result = try await ref.listAll()
                for item in result.items {
                    let url = try? await item.downloadURL()
                    let metadata = try? await item.getMetadata()
                    allItems.append(ResourceItem(
                        name: item.name,
                        path: item.fullPath,
                        sizeBytes: metadata?.size ?? 0,
                        downloadUrl: url?.absoluteString,
                        category: folder
                    ))
                }
            } catch {
                // Folder may not exist for this country, skip
            }
        }

        items = allItems
        isLoading = false
    }
}
