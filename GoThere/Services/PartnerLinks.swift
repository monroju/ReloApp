import Foundation

/// Affiliate links for the Money & Insurance directory, fetched from
/// https://getgothere.app/api/partners.json (built from the site's `_partners.json`).
///
/// The feed lists only partners that are live with a tracking link, so turning a
/// partner on is a site deploy, never an app release. Anything not in the feed
/// keeps its plain homepage `url` from `MoneyInsuranceProviders`.
@MainActor
final class PartnerLinks: ObservableObject {
    static let shared = PartnerLinks()

    @Published private(set) var urls: [String: String]

    private static let feed = URL(string: "https://getgothere.app/api/partners.json")!
    private static let cacheKey = "partner_links_v1"
    /// Site ids that differ from the app's MoneyProvider ids.
    private static let aliases: [String: String] = [:]

    private var lastFetch: Date?

    private init() {
        urls = (UserDefaults.standard.dictionary(forKey: Self.cacheKey) as? [String: String]) ?? [:]
    }

    /// Tracking link when the partner is live, else the provider's own homepage.
    func url(for provider: MoneyProvider) -> URL {
        if let s = urls[provider.id], let u = URL(string: s) { return u }
        return URL(string: provider.url) ?? URL(string: "https://getgothere.app")!
    }

    func isPartner(_ provider: MoneyProvider) -> Bool { urls[provider.id] != nil }

    /// Cheap to call on every appear: refetches at most every 6 hours.
    func refresh() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 6 * 3600 { return }
        lastFetch = Date()
        struct Feed: Decodable {
            struct Partner: Decodable { let id: String; let url: String }
            let partners: [Partner]
        }
        do {
            let (data, resp) = try await URLSession.shared.data(from: Self.feed)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            let feed = try JSONDecoder().decode(Feed.self, from: data)
            var map: [String: String] = [:]
            for p in feed.partners where p.url.hasPrefix("https://") {
                map[Self.aliases[p.id] ?? p.id] = p.url
            }
            urls = map
            UserDefaults.standard.set(map, forKey: Self.cacheKey)
        } catch {
            // Offline or bad JSON: keep the cached map.
        }
    }
}
