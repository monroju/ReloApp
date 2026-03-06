import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var themeVM: ThemeViewModel

    var body: some View {
        ZStack {
            (themeVM.isDarkMode ? Color.goBackgroundDark : Color.goBackgroundLight)
                .ignoresSafeArea()

            // Main form — centered vertically like Android
            VStack(spacing: 0) {
                Spacer()

                // Logo — ic_logo_full.png circular, 240dp on Android
                Image("GoThereLogoFull")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())

                Spacer().frame(height: 32)

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
                        Text(vm.isSignUpMode ? "Sign Up" : "Log In")
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

                Spacer().frame(height: 24)

                // Toggle sign up / sign in
                Button {
                    withAnimation { vm.isSignUpMode.toggle() }
                } label: {
                    Text(vm.isSignUpMode
                         ? "Already have an account? Log In"
                         : "Don't have an account? Sign Up")
                        .font(.system(size: 14))
                        .foregroundColor(.goPrimary)
                }

                Spacer().frame(height: 16)

                // Privacy policy link
                Text("By continuing, you agree to our ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text("Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.goPrimary)
                    .underline()

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
                        themeVM.toggleTheme()
                    } label: {
                        Image(systemName: themeVM.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title3)
                            .foregroundColor(themeVM.isDarkMode ? .white : .black)
                    }
                    .padding(32)
                }
            }
        }
    }
}
