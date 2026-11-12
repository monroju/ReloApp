import Foundation

/// One organization in the "Get help" feed.
/// Unknown JSON fields are ignored, so the feed can grow without an app release.
struct HelpOrg: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let url: String
    let audiences: [String]
    let apps: [String]
    let countries: [String]

    private enum CodingKeys: String, CodingKey {
        case id, name, blurb, url, audiences, apps, countries
    }

    init(id: String, name: String, blurb: String, url: String,
         audiences: [String] = [], apps: [String], countries: [String] = ["*"]) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.url = url
        self.audiences = audiences
        self.apps = apps
        self.countries = countries
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        url = try c.decode(String.self, forKey: .url)
        audiences = try c.decodeIfPresent([String].self, forKey: .audiences) ?? []
        apps = try c.decodeIfPresent([String].self, forKey: .apps) ?? []
        countries = try c.decodeIfPresent([String].self, forKey: .countries) ?? ["*"]
    }

    var link: URL? { URL(string: url) }
}

/// The "Get help" feed, fetched from https://getgothere.app/api/help.json
/// (built from the site's `_help.json`). Only orgs that have agreed are in the feed,
/// so adding one is a site deploy, never an app release.
///
/// Plain GET, no personal data, no tracking params. The last good response is kept
/// on disk so the list still shows offline. Settings hides the entry while `orgs`
/// is empty.
@MainActor
final class HelpOrgs: ObservableObject {
    static let shared = HelpOrgs()

    static let appId = "gothere"
    static let feedURL = URL(string: "https://getgothere.app/api/help.json")!

    /// Orgs for this app, in feed order.
    @Published private(set) var orgs: [HelpOrg] = []

    private let cacheURL: URL
    private let session: URLSession
    private var lastFetch: Date?

    init(cacheURL: URL = HelpOrgs.defaultCacheURL, session: URLSession = .shared) {
        self.cacheURL = cacheURL
        self.session = session
        if let data = try? Data(contentsOf: cacheURL), let feed = try? Self.parse(data) {
            orgs = Self.filter(feed.orgs, appId: Self.appId)
        }
    }

    nonisolated static var defaultCacheURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("help_orgs_v1.json")
    }

    // MARK: - Parsing (pure, unit tested)

    struct Feed: Decodable {
        let version: Int?
        let orgs: [HelpOrg]

        private enum CodingKeys: String, CodingKey { case version, orgs }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            version = try c.decodeIfPresent(Int.self, forKey: .version)
            // One malformed org must not hide the others.
            let lossy = try c.decode([Lossy].self, forKey: .orgs)
            orgs = lossy.compactMap(\.value)
        }

        private struct Lossy: Decodable {
            let value: HelpOrg?
            init(from decoder: Decoder) throws {
                value = try? HelpOrg(from: decoder)
            }
        }
    }

    nonisolated static func parse(_ data: Data) throws -> Feed {
        try JSONDecoder().decode(Feed.self, from: data)
    }

    /// Orgs listed for `appId` with a usable https link. Countries are ignored in v1.
    nonisolated static func filter(_ orgs: [HelpOrg], appId: String) -> [HelpOrg] {
        orgs.filter { org in
            org.apps.contains(appId)
                && !org.name.isEmpty
                && org.url.lowercased().hasPrefix("https://")
                && org.link != nil
        }
    }

    // MARK: - Loading

    /// Applies a downloaded body. A good body replaces the list and the disk cache.
    /// A bad body leaves the current (cached) list alone. Returns true when applied.
    @discardableResult
    func ingest(_ data: Data) -> Bool {
        guard let feed = try? Self.parse(data) else { return false }
        orgs = Self.filter(feed.orgs, appId: Self.appId)
        try? FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
        return true
    }

    /// Cheap to call on every appear: after a good fetch, waits 10 minutes before the next.
    func refresh() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 600 { return }
        var request = URLRequest(url: Self.feedURL,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 8)
        request.httpMethod = "GET"
        do {
            let (data, resp) = try await session.data(for: request)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            if ingest(data) { lastFetch = Date() }
        } catch {
            // Offline or timed out: keep the cached list.
        }
    }
}
