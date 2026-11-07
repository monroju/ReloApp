import XCTest
@testable import GoThere

/// Plan B (growth/PLAN_B_SPEC.md). Score math must match the shared reference in
/// the parent repo (`shared/data/planb_score.py`); the vectors are copied into
/// Fixtures/ and must be refreshed whenever the reference changes.
final class PlanBScoreTests: XCTestCase {

    private func vectors() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/planb_score_vectors.json")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// Vector paths carry only the fields the score reads.
    private func path(from dict: [String: Any]) -> PlanBPath {
        let items = (dict["items"] as? [[String: Any]] ?? []).enumerated().map { i, item in
            PlanBPath.Item(id: "\(i)", personRole: "self", kind: "birth_cert",
                           state: PlanBDocState(rawValue: item["state"] as? String ?? "") ?? .notStarted,
                           skipped: item["skipped"] as? Bool)
        }
        var visa: PlanBPath.Visa?
        if let v = dict["visa"] as? [String: Any] {
            visa = PlanBPath.Visa(incomeFit: v["incomeFit"] as? Double, savingsGoalSet: v["savingsGoalSet"] as? Bool)
        }
        return PlanBPath(id: UUID().uuidString, type: dict["type"] as? String ?? "descent", countryCode: "xx",
                         pathwayId: "xx_test", createdAt: "", planMode: "planB", lineage: [], items: items,
                         stage: .gather, filedOn: dict["filedOn"] as? String,
                         appointmentOn: dict["appointmentOn"] as? String, visa: visa)
    }

    func test_pathScores_matchSharedVectors() throws {
        let cases = try XCTUnwrap(vectors()["paths"] as? [[String: Any]])
        XCTAssertGreaterThan(cases.count, 10)
        for c in cases {
            let p = path(from: try XCTUnwrap(c["path"] as? [String: Any]))
            XCTAssertEqual(PlanBScore.path(p), c["score"] as? Int, c["name"] as? String ?? "")
        }
    }

    func test_overallScores_matchSharedVectors() throws {
        let cases = try XCTUnwrap(vectors()["overall"] as? [[String: Any]])
        for c in cases {
            let paths = (c["paths"] as? [[String: Any]] ?? []).map(path(from:))
            XCTAssertEqual(PlanBScore.overall(paths), c["score"] as? Int, c["name"] as? String ?? "")
        }
    }

    func test_buckets() {
        XCTAssertEqual([0, 1, 30, 60, 90, 100].map(PlanBScore.bucket), ["0", "1-24", "25-49", "50-74", "75-99", "100"])
    }
}

final class DescentChainTests: XCTestCase {

    func test_bundledChains_load() throws {
        let repo = DescentChainRepository()
        let bundle = try XCTUnwrap(repo.bundle, "descent_chains.json missing from the app bundle or failed to decode")
        XCTAssertEqual(Set(bundle.chains.keys), [
            "ie_foreign_births_register", "it_jure_sanguinis", "de_stag",
            "pl_citizenship_confirmation", "hu_simplified_naturalization",
        ])
        XCTAssertFalse(repo.disclaimer.isEmpty)
    }

    func test_everyCheckerPath_hasAChain() {
        let repo = DescentChainRepository()
        for path in AncestryRepository.shared.paths {
            XCTAssertNotNil(repo.chain(forAncestryPathId: path.id), "no Plan B chain for \(path.id)")
        }
    }

    func test_everyOrderHintId_resolves() throws {
        let repo = DescentChainRepository()
        for chain in try XCTUnwrap(repo.bundle).chains.values {
            for doc in chain.documents {
                XCTAssertEqual(repo.hints(for: chain, ids: doc.orderHintIds).count, doc.orderHintIds.count,
                               "\(chain.pathwayId)/\(doc.kind)")
            }
        }
    }

