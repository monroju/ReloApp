import SwiftUI
import FirebaseCore
import PostHog

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        let phConfig = PostHogConfig(
            apiKey: "phc_zdWSqHah9LiyNqn38H2i3E48XPv5acrWsXedfUWVGSLb",
            host: "https://eu.i.posthog.com"
        )
        PostHogSDK.shared.setup(phConfig)
        return true
    }
}

@main
struct GoThereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeVM = ThemeViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var countrySelection = CountrySelection.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(themeVM)
                        .environmentObject(purchaseManager)
                        .environmentObject(countrySelection)
                } else {
                    LoginView()
                        .environmentObject(themeVM)
                        .environmentObject(purchaseManager)
                        .environmentObject(countrySelection)
                }
            }
            .preferredColorScheme(themeVM.isDarkMode ? .dark : .light)
        }
    }
}
