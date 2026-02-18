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
            HomeDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(AppTab.dashboard)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(AppTab.calendar)
        }
    }
}
