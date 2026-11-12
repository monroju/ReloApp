import XCTest
@testable import GoThere

final class PartnerLinksTests: XCTestCase {
    func testCountrySpecificFeedEntriesMapOntoOneProvider() {
        let map = PartnerLinks.map([
            ("feather_es", "https://feather-insurance.com/en-es/x?utm_source=a", ["spain"]),
            ("feather_de", "https://feather-insurance.com/de/x?utm_source=a", ["germany"]),
            ("wise", "https://wise.prf.hn/click/x", ["*"]),
            ("bad", "http://insecure.example", ["*"]),
        ])
        XCTAssertEqual(map["feather@spain"], "https://feather-insurance.com/en-es/x?utm_source=a")
        XCTAssertEqual(map["feather@germany"], "https://feather-insurance.com/de/x?utm_source=a")
        XCTAssertNil(map["feather"])
        XCTAssertEqual(map["wise"], "https://wise.prf.hn/click/x")
        XCTAssertNil(map["bad"])
    }
}
