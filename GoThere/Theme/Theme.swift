import SwiftUI

// MARK: - App Colors (matching Android GoThere)

extension Color {
    // Primary Teal
    static let goPrimary = Color(hex: 0x15B8A6)            // Teal primary
    static let goOnPrimary = Color.white
    static let goPrimaryDark = Color(hex: 0x0F8F82)        // Teal Dark
    static let goPrimaryLight = Color(hex: 0x7BE3D6)       // Teal Light
    static let goPrimaryContainer = Color(hex: 0xC5F4EE)     // Android primaryContainer

    // Secondary
    static let goSecondary = Color(hex: 0x0F8F82)           // TealDark as secondary
    static let goOnSecondary = Color.white

    // Tertiary (soft blue, matches Android)
    static let goTertiary = Color(hex: 0x2E8BC0)

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

// MARK: - Radii

enum GoRadius {
    static let chip: CGFloat = 8
    static let control: CGFloat = 12
    static let card: CGFloat = 16
}

// MARK: - Card Style

/// Raised card: in dark mode a 1pt lighter top edge catches the light; in
/// light mode a soft, low shadow lifts it off the background.
struct GoCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var padded: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GoRadius.card, style: .continuous)
        content
            .padding(padded ? 16 : 0)
            .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight, in: shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(colorScheme == .dark ? 0.09 : 0), .clear],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.08), radius: 6, y: 2)
    }
}

extension View {
    func goCard() -> some View {
        modifier(GoCardStyle())
    }

    /// Raised card treatment for content that brings its own padding.
    func goRaised() -> some View {
        modifier(GoCardStyle(padded: false))
    }
}

// MARK: - Depth

/// Shrinks slightly while pressed and springs back.
struct GoPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Primary call to action: teal gradient body, light top rim, teal glow.
/// Use for the one or two main actions on a screen.
struct GoRaisedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = Capsule(style: .continuous)
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                // Top stop is goPrimary mixed 16% toward white (same as Android).
                LinearGradient(colors: [Color(hex: 0x3AC0B4), .goPrimary],
                               startPoint: .top, endPoint: .bottom),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.35), .clear],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.goPrimary.opacity(isEnabled ? 0.45 : 0), radius: 10, y: 4)
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GoRaisedButtonStyle {
    static var goRaised: GoRaisedButtonStyle { GoRaisedButtonStyle() }
    static var goRaisedFull: GoRaisedButtonStyle { GoRaisedButtonStyle(fullWidth: true) }
}

extension ButtonStyle where Self == GoPressStyle {
    static var goPress: GoPressStyle { GoPressStyle() }
}
