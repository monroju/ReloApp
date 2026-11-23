import XCTest
@testable import GoThere

/// "Get help" feed (growth-plan 08). Decoding, app filter, empty list hides the
/// Settings entry, unknown fields ignored, malformed JSON falls back to the disk cache.
@MainActor
final class HelpOrgsTests: XCTestCase {

    private var cacheURL: URL!

    override func setUp() {
        super.setUp()
        cacheURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("help_orgs_test_\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: cacheURL)
        super.tearDown()
    }

    private func data(_ json: String) -> Data { Data(json.utf8) }

    private let specSample = """
    {
      "version": 1,
      "updated": "2026-11-12",
      "orgs": [
        {
          "id": "rainbow-railroad",
          "name": "Rainbow Railroad",
          "blurb": "Helps LGBTQI+ people at risk find a way to safety.",
          "url": "https://www.rainbowrailroad.org",
          "audiences": ["lgbtq"],
          "apps": ["gothere", "localista"],
          "countries": ["*"]
        }
      ]
    }
    """

    // MARK: - Decoding

    func test_parse_specSample() throws {
        let feed = try HelpOrgs.parse(data(specSample))
        XCTAssertEqual(feed.version, 1)
        XCTAssertEqual(feed.orgs.count, 1)
        let org = try XCTUnwrap(feed.orgs.first)
        XCTAssertEqual(org.id, "rainbow-railroad")
        XCTAssertEqual(org.name, "Rainbow Railroad")
        XCTAssertEqual(org.url, "https://www.rainbowrailroad.org")
        XCTAssertEqual(org.audiences, ["lgbtq"])
        XCTAssertEqual(org.apps, ["gothere", "localista"])
        XCTAssertEqual(org.countries, ["*"])
    }

    func test_parse_ignoresUnknownFields() throws {
        let json = """
        {"version": 2, "future": {"x": 1}, "orgs": [
          {"id": "a", "name": "A", "blurb": "b", "url": "https://a.org",
           "apps": ["gothere"], "logo": "https://a.org/logo.png", "priority": 3}
        ]}
        """
        let feed = try HelpOrgs.parse(data(json))
        XCTAssertEqual(feed.orgs.map(\.id), ["a"])
    }

    func test_parse_optionalFieldsDefault() throws {
        let json = #"{"orgs": [{"id": "a", "name": "A", "url": "https://a.org", "apps": ["gothere"]}]}"#
        let org = try XCTUnwrap(HelpOrgs.parse(data(json)).orgs.first)
        XCTAssertEqual(org.blurb, "")
        XCTAssertEqual(org.audiences, [])
        XCTAssertEqual(org.countries, ["*"])
    }

    func test_parse_skipsMalformedOrgButKeepsOthers() throws {
        let json = """
        {"orgs": [
          {"id": "bad", "name": 42},
          {"id": "good", "name": "Good", "url": "https://good.org", "apps": ["gothere"]}
        ]}
        """
        XCTAssertEqual(try HelpOrgs.parse(data(json)).orgs.map(\.id), ["good"])
    }

    func test_parse_emptyOrgs() throws {
        let feed = try HelpOrgs.parse(data(#"{"version": 1, "updated": "2026-11-12", "orgs": []}"#))
        XCTAssertTrue(feed.orgs.isEmpty)
    }

    func test_parse_malformedThrows() {
        XCTAssertThrowsError(try HelpOrgs.parse(data("{not json")))
        XCTAssertThrowsError(try HelpOrgs.parse(data(#"{"version": 1}"#)))
    }

    // MARK: - Filtering

    func test_filter_keepsOnlyThisApp() {
        let orgs = [
            HelpOrg(id: "both", name: "Both", blurb: "", url: "https://both.org", apps: ["gothere", "localista"]),
            HelpOrg(id: "loc", name: "Loc", blurb: "", url: "https://loc.org", apps: ["localista"]),
            HelpOrg(id: "none", name: "None", blurb: "", url: "https://none.org", apps: []),
            HelpOrg(id: "go", name: "Go", blurb: "", url: "https://go.org", apps: ["gothere"])
        ]
        XCTAssertEqual(HelpOrgs.filter(orgs, appId: "gothere").map(\.id), ["both", "go"])
    }

    func test_filter_dropsNonHttpsLinks() {
        let orgs = [
            HelpOrg(id: "http", name: "Http", blurb: "", url: "http://plain.org", apps: ["gothere"]),
            HelpOrg(id: "js", name: "Js", blurb: "", url: "javascript:alert(1)", apps: ["gothere"]),
            HelpOrg(id: "ok", name: "Ok", blurb: "", url: "https://ok.org", apps: ["gothere"])
        ]
        XCTAssertEqual(HelpOrgs.filter(orgs, appId: "gothere").map(\.id), ["ok"])
    }

    // MARK: - Store (entry visibility + cache)

    func test_emptyFeed_leavesListEmpty_soEntryIsHidden() {
        let store = HelpOrgs(cacheURL: cacheURL)
        XCTAssertTrue(store.orgs.isEmpty)
        XCTAssertTrue(store.ingest(data(#"{"version": 1, "orgs": []}"#)))
        XCTAssertTrue(store.orgs.isEmpty)
    }

    func test_feedForOtherAppOnly_leavesListEmpty() {
        let store = HelpOrgs(cacheURL: cacheURL)
        let json = #"{"orgs": [{"id": "a", "name": "A", "url": "https://a.org", "apps": ["localista"]}]}"#
        XCTAssertTrue(store.ingest(data(json)))
        XCTAssertTrue(store.orgs.isEmpty)
    }

    func test_goodFeed_publishesAndCaches() {
        let store = HelpOrgs(cacheURL: cacheURL)
        XCTAssertTrue(store.ingest(data(specSample)))
        XCTAssertEqual(store.orgs.map(\.id), ["rainbow-railroad"])

        // A fresh store (next launch, offline) reads the cache.
        let relaunched = HelpOrgs(cacheURL: cacheURL)
        XCTAssertEqual(relaunched.orgs.map(\.id), ["rainbow-railroad"])
    }

    func test_malformedFeed_fallsBackToCache() {
        let first = HelpOrgs(cacheURL: cacheURL)
        XCTAssertTrue(first.ingest(data(specSample)))

        let store = HelpOrgs(cacheURL: cacheURL)
        XCTAssertFalse(store.ingest(data("<html>502 Bad Gateway</html>")))
        XCTAssertEqual(store.orgs.map(\.id), ["rainbow-railroad"])

        // The bad body must not overwrite the cache either.
        let relaunched = HelpOrgs(cacheURL: cacheURL)
        XCTAssertEqual(relaunched.orgs.map(\.id), ["rainbow-railroad"])
    }

    func test_corruptCache_startsEmpty() throws {
        try data("garbage").write(to: cacheURL)
        XCTAssertTrue(HelpOrgs(cacheURL: cacheURL).orgs.isEmpty)
    }
}
