import XCTest
@testable import GoThere

/// Differentiation Wave — Document Vault expiration engine. Covers the pure
/// logic added this wave: filename → validity-rule matching, expiration math,
/// document urgency/status derivation, and the vault summary counts. UI,
/// Firestore, and UNUserNotificationCenter wiring are out of scope (integration).
final class DocumentVaultTests: XCTestCase {

    // MARK: - Validity-rule matching

    func test_match_fbiCheck_byKeyword() {
        let rule = DocumentValidityRules.match(fileName: "FBI_Identity_History_Summary.pdf")
        XCTAssertEqual(rule?.canonicalName, "FBI Background Check")
        XCTAssertEqual(rule?.validityDays, 90)
        XCTAssertEqual(rule?.apostilleRequired, true)
    }

    func test_match_prefersLongerKeyword() {
        // "state background" must win over a bare "background check".
        let rule = DocumentValidityRules.match(fileName: "California State Background Check.pdf")
        XCTAssertEqual(rule?.canonicalName, "State Criminal Background Check")
    }

    func test_match_unknownFile_returnsNil() {
        XCTAssertNil(DocumentValidityRules.match(fileName: "random_lease_agreement.pdf"))
    }

    func test_match_isCaseInsensitive() {
        XCTAssertEqual(DocumentValidityRules.match(fileName: "bank STATEMENTS jan.pdf")?.canonicalName,
                       "Bank Statements")
    }

    // MARK: - Expiration math

    func test_expiration_90Days_fromKnownDate() {
        let from = ISO8601DateFormatter().date(from: "2026-06-01T00:00:00Z")!
        let exp = DocumentValidityRules.expiration(from: from, validityDays: 90)
        let expected = Calendar.current.date(byAdding: .day, value: 90, to: from)
        XCTAssertEqual(exp, expected)
    }

    func test_expiration_nonExpiring_isNil() {
        XCTAssertNil(DocumentValidityRules.expiration(from: Date(), validityDays: 0))
    }

    // MARK: - Document urgency / status

    private func doc(daysFromNow: Int?, apostilleReq: Bool = false, apostilleDone: Bool = false) -> UserDocument {
        var d = UserDocument(id: "x", name: "Doc")
        if let days = daysFromNow {
            d.expirationDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        }
        d.apostilleRequired = apostilleReq
        d.apostilleDone = apostilleDone
        return d
    }

    func test_urgency_expired() {
        XCTAssertEqual(doc(daysFromNow: -1).urgency, .expired)
        XCTAssertTrue(doc(daysFromNow: -1).isExpired)
    }

    func test_urgency_expiringSoon_within30() {
        XCTAssertEqual(doc(daysFromNow: 14).urgency, .expiringSoon)
        XCTAssertTrue(doc(daysFromNow: 14).isExpiringSoon)
    }

    func test_urgency_ok_beyond30() {
        XCTAssertEqual(doc(daysFromNow: 120).urgency, .ok)
        XCTAssertFalse(doc(daysFromNow: 120).isExpiringSoon)
    }

    func test_urgency_attention_whenApostilleOutstanding() {
        // No expiry, but apostille required & not done → needs attention.
        XCTAssertEqual(doc(daysFromNow: nil, apostilleReq: true, apostilleDone: false).urgency, .attention)
    }

    func test_derivedStatus_expiredBeatsApostille() {
        XCTAssertEqual(doc(daysFromNow: -5, apostilleReq: true).derivedStatus, .expired)
    }

    func test_derivedStatus_complete_whenAllDone() {
        XCTAssertEqual(doc(daysFromNow: 200, apostilleReq: true, apostilleDone: true).derivedStatus, .complete)
    }

    func test_expiryLabel_phrasing() {
        XCTAssertEqual(doc(daysFromNow: 1).expiryLabel, "Expires in 1 day")
        XCTAssertEqual(doc(daysFromNow: 30).expiryLabel, "Expires in 30 days")
        XCTAssertEqual(doc(daysFromNow: nil).expiryLabel, "No expiry date")
    }

    func test_defaultReminders_areThirtyFourteenThree() {
        XCTAssertEqual(doc(daysFromNow: 60).effectiveReminderDays, [30, 14, 3])
    }

    // MARK: - Vault summary

    @MainActor
    func test_vaultSummary_countsBands() {
        let vm = DocumentsViewModel()
        var expired = UserDocument(id: "a", name: "Expired")
        expired.expirationDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        var soon = UserDocument(id: "b", name: "Soon")
        soon.expirationDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        var ok = UserDocument(id: "c", name: "OK")
        ok.expirationDate = Calendar.current.date(byAdding: .day, value: 200, to: Date())
        let loose = UserDocument(id: "d", name: "Loose no expiry") // not counted

        vm.documents = [expired, soon, ok, loose]
        vm.slots = []

        let s = vm.vaultSummary
        XCTAssertEqual(s.expired, 1)
        XCTAssertEqual(s.expiringSoon, 1)
        XCTAssertEqual(s.complete, 1)
        XCTAssertEqual(s.missing, 0)
        XCTAssertTrue(s.hasAnything)
    }

    @MainActor
    func test_vaultSummary_missingFromPendingSlots() {
        let vm = DocumentsViewModel()
        let slot = DocumentSlot(key: "fbi_check", label: "FBI Check", slotDescription: nil,
                                countryId: "spain", visaTrackId: "es_non_lucrative",
                                status: .pending, uploadedDocumentId: nil)
        vm.slots = [slot]
        vm.documents = []
        XCTAssertEqual(vm.vaultSummary.missing, 1)
    }
}
