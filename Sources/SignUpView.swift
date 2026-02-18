#if canImport(SwiftUI)
import SwiftUI

struct SignUpView: View {

    @State private var viewModel = SignUpViewModel()

    /// Navigate back to login.
    var onNavigateToLogin: (() -> Void)?
    /// Called after successful registration.
    var onRegistered: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.06)
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
            viewModel.onSignUpSuccess = onRegistered
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            Text("Create Account")
                .font(.largeTitle.bold())

            Text("Start your relocation journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 20) {
            if let error = viewModel.error {
                errorBanner(error)
            }

            // Email
            fieldSection(label: "Email", icon: "envelope") {
                TextField("you@example.com", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Password
            fieldSection(label: "Password", icon: "lock") {
                if viewModel.isPasswordVisible {
                    TextField("Min. 6 characters", text: $viewModel.password)
                        .textContentType(.newPassword)
                } else {
                    SecureField("Min. 6 characters", text: $viewModel.password)
                        .textContentType(.newPassword)
                }

                Button {
                    viewModel.isPasswordVisible.toggle()
                } label: {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Password strength
            if !viewModel.password.isEmpty {
                strengthIndicator
            }

            // Confirm password
            fieldSection(label: "Confirm Password", icon: "lock.rotation") {
                SecureField("Re-enter password", text: $viewModel.confirm)
                    .textContentType(.newPassword)

                if !viewModel.confirm.isEmpty {
                    Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.passwordsMatch ? .green : .red)
                        .font(.body)
                }
            }

            // Submit
            Button(action: viewModel.signUp) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
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

    // MARK: - Strength Indicator

    private var strengthIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    Capsule()
                        .fill(strengthColor)
                        .frame(width: geo.size.width * viewModel.passwordStrength.fraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.passwordStrength)
                }
            }
            .frame(height: 6)

            Text(viewModel.passwordStrength.label)
                .font(.caption2)
                .foregroundStyle(strengthColor)
        }
        .padding(.horizontal, 4)
    }

    private var strengthColor: Color {
        switch viewModel.passwordStrength {
        case .weak:   return .red
        case .fair:   return .orange
        case .good:   return .yellow
        case .strong: return .green
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .foregroundStyle(.secondary)
            Button("Sign In") {
                onNavigateToLogin?()
            }
            .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.top, 24)
    }

    // MARK: - Shared Components

    private func fieldSection<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                content()
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
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
    SignUpView()
}

#endif
