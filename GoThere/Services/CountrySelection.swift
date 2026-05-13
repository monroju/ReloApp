import Foundation

/// App-wide selected destination country. Drives the top-bar flag, Tasks, Resources, and Calendar.
/// Persisted to UserDefaults so the selection survives relaunches.
@MainActor
final class CountrySelection: ObservableObject {
    static let shared = CountrySelection()

    private static let storageKey = "selectedCountryId"

    @Published var current: String {
        didSet {
            UserDefaults.standard.set(current, forKey: Self.storageKey)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.current = stored ?? DestinationConfig.spain
    }
}
