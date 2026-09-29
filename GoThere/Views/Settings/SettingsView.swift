import SwiftUI

/// One place for plan, appearance, tools and account. Opened from the gear in the
/// top bar on every tab.
struct SettingsView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var countrySelection: CountrySelection
    @ObservedObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showDeleteConfirm = false
    @State private var deleteError: String?

    private var unlockedCount: Int {
        DestinationConfig.allDestinations.filter { purchaseManager.isCountryUnlocked($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                planSection
                appearanceSection
                toolsSection
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(purchaseManager)
            }
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAccount() }
            } message: {
                Text("This permanently deletes your account and your saved tasks, documents and progress. It can't be undone. Active App Store subscriptions must be cancelled separately in your Apple ID settings.")
            }
            .alert("Couldn't delete account", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var planSection: some View {
        Section {
            if purchaseManager.hasAllAccess {
                Label("All Access: every country unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.goPrimary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free plan")
                        .font(.headline)
                    Text("\(unlockedCount) of \(DestinationConfig.allDestinations.count) countries unlocked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Button {
                    showPaywall = true
                } label: {
                    Label("See plans and bundles", systemImage: "crown.fill")
                        .font(.body.weight(.semibold))
                }
            }

            Button {
                Task {
                    isRestoring = true
                    purchaseManager.purchaseErrorMessage = nil
                    await purchaseManager.restorePurchases()
                    isRestoring = false
                    restoreMessage = purchaseManager.purchaseErrorMessage
                        ?? "Restore finished. Anything bought with this Apple ID is unlocked."
                }
            } label: {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if purchaseManager.subscriptionStatus.isActive {
                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
            }
        } header: {
            Text("Your plan")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { themeVM.appearance },
                set: { themeVM.appearance = $0 }
            )) {
                ForEach(ThemeViewModel.Appearance.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var toolsSection: some View {
        Section("Tools") {
            NavigationLink {
                DestinationsView()
            } label: {
                Label("All Destinations", systemImage: "globe.europe.africa")
            }
            NavigationLink {
                VisaWizardView(countryId: countrySelection.current)
            } label: {
                Label("Visa Wizard", systemImage: "wand.and.stars")
            }
            NavigationLink {
                CostCalculatorView()
            } label: {
                Label("Cost Calculator", systemImage: "eurosign.circle")
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out") {
                dismiss()
                AuthService.shared.signOut()
            }
            if !auth.isGuest {
                Button("Delete Account", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://getgothere.app/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link("Contact Support", destination: URL(string: "mailto:gabriel@getgothere.app")!)
        } footer: {
            Text("GoThere \(appVersion)")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(v) (\(b))"
    }

    private func deleteAccount() {
        Task {
            do {
                try await AuthService.shared.deleteAccount()
                AuthService.shared.signOut()
                dismiss()
            } catch {
                deleteError = "For security, please sign out, sign back in, and try again. (\(error.localizedDescription))"
            }
        }
    }
}
