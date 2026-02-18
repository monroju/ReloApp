import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Manages Firebase authentication.
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    var uid: String? { currentUser?.uid }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createUser(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Create user document in Firestore
        let db = Firestore.firestore()
        try await db.collection("users").document(result.user.uid).setData([
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
