import XCTest
@testable import GoThere

/// Foundation Wave 1: WizardConfig must decode the new top-level
/// `anchorDateQuestion`, `documentSlot` enriched fields, and `milestones` arrays.
/// Tests use an in-memory fixture to avoid coupling to the host-app bundle —
/// the bundled config is exercised at app launch, and a smoke-test below uses
/// XCTSkip when the bundle is unavailable to the test target.
final class WizardConfigDecodeTests: XCTestCase {

    private let fixtureJson = """
    {
      "wizardVersion": 2,
      "anchorDateQuestion": {
        "id": "anchor_date",
        "label": "Target application date",
        "hint": "Pick the date you'd like to submit.",
        "defaultOffsetDays": 90
      },
      "tracks": {
        "es_non_lucrative": {
          "displayName": "Spain NLV",
          "countryId": "spain",
          "shortName": "NLV",
          "steps": [],
          "taskRules": [
            {
              "taskTitle": "Request FBI Identity History Summary",
              "phase": "Phase 2",
              "description": "From FBI website",
              "conditions": {},
              "estimatedWeeks": 20,
              "order": 1,
              "documentSlot": {
                "key": "es_fbi_check",
                "label": "FBI Identity History Summary",
                "description": "From the FBI",
                "whereToObtain": "FBI website",
                "validityPeriod": "90 days",
                "apostilleRequired": true,
                "swornTranslationRequired": true
              },
              "milestones": [
                {
                  "key": "fbi_check_expiry",
                  "title": "FBI background check expires",
                  "description": "90-day window",
                  "category": "expiration",
                  "daysOffsetFromAnchor": -90,
                  "notificationEnabled": true
                }
              ]
            }
          ]
        }
      }
    }
    """.data(using: .utf8)!

    func test_fixtureDecodes_withAnchorDateQuestion() throws {
        let config = try JSONDecoder().decode(WizardConfig.self, from: fixtureJson)
        XCTAssertEqual(config.wizardVersion, 2)
        XCTAssertNotNil(config.anchorDateQuestion)
        XCTAssertEqual(config.anchorDateQuestion?.id, "anchor_date")
        XCTAssertEqual(config.anchorDateQuestion?.defaultOffsetDays, 90)
    }

    func test_fixtureDecodes_withEnrichedDocumentSlot() throws {
        let config = try JSONDecoder().decode(WizardConfig.self, from: fixtureJson)
        let docSlot = config.tracks["es_non_lucrative"]?
            .taskRules.first?.documentSlot
        XCTAssertNotNil(docSlot)
        XCTAssertEqual(docSlot?.whereToObtain, "FBI website")
        XCTAssertEqual(docSlot?.validityPeriod, "90 days")
        XCTAssertEqual(docSlot?.apostilleRequired, true)
        XCTAssertEqual(docSlot?.swornTranslationRequired, true)
    }

    func test_fixtureDecodes_withMilestones() throws {
        let config = try JSONDecoder().decode(WizardConfig.self, from: fixtureJson)
        let milestone = config.tracks["es_non_lucrative"]?
            .taskRules.first?.milestones?.first
        XCTAssertNotNil(milestone)
        XCTAssertEqual(milestone?.key, "fbi_check_expiry")
        XCTAssertEqual(milestone?.category, "expiration")
        XCTAssertEqual(milestone?.daysOffsetFromAnchor, -90)
        XCTAssertEqual(milestone?.notificationEnabled, true)
    }

    func test_legacyV1Json_decodesWithNilAnchorAndMilestones() throws {
        // A v1 payload (no anchorDateQuestion, no milestones, plain documentSlot)
        // must still decode so users on an older app+config pairing don't crash.
        let legacy = """
        {
          "wizardVersion": 1,
          "tracks": {
            "es_dnv": {
              "displayName": "Spain DNV",
              "countryId": "spain",
              "shortName": "DNV",
              "steps": [],
              "taskRules": [
                {
                  "taskTitle": "Old task",
                  "phase": "Phase 1",
                  "conditions": {},
                  "estimatedWeeks": 4,
                  "order": 1
                }
              ]
            }
          }
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(WizardConfig.self, from: legacy)
        XCTAssertEqual(config.wizardVersion, 1)
        XCTAssertNil(config.anchorDateQuestion)
        XCTAssertNil(config.tracks["es_dnv"]?.taskRules.first?.milestones)
        XCTAssertNil(config.tracks["es_dnv"]?.taskRules.first?.documentSlot)
    }

    // Smoke test against the host-app bundle. Skipped if test target can't
    // see the bundled JSON (e.g. when run as a pure logic-test target without
    // the host app's resource bundle linked).
    func test_bundleConfig_loads_smoke() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target — exercised at app launch in QA.")
        }
        XCTAssertGreaterThanOrEqual(config.wizardVersion, 2)
        XCTAssertNotNil(config.tracks["es_non_lucrative"])
    }
}
