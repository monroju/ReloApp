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
    private static let cacheKey = "partner_links_v2"
    /// Site ids that differ from the app's MoneyProvider ids. Country-specific site
    /// entries (feather_es, feather_de) map onto one app provider and are keyed
    /// "<provider>@<countryId>" using the feed's `countries` list.
    nonisolated private static let aliases: [String: String] = ["feather_es": "feather", "feather_de": "feather"]

    private var lastFetch: Date?

    private init() {
        urls = (UserDefaults.standard.dictionary(forKey: Self.cacheKey) as? [String: String]) ?? [:]
    }

    /// Tracking link when the partner is live (for this country if the feed has a
    /// country-specific link), else the provider's own homepage.
    func url(for provider: MoneyProvider, countryId: String) -> URL {
        if let s = link(provider.id, countryId), let u = URL(string: s) { return u }
        return URL(string: provider.url) ?? URL(string: "https://getgothere.app")!
    }

    func isPartner(_ provider: MoneyProvider, countryId: String) -> Bool { link(provider.id, countryId) != nil }

    private func link(_ id: String, _ countryId: String) -> String? {
        urls["\(id)@\(countryId)"] ?? urls[id]
    }

    /// Builds the id -> url map from feed entries. Exposed for tests.
    nonisolated static func map(_ partners: [(id: String, url: String, countries: [String])]) -> [String: String] {
        var map: [String: String] = [:]
        for p in partners where p.url.hasPrefix("https://") {
            let id = aliases[p.id] ?? p.id
            if p.countries.isEmpty || p.countries.contains("*") {
                map[id] = p.url
            } else {
                for c in p.countries { map["\(id)@\(c)"] = p.url }
            }
        }
        return map
    }

    /// Cheap to call on every appear: refetches at most every 6 hours.
    func refresh() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 6 * 3600 { return }
        lastFetch = Date()
        struct Feed: Decodable {
            struct Partner: Decodable { let id: String; let url: String; let countries: [String]? }
            let partners: [Partner]
        }
        do {
            let (data, resp) = try await URLSession.shared.data(from: Self.feed)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            let feed = try JSONDecoder().decode(Feed.self, from: data)
            let map = Self.map(feed.partners.map { ($0.id, $0.url, $0.countries ?? ["*"]) })
            urls = map
            UserDefaults.standard.set(map, forKey: Self.cacheKey)
        } catch {
            // Offline or bad JSON: keep the cached map.
        }
    }
}
