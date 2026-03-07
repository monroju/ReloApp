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
            errorMessage = friendlyError(error)
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
        } catch let error as NSError {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func friendlyError(_ error: NSError) -> String {
        switch error.code {
        case 17008: return "Please enter a valid email address."
        case 17009: return "Incorrect password. Please try again."
        case 17011: return "No account found with this email."
        case 17026: return "Password must be at least 6 characters."
        default: return error.localizedDescription
        }
    }

    @Published var resetEmailSent = false

    func sendPasswordReset() async {
        guard isEmailValid else {
            errorMessage = "Please enter your email address first."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.sendPasswordReset(email: email)
            resetEmailSent = true
        } catch let error as NSError {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await auth.deleteAccount()
        } catch let error as NSError {
            errorMessage = friendlyError(error)
        }
        isDeleting = false
    }

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
}
