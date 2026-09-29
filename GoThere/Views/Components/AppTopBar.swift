import SwiftUI

/// Shared top bar for every tab.
/// Left: country picker (locked countries open their unlock preview) + Upgrade pill.
/// Right: one Settings button (plain button, never a hidden menu), so it can't be
/// pushed into the iOS overflow "..." when a screen adds its own actions.
struct GoThereTopBar: ViewModifier {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var countrySelection: CountrySelection

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var lockedCountry: LockedCountry?

    private struct LockedCountry: Identifiable {
        let id: String
        let name: String
        let flag: String
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 10) {
                        countryMenu
                        if !purchaseManager.hasAllAccess {
                            Button {
                                showPaywall = true
                            } label: {
                                Label("Upgrade", systemImage: "crown.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.goPrimary)
                            }
                            .accessibilityLabel("Upgrade: see plans and bundles")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(themeVM)
                    .environmentObject(purchaseManager)
                    .environmentObject(countrySelection)
                    .preferredColorScheme(themeVM.colorScheme)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchaseManager)
            }
            .sheet(item: $lockedCountry) { c in
                LockedCountryPreviewView(countryId: c.id, countryName: c.name, countryFlag: c.flag)
                    .environmentObject(purchaseManager)
            }
    }

    private var countryMenu: some View {
        Menu {
            ForEach(DestinationConfig.allDestinations) { dest in
                let isUnlocked = purchaseManager.isCountryUnlocked(dest.id)
                Button {
                    if isUnlocked {
                        countrySelection.current = dest.id
                    } else {
                        lockedCountry = LockedCountry(id: dest.id, name: dest.name, flag: dest.flagEmoji)
                    }
                } label: {
                    if isUnlocked {
                        Text("\(dest.flagEmoji) \(dest.name)")
                    } else {
                        Label("\(dest.flagEmoji) \(dest.name)", systemImage: "lock.fill")
                    }
                }
            }
            if !purchaseManager.hasAllAccess {
                Divider()
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock all countries", systemImage: "crown.fill")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(flagForCountry(countrySelection.current))
                Text(nameForCountry(countrySelection.current))
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
            }
            .foregroundColor(.primary)
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
    /// `showThemeToggle` is kept for existing call sites; appearance now lives in Settings.
    func goTopBar(showThemeToggle: Bool = true) -> some View {
        modifier(GoThereTopBar())
    }
}
