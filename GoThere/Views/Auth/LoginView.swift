import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var themeVM: ThemeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (themeVM.isDarkMode ? Color.goBackgroundDark : Color.goBackgroundLight)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 60)

                        // Logo with dark circular background
                        ZStack {
                            Circle()
                                .fill(Color.goBackgroundDark)
                                .frame(width: 120, height: 120)
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 50))
                                .foregroundColor(.goPrimary)
                        }

                        Text("GoThere")
                            .font(.largeTitle.bold())
                            .foregroundColor(themeVM.isDarkMode ? .white : .goOnBackgroundLight)

                        Text("Your relocation companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer().frame(height: 12)

                        // Form
                        VStack(spacing: 16) {
                            // Email field
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                TextField("Email", text: $vm.email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(themeVM.isDarkMode ? Color.goSurfaceDark : Color.goSurfaceLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )

                            // Password field
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
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
                            .padding()
                            .background(themeVM.isDarkMode ? Color.goSurfaceDark : Color.goSurfaceLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )

                            // Confirm password (sign up mode)
                            if vm.isSignUpMode {
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                    SecureField("Confirm Password", text: $vm.confirmPassword)
                                }
                                .padding()
                                .background(themeVM.isDarkMode ? Color.goSurfaceDark : Color.goSurfaceLight)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // Error message
                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.goError)
                                    .multilineTextAlignment(.center)
                            }

                            // Primary button
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
                            .cornerRadius(12)
                            .disabled(vm.isLoading)

                            // Toggle sign up / sign in
                            Button {
                                withAnimation { vm.isSignUpMode.toggle() }
                            } label: {
                                Text(vm.isSignUpMode ? "Already have an account? **Log In**" : "Don't have an account? **Sign Up**")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                }

                // Theme toggle in bottom-right corner
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
