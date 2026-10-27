import Foundation
import UIKit

extension String {
    /// Looks this string up in the app's String Catalog (Localizable.xcstrings) at runtime.
    ///
    /// Use it for UI labels that travel as plain `String` values, such as enum raw values
    /// shown as chips. The raw value itself is never changed, so persisted values and
    /// analytics stay in English. Strings with no catalog entry come back unchanged, so
    /// data and content pass through untouched.
    var uiLocalized: String {
        NSLocalizedString(self, comment: "")
    }
}

/// Per-app language support. Apple's pattern: the language picker lives in iOS
/// Settings > GoThere > Language, which appears once the app ships 2+ localizations.
/// GoThere does not override the locale in-app.
enum AppLanguage {
    /// Name of the language the app is currently running in, written in that language
    /// (for example "English" or "Español").
    static var currentDisplayName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forLanguageCode: code) ?? code
        return name.capitalized(with: locale)
    }

    /// Opens this app's page in iOS Settings, where the Language option lives.
    @MainActor
    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
