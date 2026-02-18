import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        NotificationManager.shared.requestPermission()
        return true
    }
}

@main
struct GoThereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeVM = ThemeViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(themeVM)
                        .environmentObject(purchaseManager)
                } else {
                    LoginView()
                        .environmentObject(themeVM)
                        .environmentObject(purchaseManager)
                }
            }
            .preferredColorScheme(themeVM.isDarkMode ? .dark : .light)
        }
    }
}
