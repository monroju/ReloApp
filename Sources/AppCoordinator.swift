import Foundation
import Observation

// MARK: - Route Enums

enum AuthRoute: Hashable {
    case login
    case signUp
}

enum AppTab: Hashable {
    case dashboard
    case calendar
}

// MARK: - AppCoordinator

@Observable
final class AppCoordinator {

    // MARK: - Auth State

    /// `true` once the user has been authenticated (or a cached session is restored).
    var isAuthenticated: Bool = false

    /// Controls which screen is shown in the unauthenticated flow.
    var authRoute: AuthRoute = .login

    /// Tracks the full navigation path within the auth flow for push/pop.
    var authPath: [AuthRoute] = []

    // MARK: - Main App State

    var selectedTab: AppTab = .dashboard

    /// Deep-link target set before authentication completes so we can
    /// navigate the user to the right place after sign-in.
    var pendingDeepLink: AppTab? = nil

    // MARK: - Session Info (populated after sign-in)

    var uid: String? = nil
    var userEmail: String? = nil

    // MARK: - Auth Actions

    func signIn(uid: String? = nil, email: String? = nil) {
        self.uid = uid
        self.userEmail = email
        isAuthenticated = true

        if let deep = pendingDeepLink {
            selectedTab = deep
            pendingDeepLink = nil
        }
    }

    func signOut() {
        uid = nil
        userEmail = nil
        isAuthenticated = false
        authRoute = .login
        authPath = []
        selectedTab = .dashboard
        // Placeholder: call Auth.auth().signOut()
    }

    // MARK: - Auth Navigation

    func navigateToSignUp() {
        authPath.append(.signUp)
    }

    func navigateToLogin() {
        authPath.removeAll()
    }

    // MARK: - Session Restoration

    /// Call on app launch to check for an existing Firebase / Keychain session.
    func restoreSessionIfNeeded() {
        // Placeholder: check for cached auth token
        // Example:
        //   if let user = Auth.auth().currentUser {
        //       signIn(uid: user.uid, email: user.email)
        //   }
    }
}
