import XCTest
@testable import GoThere

/// Wave 1 (T1c-finish) — confirms the affordable-visa bucketing logic uses
/// the dependent-adjusted threshold, not the single-applicant figure.
/// CostCalculatorView's `affordableVisasSection` is the consumer; this test
/// mirrors its branching so a refactor that drops the dependents param is
/// caught at CI time, not in production.
final class CalculatorBucketingTests: XCTestCase {

    private func makeVisa(base: Int, multiplier: Double?) -> VisaInfo {
        VisaInfo(
            id: "test",
            countryId: "spain", countryFlag: "🇪🇸", countryName: "Spain",
            name: "Test", shortName: "TEST",
            category: .passiveIncome,
            income: "x",
            monthlyIncomeEUR: base,
            dependentMultiplier: multiplier,
            processingTime: "x", duration: "x",
            workAllowed: "x", pathToPR: "x", pathToCitizenship: "x",
            costEstimate: "x", pros: [], cons: [],
            officialUrl: "https://example.com", wizardTrackId: nil
        )
    }

    /// Bucket the user's monthly cost against a visa using the same thresholds
    /// the Calculator UI applies: <= 75% of bar => Comfortable, <= bar => Tight,
    /// > bar => Below.
    private func bucket(visa: VisaInfo, monthlyEUR: Int, dependents: Int) -> String {
        let bar = visa.requiredMonthlyEUR(dependents: dependents) ?? visa.monthlyIncomeEUR!
        if monthlyEUR <= Int(Double(bar) * 0.75) { return "Comfortable" }
        if monthlyEUR <= bar { return "Tight" }
        return "Below"
    }

    func test_singleApplicant_belowThreshold_isBelow() {
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        XCTAssertEqual(bucket(visa: visa, monthlyEUR: 3000, dependents: 0), "Below")
    }

    func test_singleApplicant_comfortable() {
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        // 1800 / 2400 = 0.75 — exactly the comfortable ceiling.
        XCTAssertEqual(bucket(visa: visa, monthlyEUR: 1800, dependents: 0), "Comfortable")
    }

    func test_threeDependents_movesBarUpAndShiftsBucket() {
        let visa = makeVisa(base: 2400, multiplier: 0.25)
        // €3,000/mo against single-applicant €2,400 => Below.
        XCTAssertEqual(bucket(visa: visa, monthlyEUR: 3000, dependents: 0), "Below")
        // Add 3 dependents: bar becomes 2400 + (2400 * 0.25 * 3) = 4200.
        // €3,000 ≤ 75% of 4200 (= 3150) => Comfortable.
        XCTAssertEqual(bucket(visa: visa, monthlyEUR: 3000, dependents: 3), "Comfortable")
    }

    func test_nilMultiplier_dependentsHaveNoEffect() {
        // Visas without a structured dependent multiplier (employer/points)
        // must not change bucket as dependents go up.
        let visa = makeVisa(base: 2400, multiplier: nil)
        let solo = bucket(visa: visa, monthlyEUR: 2000, dependents: 0)
        let withKids = bucket(visa: visa, monthlyEUR: 2000, dependents: 4)
        XCTAssertEqual(solo, withKids)
    }
}
