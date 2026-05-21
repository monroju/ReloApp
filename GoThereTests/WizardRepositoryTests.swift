import XCTest
@testable import GoThere

/// Foundation Wave 1 tests for the wizard repository — slot generation,
/// milestone generation, and condition evaluation. Pure-function tests, no
/// Firestore or UI involved.
final class WizardRepositoryTests: XCTestCase {

    // MARK: - Fixture builders

    /// Builds a minimal wizard track in-memory so tests don't depend on the
    /// bundled wizard_config.json. Lets us assert structural behavior without
    /// the config drift risk.
    private func makeTrack(
        countryId: String = "spain",
        documentSlot: DocumentSlotRule? = nil,
        milestones: [MilestoneRule]? = nil,
        conditions: [String: AnyCodableValue] = [:]
    ) -> WizardTrack {
        let rule = TaskRule(
            taskTitle: "Test task",
            phase: "Phase 1: Research",
            description: "for unit test",
            links: nil,
            conditions: conditions,
            estimatedWeeks: 4,
            order: 1,
            documentSlot: documentSlot,
            milestones: milestones
        )
        return WizardTrack(
            displayName: "Test track",
            countryId: countryId,
            shortName: "TEST",
            steps: [],
            taskRules: [rule]
        )
    }

    // MARK: - DocumentSlot generation

    func test_generateSlots_carriesEnrichedFields() {
        let docSlot = DocumentSlotRule(
            key: "test_key",
            label: "Test doc",
            description: "legacy desc",
            whereToObtain: "From the relevant authority",
            validityPeriod: "Valid 90 days",
            apostilleRequired: true,
            swornTranslationRequired: false
        )
        let track = makeTrack(documentSlot: docSlot)

        let slots = WizardRepository.shared.generateSlots(
            track: track, trackId: "test_track", answers: [:]
        )

        XCTAssertEqual(slots.count, 1)
        let s = slots[0]
        XCTAssertEqual(s.whereToObtain, "From the relevant authority")
        XCTAssertEqual(s.validityPeriod, "Valid 90 days")
        XCTAssertEqual(s.apostilleRequired, true)
        XCTAssertEqual(s.swornTranslationRequired, false)
        XCTAssertEqual(s.sourceTaskRuleKey, "test_key")
        XCTAssertEqual(s.firestoreId, "test_track__test_key")
    }

    func test_generateSlots_idempotentFirestoreIds() {
        // Re-running the wizard with identical inputs must yield identical
        // firestoreIds so the upsert merge in DocumentsRepository doesn't
        // create duplicate slots.
        let docSlot = DocumentSlotRule(
            key: "fbi",
            label: "FBI",
            description: nil,
            whereToObtain: nil,
            validityPeriod: nil,
            apostilleRequired: nil,
            swornTranslationRequired: nil
        )
        let track = makeTrack(documentSlot: docSlot)

        let first = WizardRepository.shared.generateSlots(track: track, trackId: "tr", answers: [:])
        let second = WizardRepository.shared.generateSlots(track: track, trackId: "tr", answers: [:])

        XCTAssertEqual(first.map(\.firestoreId), second.map(\.firestoreId))
    }

    // MARK: - Milestone generation

    func test_generateMilestones_appliesDayOffsetFromAnchor() {
        let anchor = ISO8601DateFormatter().date(from: "2026-06-15T00:00:00Z")!
        let m = MilestoneRule(
            key: "fbi_expiry",
            title: "FBI expires",
            description: "test",
            category: "expiration",
            daysOffsetFromAnchor: -90,
            notificationEnabled: true
        )
        let track = makeTrack(milestones: [m])

        let result = WizardRepository.shared.generateMilestones(
            track: track, trackId: "tr", answers: [:], anchorDate: anchor
        )

        XCTAssertEqual(result.count, 1)
        let expected = Calendar.current.date(byAdding: .day, value: -90, to: anchor)!
        XCTAssertEqual(result[0].event.date.timeIntervalSince1970,
                       expected.timeIntervalSince1970,
                       accuracy: 1.0)
        XCTAssertEqual(result[0].event.category, "expiration")
        XCTAssertEqual(result[0].event.notificationEnabled, true)
        XCTAssertEqual(result[0].event.visaTrackId, "tr")
        XCTAssertEqual(result[0].event.id, "milestone_tr_fbi_expiry")
    }

    func test_generateMilestones_idempotentEventIds() {
        // Two runs against the same track + anchor must produce identical
        // event ids so EventsRepository.addEventFromMilestone upserts.
        let anchor = Date()
        let m = MilestoneRule(
            key: "consulate", title: "Consulate appt", description: nil,
            category: "appointment", daysOffsetFromAnchor: 0,
            notificationEnabled: false
        )
        let track = makeTrack(milestones: [m])

        let first = WizardRepository.shared.generateMilestones(
            track: track, trackId: "tr", answers: [:], anchorDate: anchor
        )
        let second = WizardRepository.shared.generateMilestones(
            track: track, trackId: "tr", answers: [:], anchorDate: anchor
        )

        XCTAssertEqual(first.map { $0.event.id }, second.map { $0.event.id })
    }

    // MARK: - Condition evaluation

    func test_evaluateConditions_filtersOutNonMatchingRules() {
        // Rule conditioned on has_check=true should not emit when answer is false.
        let track = makeTrack(
            milestones: [MilestoneRule(
                key: "k", title: "t", description: nil, category: "milestone",
                daysOffsetFromAnchor: 0, notificationEnabled: false
            )],
            conditions: ["has_check": .bool(true)]
        )
        let result = WizardRepository.shared.generateMilestones(
            track: track, trackId: "tr",
            answers: ["has_check": false],
            anchorDate: Date()
        )
        XCTAssertTrue(result.isEmpty)
    }
}
