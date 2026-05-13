import SwiftUI

struct HomeView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var countrySelection: CountrySelection
    @StateObject private var destVM = DestinationsViewModel()
    @StateObject private var tasksVM = TasksViewModel()
    @StateObject private var calendarVM = CalendarViewModel()
    @State private var showPaywall = false
    @State private var showMenu = false
    @State private var showDeleteAccount = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Country selector
                    countrySelector

                    // Visa track info
                    if let track = destVM.activeVisaTrack {
                        visaTrackCard(track)
                    }

                    // Quick stats
                    statsSection

                    // Upcoming events
                    upcomingEventsSection

                    // Quick links
                    quickLinksSection
                }
                .padding()
            }
            .navigationTitle("GoThere")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.goPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            themeVM.toggleTheme()
                        } label: {
                            Image(systemName: themeVM.isDarkMode ? "sun.max.fill" : "moon.fill")
                        }
                        Menu {
                            NavigationLink("Decision Tree") {
                                DecisionTreeView()
                            }
                            NavigationLink("Cost Calculator") {
                                CostCalculatorView()
                            }
                            NavigationLink("Visa Wizard") {
                                VisaWizardView(countryId: countrySelection.current)
                            }
                            NavigationLink("Destinations") {
                                DestinationsView()
                            }
                            Divider()
                            if !AuthService.shared.isGuest {
                                Button("Delete Account", role: .destructive) {
                                    showDeleteAccount = true
                                }
                            }
                            Button("Sign Out", role: .destructive) {
                                AuthService.shared.signOut()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task {
                await destVM.loadDestination()
                tasksVM.startListening()
                calendarVM.startListening()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Delete Account", isPresented: $showDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await AuthService.shared.deleteAccount()
                        } catch {
                            deleteError = error.localizedDescription
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This cannot be undone.")
            }
            .alert("Error", isPresented: .constant(deleteError != nil)) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    // MARK: - Country Selector

    private var countrySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DestinationConfig.allDestinations) { dest in
                    let isUnlocked = purchaseManager.isCountryUnlocked(dest.id)
                    let isActive = destVM.activeDestinationId == dest.id

                    Button {
                        if isUnlocked {
                            Task { await destVM.selectDestination(dest.id) }
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(dest.flagEmoji)
                            Text(dest.name)
                                .font(.subheadline.weight(isActive ? .bold : .regular))
                            if !isUnlocked {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isActive ? Color.goPrimary.opacity(0.15) : Color.clear)
                        .foregroundColor(isActive ? .goPrimary : .primary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isActive ? Color.goPrimary : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Visa Track Card

    private func visaTrackCard(_ track: VisaTrack) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(track.name)
                    .font(.headline)
                Spacer()
                if let time = track.estimatedProcessingTime {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(track.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let dest = destVM.activeDestination, dest.visaTracks.count > 1 {
                Menu {
                    ForEach(dest.visaTracks) { t in
                        Button {
                            Task { await destVM.selectVisaTrack(t.id) }
                        } label: {
                            Label(t.name, systemImage: t.id == destVM.activeVisaTrackId ? "checkmark" : "")
                        }
                    }
                } label: {
                    Text("Change visa track")
                        .font(.caption)
                        .foregroundColor(.goPrimary)
                }
            }
        }
        .goCard()
    }

    // MARK: - Stats

    private var statsSection: some View {
        let total = tasksVM.tasks.count
        let completed = tasksVM.tasks.filter(\.completed).count
        let pct = total > 0 ? Double(completed) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)

            HStack(spacing: 20) {
                statBubble(value: "\(completed)/\(total)", label: "Tasks Done")
                statBubble(value: "\(Int(pct * 100))%", label: "Complete")
                statBubble(value: "\(calendarVM.upcomingEvents.count)", label: "Upcoming")
            }

            ProgressView(value: pct)
                .tint(.goSuccess)
        }
        .goCard()
    }

    private func statBubble(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.goPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Events")
                .font(.headline)

            if calendarVM.upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(calendarVM.upcomingEvents.prefix(3)) { event in
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.goPrimary)
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.subheadline)
                            Text(event.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .goCard()
    }

    // MARK: - Quick Links

    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    DecisionTreeView()
                } label: {
                    quickLinkTile(icon: "signpost.right.fill", title: "Find Your City", color: .goPrimary)
                }

                NavigationLink {
                    CostCalculatorView()
                } label: {
                    quickLinkTile(icon: "dollarsign.circle.fill", title: "Cost Calculator", color: .goSecondary)
                }

                NavigationLink {
                    VisaWizardView(countryId: countrySelection.current)
                } label: {
                    quickLinkTile(icon: "wand.and.stars", title: "Visa Wizard", color: .orange)
                }

                NavigationLink {
                    DestinationsView()
                } label: {
                    quickLinkTile(icon: "map.fill", title: "Destinations", color: .purple)
                }
            }
        }
        .goCard()
    }

    private func quickLinkTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
