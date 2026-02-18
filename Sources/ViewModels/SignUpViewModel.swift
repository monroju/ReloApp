import Foundation
import Observation

@Observable
final class SignUpViewModel {

    // MARK: - Form State

    var email: String = "" { didSet { validateForm() } }
    var password: String = "" { didSet { validateForm() } }
    var confirm: String = "" { didSet { validateForm() } }
    var isPasswordVisible: Bool = false
    var isLoading: Bool = false
    var error: String? = nil
    var canSubmit: Bool = false

    /// Set by the parent coordinator after successful sign-up.
    var onSignUpSuccess: (() -> Void)?

    // MARK: - Computed

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirm
    }

    var passwordStrength: PasswordStrength {
        let len = password.count
        if len < 6 { return .weak }
        let hasUpper = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
        let score = [hasUpper, hasDigit, hasSpecial, len >= 10].filter { $0 }.count
        switch score {
        case 0...1: return .weak
        case 2:     return .fair
        case 3:     return .good
        default:    return .strong
        }
    }

    // MARK: - Actions

    func signUp() {
        guard canSubmit, !isLoading else { return }
        isLoading = true
        error = nil
        // Placeholder: Replace with FirebaseAuth / your auth service.
        // Example:
        //   Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, err in
        //       self?.isLoading = false
        //       if let err { self?.error = err.localizedDescription; return }
        //       self?.onSignUpSuccess?()
        //   }
        isLoading = false
    }

    func clearError() {
        error = nil
    }

    /// Snapshot the current state into a value type.
    func snapshot() -> SignUpUiState {
        SignUpUiState(
            email: email,
            password: password,
            confirm: confirm,
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
        let confirmValid = password == confirm
        canSubmit = emailValid && passwordValid && confirmValid
    }
}

// MARK: - PasswordStrength

enum PasswordStrength: String, CaseIterable {
    case weak, fair, good, strong

    var label: String { rawValue.capitalized }

    var fraction: Double {
        switch self {
        case .weak:   return 0.25
        case .fair:   return 0.50
        case .good:   return 0.75
        case .strong: return 1.0
        }
    }
}
