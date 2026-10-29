import SwiftUI

extension Notification.Name {
    /// Cross-screen deep link request. userInfo["route"] is one of:
    /// "tasks" | "calendar" | "documents" | "resources" | "decision" | "wizard".
    /// Wizard is handled inside TasksView's own sheet; the rest map to tabs.
    static let gothereDeepLink = Notification.Name("gothere.deeplink")
}

/// External `gothere://<route>` URLs (App Store In-App Events, links). Holds the
/// route until MainTabView is on screen, so a cold launch or a pre-login tap
/// still lands on the right tab once the tabs appear.
@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    @Published var pendingRoute: String?

    func open(_ url: URL) {
        guard url.scheme?.lowercased() == "gothere" else { return }
        // gothere://decision parses "decision" as the host; gothere:///decision as the path.
        let route = (url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            .lowercased()
        guard !route.isEmpty else { return }
        pendingRoute = route
        Analytics.log(.deepLinkOpened, properties: ["route": route])
    }
}

struct MainTabView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedTab = 0
    @ObservedObject private var deepLinks = DeepLinkRouter.shared

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
            selectTab(for: (note.userInfo?["route"] as? String) ?? "")
        }
        .onAppear { consumePendingDeepLink() }
        .onChange(of: deepLinks.pendingRoute) { consumePendingDeepLink() }
    }

    private func consumePendingDeepLink() {
        guard let route = deepLinks.pendingRoute else { return }
        deepLinks.pendingRoute = nil
        selectTab(for: route)
    }

    private func selectTab(for route: String) {
        switch route {
        case "tasks":     selectedTab = 0
        case "calendar":  selectedTab = 1
        case "documents": selectedTab = 2
        case "resources": selectedTab = 3
        case "decision", "decisiontree": selectedTab = 4
        default: break  // wizard handled inside TasksView's own sheet
        }
    }
}
