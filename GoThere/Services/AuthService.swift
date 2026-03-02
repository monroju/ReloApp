import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Manages Firebase authentication.
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuest = false

    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        // Use in-memory auth persistence on simulators (fixes keychain errors on Appetize.io)
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil || (self?.isGuest ?? false)
            }
        }
    }

    var uid: String? {
        if isGuest { return "guest" }
        return currentUser?.uid
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createUser(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let db = Firestore.firestore()
        try await db.collection("users").document(result.user.uid).setData([
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func signInAsGuest() {
        isGuest = true
        isAuthenticated = true
    }

    func signOut() {
        isGuest = false
        try? Auth.auth().signOut()
    }
}
