import SwiftUI

// MARK: - App Colors (matching Android GoThere)

extension Color {
    // Primary Teal
    static let goPrimary = Color(hex: 0x15B8A6)            // Teal primary
    static let goOnPrimary = Color.white
    static let goPrimaryDark = Color(hex: 0x0F8F82)        // Teal Dark
    static let goPrimaryLight = Color(hex: 0x7BE3D6)       // Teal Light
    static let goPrimaryContainer = Color(hex: 0x7BE3D6).opacity(0.2)

    // Secondary
    static let goSecondary = Color(hex: 0x15B8A6).opacity(0.7)
    static let goOnSecondary = Color.white

    // Background (Light)
    static let goBackgroundLight = Color(hex: 0xF7F8FA)
    static let goSurfaceLight = Color.white
    static let goOnBackgroundLight = Color(hex: 0x1A1A24)

    // Background (Dark)
    static let goBackgroundDark = Color(hex: 0x151B23)      // Night
    static let goSurfaceDark = Color(hex: 0x1E2530)
    static let goOnBackgroundDark = Color(hex: 0xE8E9ED)

    // Accent
    static let goError = Color(hex: 0xBA1A1A)
    static let goWarning = Color(hex: 0xFFAB00)
    static let goSuccess = Color(hex: 0x4DC77B)

    // Hex initializer
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Theme Environment Key

struct GoThereThemeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isDarkMode: Bool {
        get { self[GoThereThemeKey.self] }
        set { self[GoThereThemeKey.self] = newValue }
    }
}

// MARK: - Card Style

struct GoCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

extension View {
    func goCard() -> some View {
        modifier(GoCardStyle())
    }
}
