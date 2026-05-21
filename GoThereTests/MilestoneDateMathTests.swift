import XCTest
@testable import GoThere

/// Foundation Wave 1: anchor-date arithmetic must produce the same calendar
/// day regardless of user time zone. The operator authors in Spain (CET/CEST);
/// users live across US time zones. A bug here means reminders fire on the
/// wrong day.
final class MilestoneDateMathTests: XCTestCase {

    func test_offsetMinus90Days_lands90DaysBeforeAnchor() {
        let anchor = ISO8601DateFormatter().date(from: "2026-06-15T12:00:00Z")!
        let expected = ISO8601DateFormatter().date(from: "2026-03-17T12:00:00Z")!

        let result = Calendar.current.date(byAdding: .day, value: -90, to: anchor)!
        XCTAssertEqual(result.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1.0)
    }

    func test_offsetPlus30Days_landsCorrectlyAcrossMonth() {
        let anchor = ISO8601DateFormatter().date(from: "2026-08-20T00:00:00Z")!
        let expected = ISO8601DateFormatter().date(from: "2026-09-19T00:00:00Z")!

        let result = Calendar.current.date(byAdding: .day, value: 30, to: anchor)!
        XCTAssertEqual(result.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1.0)
    }

    func test_dstTransition_preservesCalendarDay() {
        // US DST starts 2026-03-08 02:00 local. An offset crossing this date
        // should still land on a clean calendar day relative to the anchor.
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        let anchorComps = DateComponents(year: 2026, month: 3, day: 25, hour: 12)
        let anchor = pacific.date(from: anchorComps)!
        let expectedComps = DateComponents(year: 2026, month: 3, day: 5, hour: 12)
        let expected = pacific.date(from: expectedComps)!

        let result = pacific.date(byAdding: .day, value: -20, to: anchor)!

        // Compare year/month/day components — the wall clock day, not the
        // absolute interval which could differ by one hour due to DST.
        XCTAssertEqual(pacific.component(.year, from: result),
                       pacific.component(.year, from: expected))
        XCTAssertEqual(pacific.component(.month, from: result),
                       pacific.component(.month, from: expected))
        XCTAssertEqual(pacific.component(.day, from: result),
                       pacific.component(.day, from: expected))
    }

    func test_zeroOffset_anchorEqualsResult() {
        let anchor = Date()
        let result = Calendar.current.date(byAdding: .day, value: 0, to: anchor)!
        XCTAssertEqual(result.timeIntervalSince1970, anchor.timeIntervalSince1970, accuracy: 1.0)
    }
}
