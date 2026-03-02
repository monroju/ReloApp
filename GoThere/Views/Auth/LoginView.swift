import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var themeVM: ThemeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                (themeVM.isDarkMode ? Color.goBackgroundDark : Color.goBackgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 48)

                        // Logo — teal "9" pin inside dark circle (matches Android)
                        ZStack {
                            Circle()
                                .fill(Color.goBackgroundDark)
                                .frame(width: 140, height: 140)

                            HStack(spacing: 6) {
                                // Stylized location pin "9"
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.goPrimary)

                                Text("GoThere")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer().frame(height: 24)

                        // Form with underline-style fields (Android style)
                        VStack(spacing: 20) {
                            // Email field — underline style
                            VStack(spacing: 4) {
                                TextField("Email", text: $vm.email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding(.vertical, 8)
                                Rectangle()
                                    .fill(Color.goPrimary.opacity(0.5))
                                    .frame(height: 1)
                            }

                            // Password field — underline style
                            VStack(spacing: 4) {
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
                                .padding(.vertical, 8)
                                Rectangle()
                                    .fill(Color.goPrimary.opacity(0.5))
                                    .frame(height: 1)
                            }

                            // Confirm password (sign up only)
                            if vm.isSignUpMode {
                                VStack(spacing: 4) {
                                    SecureField("Confirm Password", text: $vm.confirmPassword)
                                        .padding(.vertical, 8)
                                    Rectangle()
                                        .fill(Color.goPrimary.opacity(0.5))
                                        .frame(height: 1)
                                }
                            }

                            // Error
                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.goError)
                                    .multilineTextAlignment(.center)
                            }

                            Spacer().frame(height: 4)

                            // Primary button — teal rounded (matches Android)
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
                                        .padding(.vertical, 14)
                                } else {
                                    Text(vm.isSignUpMode ? "Sign Up" : "Log In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .background(Color.goPrimary)
                            .cornerRadius(28)
                            .disabled(vm.isLoading)

                            // Toggle sign up / sign in
                            Button {
                                withAnimation { vm.isSignUpMode.toggle() }
                            } label: {
                                Text(vm.isSignUpMode
                                     ? "Already have an account? **Log In**"
                                     : "Don't have an account? **Sign Up**")
                                    .font(.subheadline)
                                    .foregroundColor(.goPrimary)
                            }

                            // Guest mode for Appetize.io testing
                            Button {
                                AuthService.shared.signInAsGuest()
                            } label: {
                                Text("Continue as Guest")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
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
                                .foregroundColor(.goPrimary)
                                .padding(12)
                                .background(themeVM.isDarkMode ? Color.goSurfaceDark : Color.goSurfaceLight)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
