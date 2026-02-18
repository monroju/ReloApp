#if canImport(SwiftUI)
import SwiftUI

@main
struct ReloApp: App {

    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            Group {
                if coordinator.isAuthenticated {
                    MainTabView(coordinator: coordinator)
                } else {
                    AuthFlowView(coordinator: coordinator)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: coordinator.isAuthenticated)
            .onAppear {
                coordinator.restoreSessionIfNeeded()
            }
        }
    }
}

// MARK: - Auth Flow

struct AuthFlowView: View {

    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.authPath) {
            LoginView(
                onNavigateToSignUp: {
                    coordinator.navigateToSignUp()
                },
                onAuthenticated: {
                    coordinator.signIn()
                }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .login:
                    LoginView(
                        onNavigateToSignUp: {
                            coordinator.navigateToSignUp()
                        },
                        onAuthenticated: {
                            coordinator.signIn()
                        }
                    )
                case .signUp:
                    SignUpView(
                        onNavigateToLogin: {
                            coordinator.navigateToLogin()
                        },
                        onRegistered: {
                            coordinator.signIn()
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    @Bindable var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2", value: .dashboard) {
                HomeDashboardView()
            }

            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}

#else

@main
struct ReloApp {
    static func main() {
        print("ReloApp: SwiftUI is not available on this platform. Business logic compiled successfully.")
    }
}

#endif
