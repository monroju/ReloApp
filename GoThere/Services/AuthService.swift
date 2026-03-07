import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine

/// Manages Firebase authentication.
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuest = false

    private var authListener: AuthStateDidChangeListenerHandle?

    private var firebaseAvailable: Bool {
        FirebaseApp.app() != nil
    }

    private init() {
        guard firebaseAvailable else { return }

        // On simulators (especially Appetize.io), the keychain is restricted.
        // We must call useUserAccessGroup(nil) BEFORE any auth operation
        // to force Firebase to use in-memory storage instead of keychain.
        #if targetEnvironment(simulator)
        do {
            try Auth.auth().useUserAccessGroup(nil)
        } catch {
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
        guard firebaseAvailable else { throw AuthError.firebaseNotConfigured }
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError where error.code == 17995 {
            // Keychain error — server auth may have succeeded anyway
            if let user = Auth.auth().currentUser {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } else {
                // Server auth also failed, fall back to guest with uid
                await MainActor.run {
                    self.isGuest = true
                    self.isAuthenticated = true
                }
            }
        }
    }

    func createUser(email: String, password: String) async throws {
        guard firebaseAvailable else { throw AuthError.firebaseNotConfigured }
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let db = Firestore.firestore()
            try await db.collection("users").document(result.user.uid).setData([
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } catch let error as NSError where error.code == 17995 {
            if let user = Auth.auth().currentUser {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } else {
                await MainActor.run {
                    self.isGuest = true
                    self.isAuthenticated = true
                }
            }
        }
    }

    func signInAsGuest() {
        isGuest = true
        isAuthenticated = true
    }

    func sendPasswordReset(email: String) async throws {
        guard firebaseAvailable else { throw AuthError.firebaseNotConfigured }
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func deleteAccount() async throws {
        guard firebaseAvailable else { return }
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let db = Firestore.firestore()
        try? await db.collection("users").document(uid).delete()
        try await user.delete()
    }

    func signOut() {
        isGuest = false
        if firebaseAvailable { try? Auth.auth().signOut() }
    }

    enum AuthError: LocalizedError {
        case firebaseNotConfigured
        var errorDescription: String? {
            "Firebase is not configured. Use Guest mode."
        }
    }
}
