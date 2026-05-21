import XCTest
@testable import GoThere

/// Wave 2 — Ancestry deepening. Verifies the `eligibilityRule` structured
/// metadata is wired on every ancestry track and that the inFlux flag is set
/// correctly for Italy (DL 36/2025) and Canada (Bill C-3). Drives the warning
/// banner on the Wizard intro and the Decision Tree explanation layer.
final class EligibilityRuleTests: XCTestCase {

    // MARK: - Codable roundtrip

    func test_eligibilityRule_decodeEncodeRoundtrip() throws {
        let original = EligibilityRule(
            summary: "Test summary",
            generationCutoff: 2,
            maternalLineCutoff: true,
            criteria: ["Criterion 1", "Criterion 2"],
            inFlux: true,
            inFluxNote: "Verify with a lawyer"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EligibilityRule.self, from: data)
        XCTAssertEqual(decoded.summary, original.summary)
        XCTAssertEqual(decoded.generationCutoff, original.generationCutoff)
        XCTAssertEqual(decoded.maternalLineCutoff, original.maternalLineCutoff)
        XCTAssertEqual(decoded.criteria, original.criteria)
        XCTAssertEqual(decoded.inFlux, original.inFlux)
        XCTAssertEqual(decoded.inFluxNote, original.inFluxNote)
    }

    func test_eligibilityRule_nilFieldsRoundtrip() throws {
        let original = EligibilityRule(
            summary: "Stable rule",
            generationCutoff: nil,
            maternalLineCutoff: false,
            criteria: [],
            inFlux: false,
            inFluxNote: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EligibilityRule.self, from: data)
        XCTAssertNil(decoded.generationCutoff)
        XCTAssertNil(decoded.inFluxNote)
        XCTAssertFalse(decoded.inFlux)
    }

    // MARK: - In-flux flag is true exactly where the brief expects

    func test_italyJureSanguinis_isInFlux() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let rule = config.tracks["it_jure_sanguinis"]?.eligibilityRule
        XCTAssertNotNil(rule, "Italy Jure Sanguinis must carry a structured EligibilityRule")
        XCTAssertEqual(rule?.inFlux, true, "Italy DL 36/2025 + Law 74/2025 + Constitutional Court Ruling 63/2026 — in flux until the dust settles")
        XCTAssertNotNil(rule?.inFluxNote, "inFluxNote must explain WHAT is changing so the banner is informative")
        XCTAssertEqual(rule?.generationCutoff, 2, "Post-DL 36/2025 limits the line to parent or grandparent")
        XCTAssertTrue(rule?.maternalLineCutoff ?? false, "1948 maternal-line carve-out is core to the Italian story")
    }

    func test_canadaDescent_isInFlux() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let rule = config.tracks["ca_descent"]?.eligibilityRule
        XCTAssertNotNil(rule, "Canada by-descent track must carry an EligibilityRule")
        XCTAssertEqual(rule?.inFlux, true, "Bill C-3 came into force 15 December 2025 — still settling")
        XCTAssertNotNil(rule?.inFluxNote)
    }

    // MARK: - Stable ancestry tracks must NOT be marked in-flux

    func test_irelandFBR_isNotInFlux() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let rule = config.tracks["ie_fbr"]?.eligibilityRule
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.inFlux, false, "Irish FBR rules are stable — banner would create false alarm")
    }

    func test_otherAncestryTracks_carryEligibilityRules() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        for trackId in ["de_stag_15", "pl_confirmation", "uk_ancestry"] {
            let rule = config.tracks[trackId]?.eligibilityRule
            XCTAssertNotNil(rule, "\(trackId) must carry an EligibilityRule so Decision Tree can render the explanation layer")
            XCTAssertFalse(rule?.summary.isEmpty ?? true)
            XCTAssertFalse(rule?.criteria.isEmpty ?? true, "criteria array must be non-empty — drives the bullet list in the Wizard intro card")
        }
    }

    // MARK: - Real Journey wiring

    func test_italyRealJourneyExists() {
        let journey = RealJourneys.forVisa("it_jure_sanguinis")
        XCTAssertNotNil(journey)
        XCTAssertEqual(journey?.countryId, "italy")
        XCTAssertGreaterThanOrEqual(journey?.phases.count ?? 0, 5, "Italy journey walks eligibility → docs → apostille → translation → filing → registration")
    }

    func test_irelandRealJourneyExists() {
        let journey = RealJourneys.forVisa("ie_fbr")
        XCTAssertNotNil(journey)
        XCTAssertEqual(journey?.countryId, "ireland")
        XCTAssertGreaterThanOrEqual(journey?.phases.count ?? 0, 5)
    }

    // MARK: - Backward-compat smoke

    func test_legacyTrackDecodesWithNilEligibilityRule() throws {
        let legacy = """
        {
          "wizardVersion": 2,
          "tracks": {
            "es_work": {
              "displayName": "Spain Work",
              "countryId": "spain",
              "shortName": "Work",
              "steps": [],
              "taskRules": []
            }
          }
        }
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(WizardConfig.self, from: legacy)
        XCTAssertNil(config.tracks["es_work"]?.eligibilityRule, "Tracks without an eligibilityRule must decode with nil — not throw")
    }
}
