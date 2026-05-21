import XCTest
@testable import GoThere

/// Foundation Wave 1: `VisaInfo.requiredMonthlyEUR(dependents:)` is the income-
/// fit math used by both Calculator and Wizard. Regressions here corrupt the
/// affordability indicator.
final class VisaInfoTests: XCTestCase {

    private func makeVisa(base: Int?, multiplier: Double?) -> VisaInfo {
        VisaInfo(
            id: "test",
            countryId: "spain", countryFlag: "🇪🇸", countryName: "Spain",
            name: "Test", shortName: "TEST",
            category: .passiveIncome,
            income: "test",
            monthlyIncomeEUR: base,
            dependentMultiplier: multiplier,
            processingTime: "x",
            duration: "x",
            workAllowed: "x",
            pathToPR: "x",
            pathToCitizenship: "x",
            costEstimate: "x",
            pros: [], cons: [],
            officialUrl: "https://example.com",
            wizardTrackId: nil
        )
    }

    func test_zeroDependents_returnsBase() {
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        XCTAssertEqual(visa.requiredMonthlyEUR(dependents: 0), 2400)
    }

    func test_oneDependent_appliesMultiplier() {
        // Spain NLV: 4× IPREM (~€2,400) + 25% per dependent.
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        XCTAssertEqual(visa.requiredMonthlyEUR(dependents: 1), 3000)
    }

    func test_threeDependents_scalesLinearly() {
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        // 2400 + (2400 * 0.25 * 3) = 4200
        XCTAssertEqual(visa.requiredMonthlyEUR(dependents: 3), 4200)
    }

    func test_nilMultiplier_returnsBaseRegardlessOfDependents() {
        let visa = makeVisa(base: 2400, multiplier: nil)
        XCTAssertEqual(visa.requiredMonthlyEUR(dependents: 5), 2400)
    }

    func test_nilBase_returnsNil() {
        let visa = makeVisa(base: nil, multiplier: 0.25)
        XCTAssertNil(visa.requiredMonthlyEUR(dependents: 2))
    }
}