    func test_builder_dropsRolesAboveAncestor() throws {
        let chain = try XCTUnwrap(DescentChainRepository().chain(pathwayId: "ie_foreign_births_register"))
        let parentLine = PlanBChainBuilder.items(for: chain, ancestor: .parent)
        XCTAssertFalse(parentLine.contains { $0.personRole == "grandparent" })
        let grandLine = PlanBChainBuilder.items(for: chain, ancestor: .grandparent)
        XCTAssertTrue(grandLine.contains { $0.personRole == "grandparent" })
        XCTAssertEqual(Set(grandLine.map(\.id)).count, grandLine.count, "item ids must be unique")
        for item in grandLine {
            XCTAssertNotNil(PlanBChainBuilder.document(for: item, in: chain), item.id)
        }
    }

    func test_ancestorChoices_respectMaxRole() throws {
        let it = try XCTUnwrap(DescentChainRepository().chain(pathwayId: "it_jure_sanguinis"))
        XCTAssertEqual(it.ancestorChoices, [.parent, .grandparent])
    }
}

@MainActor
final class PlanBStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "gothere.tests.planb"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func test_track_persistsAndIsIdempotent() throws {
        let chain = try XCTUnwrap(DescentChainRepository().chain(pathwayId: "ie_foreign_births_register"))
        let store = PlanBStore(defaults: defaults)
        let first = store.trackDescent(chain: chain, ancestor: .grandparent)
        store.trackDescent(chain: chain, ancestor: .grandparent)
        XCTAssertEqual(store.paths.count, 1)
        XCTAssertEqual(first.lineage.map(\.role), [.me, .parent, .grandparent])
        XCTAssertEqual(PlanBStore(defaults: defaults).paths, store.paths, "reloads from defaults")
    }

    func test_stateChanges_moveTheScore() throws {
        let chain = try XCTUnwrap(DescentChainRepository().chain(pathwayId: "ie_foreign_births_register"))
        let store = PlanBStore(defaults: defaults)
        let path = store.trackDescent(chain: chain, ancestor: .grandparent)
        XCTAssertEqual(store.overallScore, 0)
        for item in path.items { store.setState(.done, itemId: item.id, in: path.id) }
        XCTAssertEqual(store.overallScore, 70)
        store.setFiled(Date(), in: path.id)
        store.setAppointment(Date(), in: path.id)
        XCTAssertEqual(store.overallScore, 100)
    }

    func test_ordered_stampsDate_andSkippedLeavesDenominator() throws {
        let chain = try XCTUnwrap(DescentChainRepository().chain(pathwayId: "ie_foreign_births_register"))
        let store = PlanBStore(defaults: defaults)
        let path = store.trackDescent(chain: chain, ancestor: .grandparent)
        let item = try XCTUnwrap(path.items.first)
        store.setState(.ordered, itemId: item.id, in: path.id)
        XCTAssertNotNil(store.paths[0].items[0].orderedOn)
        let total = store.paths[0].activeItems.count
        store.setSkipped(true, itemId: item.id, in: path.id)
        XCTAssertEqual(store.paths[0].activeItems.count, total - 1)
    }

    func test_planBIntent_setsMode() {
        let store = PlanBStore(defaults: defaults)
        XCTAssertFalse(store.isPlanBMode)
        store.selectPlanBIntent(source: "test")
        XCTAssertTrue(store.isPlanBMode)
    }
}

final class RuleTopicTests: XCTestCase {

    func test_free_destinationOnlyWithoutPlanB() {
        XCTAssertEqual(PushNotificationService.desiredRuleTopics(destinationId: DestinationConfig.spain,
                                                                 planBCodes: [], allAccess: false), ["rules_es"])
    }

    func test_free_firstPlanBCountryReplacesDestination() {
        XCTAssertEqual(PushNotificationService.desiredRuleTopics(destinationId: DestinationConfig.spain,
                                                                 planBCodes: ["de", "ie", "it"], allAccess: false),
                       ["rules_ie"], "de has no alert list, so the first alertable path wins")
    }

    func test_allAccess_destinationPlusEveryPath_noDuplicates() {
        XCTAssertEqual(PushNotificationService.desiredRuleTopics(destinationId: DestinationConfig.ireland,
                                                                 planBCodes: ["ie", "it"], allAccess: true),
                       ["rules_ie", "rules_it"])
    }
}
