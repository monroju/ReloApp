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
        // On simulators (especially Appetize.io), the keychain is restricted.
        // We must call useUserAccessGroup(nil) BEFORE any auth operation
        // to force Firebase to use in-memory storage instead of keychain.
        #if targetEnvironment(simulator)
        do {
            try Auth.auth().useUserAccessGroup(nil)
        } catch {
            // If this fails, keychain operations will also fail —
            // users should use Guest mode on Appetize.io
            print("⚠️ useUserAccessGroup failed: \(error)")
        }
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
        #if targetEnvironment(simulator)
        // Re-apply before each auth call to ensure in-memory persistence
        try? Auth.auth().useUserAccessGroup(nil)
        #endif
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createUser(email: String, password: String) async throws {
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif
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
