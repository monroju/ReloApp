import SwiftUI

struct GoThereTopBar: ViewModifier {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    let showCountrySelector: Bool
    let showThemeToggle: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.goPrimary)
                        Text("GoThere")
                            .font(.headline)
                            .foregroundColor(.goPrimary)
                    }
                }
                if showThemeToggle {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                themeVM.toggleTheme()
                            } label: {
                                Image(systemName: themeVM.isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .foregroundColor(.goPrimary)
                            }
                            Menu {
                                NavigationLink("Cost Calculator") {
                                    CostCalculatorView()
                                }
                                NavigationLink("Visa Packs") {
                                    VisaPackView()
                                }
                                NavigationLink("Destinations") {
                                    DestinationsView()
                                }
                                Divider()
                                Button("Sign Out", role: .destructive) {
                                    AuthService.shared.signOut()
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.goPrimary)
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func goTopBar(showCountrySelector: Bool = false, showThemeToggle: Bool = true) -> some View {
        modifier(GoThereTopBar(showCountrySelector: showCountrySelector, showThemeToggle: showThemeToggle))
    }
}
