import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isPasswordVisible = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUpMode = false

    private let auth = AuthService.shared

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    func signIn() async {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password (6+ characters)."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch let error as NSError {
            // Show Firebase error code for easier debugging
            let code = error.code
            let msg = error.localizedDescription
            errorMessage = "(\(code)) \(msg)"
        }
        isLoading = false
    }

    func signUp() async {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password (6+ characters)."
            return
        }
        guard passwordsMatch else {
            errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.createUser(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
}
