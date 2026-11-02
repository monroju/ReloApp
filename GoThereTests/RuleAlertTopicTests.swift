import XCTest
@testable import GoThere

/// E13: per-destination FCM topics. The names must match the sender in
/// shared/alerts/alerts.py (`rules_<iso code>`), or pushes reach nobody.
final class RuleAlertTopicTests: XCTestCase {

    func testCoveredDestinationsMapToIsoTopics() {
        XCTAssertEqual(PushNotificationService.ruleAlertTopic(for: DestinationConfig.spain), "rules_es")
        XCTAssertEqual(PushNotificationService.ruleAlertTopic(for: DestinationConfig.portugal), "rules_pt")
        XCTAssertEqual(PushNotificationService.ruleAlertTopic(for: DestinationConfig.ireland), "rules_ie")
        XCTAssertEqual(PushNotificationService.ruleAlertTopic(for: DestinationConfig.italy), "rules_it")
        XCTAssertEqual(PushNotificationService.ruleAlertTopic(for: DestinationConfig.mexico), "rules_mx")
    }

    func testUncoveredDestinationsHaveNoTopic() {
        XCTAssertNil(PushNotificationService.ruleAlertTopic(for: DestinationConfig.canada))
        XCTAssertNil(PushNotificationService.ruleAlertTopic(for: DestinationConfig.ukAncestry))
    }
}
