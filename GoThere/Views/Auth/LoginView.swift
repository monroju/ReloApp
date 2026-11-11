import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var themeVM: ThemeViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.goBackgroundDark : Color.goBackgroundLight)
                .ignoresSafeArea()

            // Main form — centered vertically like Android
            VStack(spacing: 0) {
                Spacer()

                // Logo — ic_logo_full.png circular (matches Android)
                Image("GoThereLogoFull")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())

                Spacer().frame(height: 20)

                // One clear heading per mode, so it is obvious which of the two flows is active
                Text(vm.isSignUpMode
                     ? String(localized: "Create your account")
                     : String(localized: "Welcome back"))
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(vm.isSignUpMode
                     ? String(localized: "New here? Choose an email and a password.")
                     : String(localized: "Use the email and password you signed up with."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                Spacer().frame(height: 20)

                // Mode switch: two tabs, the selected one filled
                HStack(spacing: 0) {
                    modeTab(String(localized: "Create account"), selected: vm.isSignUpMode) {
                        setMode(signUp: true)
                    }
                    modeTab(String(localized: "Log In"), selected: !vm.isSignUpMode) {
                        setMode(signUp: false)
                    }
                }
                .padding(4)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                // Email field — OutlinedTextField style with rounded border
                VStack(spacing: 16) {
                    HStack {
                        TextField("Email", text: $vm.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.goPrimary.opacity(0.6), lineWidth: 1)
                    )

                    // Password field
                    HStack {
                        if vm.isPasswordVisible {
                            TextField("Password", text: $vm.password)
                        } else {
                            SecureField("Password", text: $vm.password)
                        }
                        Button {
                            vm.togglePasswordVisibility()
                        } label: {
                            Image(systemName: vm.isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.goPrimary, lineWidth: 1)
                    )

                    // Confirm password (sign up only)
                    if vm.isSignUpMode {
                        HStack {
                            SecureField("Confirm Password", text: $vm.confirmPassword)
                        }
                        .padding(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.goPrimary.opacity(0.6), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)

                // Forgot password (login mode only)
                if !vm.isSignUpMode {
                    HStack {
                        Spacer()
                        Button {
                            Task { await vm.sendPasswordReset() }
                        } label: {
                            Text("Forgot Password?")
                                .font(.caption)
                                .foregroundColor(.goPrimary)
                        }
                        .disabled(vm.isLoading)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }

                Spacer().frame(height: 24)

                // Reset email confirmation
                if vm.resetEmailSent {
                    Text("Password reset email sent! Check your inbox.")
                        .font(.caption)
                        .foregroundColor(.goSuccess)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                }

                // Error message
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.goError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                }

                // Primary button — teal, 48dp height, 8dp radius (Android)
                Button {
                    Task {
                        if vm.isSignUpMode {
                            await vm.signUp()
                        } else {
                            await vm.signIn()
                        }
                    }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    } else {
                        Text(vm.isSignUpMode
                             ? String(localized: "Create account")
                             : String(localized: "Log In"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                }
                .background(Color.goPrimary)
                .cornerRadius(8)
                .disabled(vm.isLoading)
                .padding(.horizontal, 32)

                Spacer().frame(height: 16)

                // Privacy policy link
                HStack(spacing: 0) {
                    Text("By continuing, you agree to our ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("Privacy Policy", destination: URL(string: "https://gothere-e5ea7.web.app/privacy.html")!)
                        .font(.caption)
                        .foregroundColor(.goPrimary)
                        .underline()
                }

                Spacer().frame(height: 16)

                // Guest mode for Appetize.io testing
                Button {
                    AuthService.shared.signInAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .underline()
                }

                Spacer()
            }

            // Theme toggle — bottom right (matches Android)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        themeVM.appearance = (colorScheme == .dark) ? .light : .dark
                    } label: {
                        Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .padding(32)
                }
            }
        }
    }

    private func setMode(signUp: Bool) {
        guard vm.isSignUpMode != signUp else { return }
        withAnimation {
            vm.isSignUpMode = signUp
            vm.errorMessage = nil
            vm.resetEmailSent = false
        }
    }

    private func modeTab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.goPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(vm.isLoading)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
