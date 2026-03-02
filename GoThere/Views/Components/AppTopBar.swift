import SwiftUI

/// Top bar matching Android CenterAlignedTopAppBar:
/// Left: country flag + dropdown
/// Center: ic_logo.png (32dp circular)
/// Right: theme toggle + settings gear
struct GoThereTopBar: ViewModifier {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    let showThemeToggle: Bool

    @State private var selectedCountry = DestinationConfig.spain

    func body(content: Content) -> some View {
        content
            .toolbar {
                // Left — country flag + dropdown
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(DestinationConfig.allDestinations) { dest in
                            let isUnlocked = purchaseManager.isCountryUnlocked(dest.id)
                            Button {
                                if isUnlocked {
                                    selectedCountry = dest.id
                                }
                            } label: {
                                HStack {
                                    Text("\(dest.flagEmoji) \(dest.name)")
                                    if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(flagForCountry(selectedCountry))
                            Text(nameForCountry(selectedCountry))
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Center — actual GoThere logo (ic_logo.png, circular 32dp)
                ToolbarItem(placement: .principal) {
                    Image("GoThereLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }

                // Right — theme toggle + settings gear
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if showThemeToggle {
                            Button {
                                themeVM.toggleTheme()
                            } label: {
                                Image(systemName: themeVM.isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .foregroundColor(themeVM.isDarkMode ? .white : .black)
                            }
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
                            Image(systemName: "gearshape")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
    }

    private func flagForCountry(_ id: String) -> String {
        DestinationConfig.getDestination(id)?.flagEmoji ?? "\u{1F1EA}\u{1F1F8}"
    }

    private func nameForCountry(_ id: String) -> String {
        DestinationConfig.getDestination(id)?.name ?? "Spain"
    }
}

extension View {
    func goTopBar(showThemeToggle: Bool = true) -> some View {
        modifier(GoThereTopBar(showThemeToggle: showThemeToggle))
    }
}
