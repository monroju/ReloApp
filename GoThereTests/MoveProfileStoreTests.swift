import XCTest
@testable import GoThere

/// Differentiation Wave — persistence prerequisite. The dashboard relies on
/// `estimatedMonthlyCostEUR` returning nil ("never opened the calculator") vs a
/// real value, to decide whether to show the setup nudge.
final class MoveProfileStoreTests: XCTestCase {

    private let keys = [
        "gothere.move.estimatedMonthlyCostEUR", "gothere.move.costCity",
        "gothere.move.costCountry", "gothere.move.dependents",
        "gothere.move.costUpdatedAt", "target_move_millis"
    ]

    override func setUp() {
        super.setUp()
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
    override func tearDown() {
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func test_estimatedCost_nilWhenNeverSet() {
        XCTAssertNil(MoveProfileStore.estimatedMonthlyCostEUR)
    }

    func test_estimatedCost_zeroIsDistinctFromNil() {
        MoveProfileStore.saveEstimatedCost(eur: 0, city: "Madrid", country: "spain", dependents: 0)
        XCTAssertEqual(MoveProfileStore.estimatedMonthlyCostEUR, 0)
        XCTAssertNotNil(MoveProfileStore.estimatedMonthlyCostEUR)
    }

    func test_saveAndRead_roundTrip() {
        MoveProfileStore.saveEstimatedCost(eur: 2840, city: "Madrid", country: "spain", dependents: 2)
        XCTAssertEqual(MoveProfileStore.estimatedMonthlyCostEUR, 2840)
        XCTAssertEqual(MoveProfileStore.costCity, "Madrid")
        XCTAssertEqual(MoveProfileStore.costCountry, "spain")
        XCTAssertEqual(MoveProfileStore.dependents, 2)
    }

    func test_targetMoveDate_nilWhenUnsetOrZero() {
        XCTAssertNil(MoveProfileStore.targetMoveDate)
    }

    func test_targetMoveDate_readsMillisKey() {
        let future = Date().addingTimeInterval(60 * 86400)
        UserDefaults.standard.set(future.timeIntervalSince1970 * 1000, forKey: "target_move_millis")
        let read = MoveProfileStore.targetMoveDate
        XCTAssertNotNil(read)
        XCTAssertEqual(read!.timeIntervalSince1970, future.timeIntervalSince1970, accuracy: 1.0)
    }
}
