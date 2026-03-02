import SwiftUI

/// Shared top bar matching Android layout:
/// Left: country flag + dropdown name
/// Center: teal pin icon
/// Right: settings gear
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
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Center — teal pin logo
                ToolbarItem(placement: .principal) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.goPrimary)
                }

                // Right — gear + optional theme toggle
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if showThemeToggle {
                            Button {
                                themeVM.toggleTheme()
                            } label: {
                                Image(systemName: themeVM.isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .foregroundColor(.goPrimary)
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
        DestinationConfig.getDestination(id)?.flagEmoji ?? "🇪🇸"
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
