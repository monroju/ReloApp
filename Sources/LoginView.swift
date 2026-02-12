import SwiftUI

struct LoginView: View {

    @State private var viewModel = LoginViewModel()

    /// Navigate to sign-up.
    var onNavigateToSignUp: (() -> Void)?
    /// Called after successful authentication.
    var onAuthenticated: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.08)
                    hero
                    formCard
                    footerLinks
                    Spacer(minLength: 32)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(backgroundGradient)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            viewModel.onLoginSuccess = onAuthenticated
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.desk")
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.accent)

            Text("Welcome Back")
                .font(.largeTitle.bold())

            Text("Sign in to continue your journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 20) {
            // Error banner
            if let error = viewModel.error {
                errorBanner(error)
            }

            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    TextField("you@example.com", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)

                    if viewModel.isPasswordVisible {
                        TextField("Password", text: $viewModel.password)
                            .textContentType(.password)
                    } else {
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                    }

                    Button {
                        viewModel.isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            // Submit
            Button(action: viewModel.login) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .controlSize(.large)
            .disabled(!viewModel.canSubmit || viewModel.isLoading)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(.secondary)
            Button("Sign Up") {
                onNavigateToSignUp?()
            }
            .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.top, 24)
    }

    // MARK: - Helpers

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                viewModel.clearError()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
