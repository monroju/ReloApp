import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

/// FCM + APNs wiring for GoThere. Permission is opt-in; we never auto-prompt on launch.
/// Once granted, we auto-subscribe to `us_policy_alerts` so US-origin users receive
/// alerts about policy changes that affect their move (passport rules, exit tax, etc.).
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    static let usPolicyAlertsTopic = "us_policy_alerts"
    private static let subscribedKey = "fcm_subscribed_us_policy_alerts"

    private override init() { super.init() }

    func configureOnLaunch() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    /// Call from a settings toggle or first-run onboarding card.
    func requestPermissionAndSubscribe() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                self.subscribeToUSPolicyAlertsIfNeeded()
                self.syncRuleAlertTopicForSelection()
            }
        }
    }

    func subscribeToUSPolicyAlertsIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.subscribedKey) { return }
        Messaging.messaging().subscribe(toTopic: Self.usPolicyAlertsTopic) { error in
            if error == nil {
                defaults.set(true, forKey: Self.subscribedKey)
            }
        }
    }

    // MARK: Rule-change alerts per destination

    /// Destinations with verified rule-change alerts. Topic is `rules_<code>`;
    /// the sender is shared/alerts/alerts.py in the parent repo.
    static let ruleAlertCodes: [String: String] = [
        DestinationConfig.spain: "es", DestinationConfig.portugal: "pt",
        DestinationConfig.ireland: "ie", DestinationConfig.italy: "it",
        DestinationConfig.mexico: "mx",
    ]
    private static let ruleTopicKey = "fcm_rule_alert_topic"

    static func ruleAlertTopic(for countryId: String) -> String? {
        ruleAlertCodes[countryId].map { "rules_\($0)" }
    }

    /// Keep exactly one `rules_<code>` topic, matching the selected destination.
    /// Only acts once the user has opted in to notifications, so it never prompts.
    func syncRuleAlertTopic(for countryId: String) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.subscribedKey) else { return }
        let wanted = Self.ruleAlertTopic(for: countryId)
        let current = defaults.string(forKey: Self.ruleTopicKey)
        guard wanted != current else { return }
        if let current {
            Messaging.messaging().unsubscribe(fromTopic: current)
            defaults.removeObject(forKey: Self.ruleTopicKey)
        }
        guard let wanted else { return }
        Messaging.messaging().subscribe(toTopic: wanted) { error in
            if error == nil { defaults.set(wanted, forKey: Self.ruleTopicKey) }
        }
    }

    private func syncRuleAlertTopicForSelection() {
        let id = UserDefaults.standard.string(forKey: "selectedCountryId") ?? DestinationConfig.spain
        syncRuleAlertTopic(for: id)
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        subscribeToUSPolicyAlertsIfNeeded()
        syncRuleAlertTopicForSelection()
    }
}
