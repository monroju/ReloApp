import XCTest
@testable import GoThere

/// Foundation Wave 1 migration tests. The schema bump added optional fields
/// to `DocumentSlot` and `EventItem`. Existing Firestore docs written before
/// the bump must decode safely. These tests assert backward compatibility
/// by decoding JSON shaped like the old payload.
final class SchemaMigrationTests: XCTestCase {

    // MARK: - DocumentSlot

    func test_legacyDocumentSlotJson_decodesWithNilNewFields() throws {
        // Payload as written before Foundation Wave 1 — no enrichment fields.
        let legacyJson = """
        {
            "id": "slot_abc",
            "key": "fbi_check",
            "label": "FBI",
            "countryId": "spain",
            "visaTrackId": "es_nlv",
            "status": "pending",
            "generatedAt": -978307200
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let slot = try decoder.decode(DocumentSlot.self, from: legacyJson)

        XCTAssertEqual(slot.key, "fbi_check")
        XCTAssertEqual(slot.status, .pending)
        // New fields must default to nil — not crash, not throw.
        XCTAssertNil(slot.whereToObtain)
        XCTAssertNil(slot.validityPeriod)
        XCTAssertNil(slot.apostilleRequired)
        XCTAssertNil(slot.swornTranslationRequired)
        XCTAssertNil(slot.sourceTaskRuleKey)
    }

    func test_enrichedDocumentSlotJson_decodesWithFields() throws {
        let enrichedJson = """
        {
            "id": "slot_abc",
            "key": "fbi_check",
            "label": "FBI Identity History Summary",
            "countryId": "spain",
            "visaTrackId": "es_nlv",
            "status": "pending",
            "generatedAt": -978307200,
            "whereToObtain": "FBI website or approved channeler",
            "validityPeriod": "90 days",
            "apostilleRequired": true,
            "swornTranslationRequired": true,
            "sourceTaskRuleKey": "es_fbi_check"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let slot = try decoder.decode(DocumentSlot.self, from: enrichedJson)
        XCTAssertEqual(slot.whereToObtain, "FBI website or approved channeler")
        XCTAssertEqual(slot.validityPeriod, "90 days")
        XCTAssertEqual(slot.apostilleRequired, true)
        XCTAssertEqual(slot.swornTranslationRequired, true)
        XCTAssertEqual(slot.sourceTaskRuleKey, "es_fbi_check")
    }

    // MARK: - EventItem

    func test_legacyEventItemJson_decodesWithNilNewFields() throws {
        let legacyJson = """
        {
            "id": "evt_abc",
            "title": "FBI background check expires",
            "dateMillis": 1750000000000,
            "createdAt": 750000000,
            "source": "wizard"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let event = try decoder.decode(EventItem.self, from: legacyJson)
        XCTAssertEqual(event.source, "wizard")
        XCTAssertNil(event.category)
        XCTAssertNil(event.daysOffsetFromAnchor)
        XCTAssertNil(event.notificationEnabled)
        XCTAssertNil(event.visaTrackId)
        // Falls back to .milestone when category is missing.
        XCTAssertEqual(event.resolvedCategory, .milestone)
    }

    func test_enrichedEventItemJson_decodesAndResolvesCategory() throws {
        let enrichedJson = """
        {
            "id": "evt_xyz",
            "title": "Consulate appointment",
            "dateMillis": 1750000000000,
            "createdAt": 750000000,
            "source": "wizard",
            "category": "appointment",
            "daysOffsetFromAnchor": 0,
            "notificationEnabled": true,
            "visaTrackId": "es_non_lucrative"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let event = try decoder.decode(EventItem.self, from: enrichedJson)
        XCTAssertEqual(event.category, "appointment")
        XCTAssertEqual(event.daysOffsetFromAnchor, 0)
        XCTAssertEqual(event.notificationEnabled, true)
        XCTAssertEqual(event.visaTrackId, "es_non_lucrative")
        XCTAssertEqual(event.resolvedCategory, .appointment)
    }

    func test_resolvedCategory_unknownCategoryFallsBackToMilestone() {
        var event = EventItem(title: "x")
        event.category = "frobnicate"  // not a known case
        XCTAssertEqual(event.resolvedCategory, .milestone)
    }
}
