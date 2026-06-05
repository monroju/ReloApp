import XCTest
@testable import GoThere

/// Differentiation Wave — Co-Pilot dashboard intelligence. Exercises the pure
/// engine: readiness scoring (with weight renormalization), and every insight
/// card branch. No UI / store access — all inputs are hand-built UserMoveState.
final class CoPilotEngineTests: XCTestCase {

    /// A real income-tested visa from the catalog (avoids brittle hard-coded ids).
    private var incomeVisa: VisaInfo {
        VisaCatalog.all.first { $0.monthlyIncomeEUR != nil }!
    }
    private var pointsVisa: VisaInfo? {
        VisaCatalog.all.first { $0.monthlyIncomeEUR == nil }
    }

    // MARK: - Readiness

    func test_readiness_emptyState_isSetupLabel() {
        let r = CoPilotEngine.readiness(UserMoveState())
        XCTAssertEqual(r.value, 0)
        XCTAssertEqual(r.label, "Let's set up your move")
    }

    func test_readiness_onlyTasks_usesRenormalizedWeight() {
        var s = UserMoveState()
        s.taskTotal = 10
        s.taskCompleted = 5
        // Only the task component has data → renormalized to 100% of weight.
        XCTAssertEqual(CoPilotEngine.readiness(s).value, 50)
    }

    func test_readiness_band_labels() {
        var s = UserMoveState()
        s.taskTotal = 10; s.taskCompleted = 9
        XCTAssertEqual(CoPilotEngine.readiness(s).label, "You're well-prepared")
        s.taskCompleted = 6
        XCTAssertEqual(CoPilotEngine.readiness(s).label, "A few things need attention")
        s.taskCompleted = 2
        XCTAssertEqual(CoPilotEngine.readiness(s).label, "Action required before your target date")
    }

    func test_docScore_expiringIsHalfCredit() {
        var s = UserMoveState()
        s.docComplete = 1; s.docExpiringSoon = 1 // credit 1.5 / 2 = 0.75
        XCTAssertEqual(CoPilotEngine.docScore(s)!, 0.75, accuracy: 0.001)
    }

    func test_incomeScore_pointsBasedVisa_isFullCredit() throws {
        let points = try XCTUnwrap(pointsVisa)
        var s = UserMoveState()
        s.selectedVisa = points
        XCTAssertEqual(CoPilotEngine.incomeScore(s), 1.0)
    }

    func test_incomeScore_nilWhenNoEstimate() {
        var s = UserMoveState()
        s.selectedVisa = incomeVisa
        // income-tested visa but no calculator estimate → not scorable yet
        XCTAssertNil(CoPilotEngine.incomeScore(s))
    }

    // MARK: - Setup cards

    func test_setupCards_whenNothingConfigured() {
        let cards = CoPilotEngine.generateInsightCards(UserMoveState())
        let ids = Set(cards.map(\.id))
        XCTAssertTrue(ids.contains("setup_visa"))
        XCTAssertTrue(ids.contains("setup_date"))
        XCTAssertTrue(ids.contains("setup_cost"))
    }

    // MARK: - Document cards

    func test_documentCards_expiredIsRed_andBeforeExpiring() {
        var s = UserMoveState()
        s.selectedVisa = incomeVisa
        s.targetMoveDate = Calendar.current.date(byAdding: .day, value: 90, to: Date())
        s.estimatedMonthlyCostEUR = 9_999
        s.expiringDocuments = [
            .init(name: "FBI Background Check", daysUntil: -3),
            .init(name: "Medical Certificate", daysUntil: 20)
        ]
        let cards = CoPilotEngine.generateInsightCards(s)
        let docCards = cards.filter { $0.id.hasPrefix("doc_") }
        XCTAssertEqual(docCards.first?.message.contains("FBI"), true)
        XCTAssertEqual(docCards.first?.severity, .red) // expired sorts first
    }

    func test_documentCards_missingCount() {
        var s = UserMoveState()
        s.docMissing = 3
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "doc_missing" }
        XCTAssertNotNil(card)
        XCTAssertTrue(card!.title.contains("3"))
    }

    // MARK: - Income cards

    func test_incomeCard_gap_whenBudgetBelowRequirement() {
        var s = UserMoveState()
        s.selectedVisa = incomeVisa
        s.estimatedMonthlyCostEUR = 1   // far below any threshold
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "income_gap" }
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.severity, .amber)
    }

    func test_incomeCard_surplus_whenBudgetAboveRequirement() {
        var s = UserMoveState()
        s.selectedVisa = incomeVisa
        s.estimatedMonthlyCostEUR = 1_000_000 // above any threshold
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "income_ok" }
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.severity, .green)
    }

    // MARK: - Timeline cards

    private func behindState() -> UserMoveState {
        var s = UserMoveState()
        s.taskTotal = 10
        s.taskCompleted = 2
        s.earliestTaskDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        s.targetMoveDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) // 1 week left
        return s
    }

    func test_timelineCard_behind_isRed() {
        let card = CoPilotEngine.generateInsightCards(behindState()).first { $0.id == "timeline_behind" }
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.severity, .red)
    }

    func test_timelineCard_onTrack_isGreen() {
        var s = behindState()
        s.targetMoveDate = Calendar.current.date(byAdding: .day, value: 300, to: Date()) // lots of time
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "timeline_ontrack" }
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.severity, .green)
    }

    func test_timelineCard_pastTarget_promptsUpdate() {
        var s = UserMoveState()
        s.taskTotal = 5; s.taskCompleted = 1
        s.targetMoveDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "timeline_past" }
        XCTAssertNotNil(card)
    }

    func test_projectedWeeks_nilWhenNothingCompleted() {
        var s = UserMoveState()
        s.taskTotal = 5; s.taskCompleted = 0
        s.earliestTaskDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        XCTAssertNil(CoPilotEngine.projectedWeeksToFinish(s))
    }

    // MARK: - Cita + ready + ordering

    func test_citaCard_whenMonitorsActive() {
        var s = UserMoveState()
        s.activeCitaMonitors = 2
        s.citaSample = "NIE — Initial · Madrid"
        let card = CoPilotEngine.generateInsightCards(s).first { $0.id == "cita_active" }
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.severity, .green)
    }

    func test_readyCard_onlyWhenDocsCleanAndPresent() {
        var s = UserMoveState()
        s.docComplete = 2 // nothing expiring/expired/missing
        XCTAssertNotNil(CoPilotEngine.generateInsightCards(s).first { $0.id == "docs_ready" })
        s.docExpiringSoon = 1
        XCTAssertNil(CoPilotEngine.generateInsightCards(s).first { $0.id == "docs_ready" })
    }

    func test_cards_sortedRedAmberGreen() {
        var s = UserMoveState()
        s.expiringDocuments = [.init(name: "X", daysUntil: -1)] // red
        s.docMissing = 1                                        // amber
        s.activeCitaMonitors = 1                                // green
        let severities = CoPilotEngine.generateInsightCards(s).map(\.severity)
        XCTAssertEqual(severities, severities.sorted())
    }
}
