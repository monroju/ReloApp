import Foundation
import Observation

@Observable
final class LoginViewModel {

    // MARK: - Form State

    var email: String = "" { didSet { validateForm() } }
    var password: String = "" { didSet { validateForm() } }
    var isPasswordVisible: Bool = false
    var isLoading: Bool = false
    var error: String? = nil
    var canSubmit: Bool = false

    /// Set by the parent coordinator after successful login.
    var onLoginSuccess: (() -> Void)?

    // MARK: - Actions

    func login() {
        guard canSubmit, !isLoading else { return }
        isLoading = true
        error = nil
        // Placeholder: Replace with FirebaseAuth / your auth service.
        // Example:
        //   Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, err in
        //       self?.isLoading = false
        //       if let err { self?.error = err.localizedDescription; return }
        //       self?.onLoginSuccess?()
        //   }
        isLoading = false
    }

    func clearError() {
        error = nil
    }

    // MARK: - Snapshot

    /// Snapshot the current state into a value type for logging / analytics.
    func snapshot() -> LoginUiState {
        LoginUiState(
            email: email,
            password: password,
            isPasswordVisible: isPasswordVisible,
            isLoading: isLoading,
            error: error,
            canSubmit: canSubmit
        )
    }

    // MARK: - Private

    private func validateForm() {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        canSubmit = emailValid && passwordValid
    }
}
