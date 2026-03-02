import SwiftUI

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
    }
}
