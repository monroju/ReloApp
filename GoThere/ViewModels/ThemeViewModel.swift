import Foundation
import SwiftUI

@MainActor
final class ThemeViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    func toggleTheme() {
        isDarkMode.toggle()
    }
}
