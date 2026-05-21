import SwiftUI

extension Notification.Name {
    /// Cross-screen deep link request. userInfo["route"] is one of:
    /// "tasks" | "calendar" | "documents" | "resources" | "decision" | "wizard".
    /// Wizard is handled inside TasksView's own sheet; the rest map to tabs.
    static let gothereDeepLink = Notification.Name("gothere.deeplink")
}

struct MainTabView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)

            CalendarScreenView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)

            DocumentsView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }
                .tag(2)

            ResourcesView()
                .tabItem {
                    Label("Resources", systemImage: "book.fill")
                }
                .tag(3)

            NavigationStack {
                DecisionTreeView()
                    .goTopBar(showThemeToggle: false)
            }
            .tabItem {
                Label("Decision Tree", systemImage: "signpost.right.fill")
            }
            .tag(4)
        }
        .tint(.goPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .gothereDeepLink)) { note in
            switch (note.userInfo?["route"] as? String) ?? "" {
            case "tasks":     selectedTab = 0
            case "calendar":  selectedTab = 1
            case "documents": selectedTab = 2
            case "resources": selectedTab = 3
            case "decision", "decisiontree": selectedTab = 4
            default: break  // wizard handled inside TasksView's own sheet
            }
        }
    }
}
