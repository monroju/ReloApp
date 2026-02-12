import Foundation

struct SignUpUiState: Codable, Hashable {
    var email: String
    var password: String
    var confirm: String
    var isPasswordVisible: Bool
    var isLoading: Bool
    var error: String?
    var canSubmit: Bool

    init(
        email: String = "",
        password: String = "",
        confirm: String = "",
        isPasswordVisible: Bool = false,
        isLoading: Bool = false,
        error: String? = nil,
        canSubmit: Bool = false
    ) {
        self.email = email
        self.password = password
        self.confirm = confirm
        self.isPasswordVisible = isPasswordVisible
        self.isLoading = isLoading
        self.error = error
        self.canSubmit = canSubmit
    }

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case confirm
        case isPasswordVisible = "is_password_visible"
        case isLoading = "is_loading"
        case error
        case canSubmit = "can_submit"
    }
}
