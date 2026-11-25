import XCTest
@testable import GoThere

/// notification_opened properties: every notification kind maps to a stable `type`,
/// and no notification text reaches analytics.
final class NotificationOpenTrackingTests: XCTestCase {

    private func local(_ id: String) -> [String: Any] {
        NotificationOpenTracking.properties(identifier: id, userInfo: [:], isRemote: false)
    }

    func testLocalPrefixesMapToTypes() {
        XCTAssertEqual(local("docexp_ABC_30")["type"] as? String, "document_expiry")
        XCTAssertEqual(local("docexp_ABC_expired")["type"] as? String, "document_expiry")
        XCTAssertEqual(local("cita_M1_2")["type"] as? String, "cita_reminder")
        XCTAssertEqual(local("event_42")["type"] as? String, "calendar_event")
        XCTAssertEqual(local("timeline_renewal_open")["type"] as? String, "timeline")
        XCTAssertEqual(local("something_else")["type"] as? String, "local_other")
    }

    func testLocalCarriesSourceIdAndPlatform() {
        let p = local("docexp_ABC_30")
        XCTAssertEqual(p["source"] as? String, "local")
        XCTAssertEqual(p["id"] as? String, "docexp_ABC_30")
        XCTAssertEqual(p["platform"] as? String, "ios")
    }

    func testLongIdentifierIsTruncated() {
        let p = local("event_" + String(repeating: "x", count: 200))
        XCTAssertEqual((p["id"] as? String)?.count, 64)
    }

    func testRuleAlertPush() {
        let p = NotificationOpenTracking.properties(
            identifier: "ignored",
            userInfo: ["from": "/topics/rules_es", "gcm.message_id": "0:123",
                       "aps": ["alert": ["title": "Secret title", "body": "Secret body"]]],
            isRemote: true)
        XCTAssertEqual(p["source"] as? String, "push")
        XCTAssertEqual(p["type"] as? String, "rule_alert")
        XCTAssertEqual(p["topic"] as? String, "rules_es")
        XCTAssertEqual(p["id"] as? String, "0:123")
        XCTAssertEqual(p["platform"] as? String, "ios")
        let values = p.values.compactMap { $0 as? String }.joined(separator: " ")
        XCTAssertFalse(values.contains("Secret"))
    }

    func testUSPolicyPushAndExplicitType() {
        let us = NotificationOpenTracking.properties(
            identifier: "", userInfo: ["from": "/topics/us_policy_alerts"], isRemote: true)
        XCTAssertEqual(us["type"] as? String, "us_policy_alert")

        let explicit = NotificationOpenTracking.properties(
            identifier: "", userInfo: ["from": "/topics/rules_pt", "type": "timeline"], isRemote: true)
        XCTAssertEqual(explicit["type"] as? String, "timeline")
    }

    func testDirectPushWithoutTopic() {
        let p = NotificationOpenTracking.properties(
            identifier: "", userInfo: ["from": "123456789"], isRemote: true)
        XCTAssertEqual(p["type"] as? String, "push")
        XCTAssertNil(p["topic"])
    }
}
