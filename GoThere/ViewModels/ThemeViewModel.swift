import Foundation
import SwiftUI

/// App appearance. Defaults to following the iPhone's own Light/Dark setting;
/// the user can pin Light or Dark from Settings.
@MainActor
final class ThemeViewModel: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    @AppStorage("appearance") private var storedAppearance: String = ""

    init() {
        // Migrate the old on/off toggle. Only an explicit dark choice carries over;
        // the old default (false) forced Light, which ignored the phone's setting.
        if storedAppearance.isEmpty {
            let wasDark = UserDefaults.standard.bool(forKey: "isDarkMode")
            storedAppearance = wasDark ? Appearance.dark.rawValue : Appearance.system.rawValue
        }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: storedAppearance) ?? .system }
        set {
            objectWillChange.send()
            storedAppearance = newValue.rawValue
        }
    }

    /// nil = follow the system setting.
    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// True only when Dark is pinned. Views that need the rendered scheme
    /// should read `@Environment(\.colorScheme)` instead.
    var isDarkMode: Bool { appearance == .dark }

    func toggleTheme() {
        appearance = (appearance == .dark) ? .light : .dark
    }
}
