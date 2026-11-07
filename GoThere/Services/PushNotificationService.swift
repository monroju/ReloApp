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

    private static let ruleTopicsKey = "fcm_rule_alert_topics"

    /// Rule-alert topics the user should hold right now. Free users get one country:
    /// their first tracked Plan B path that has alerts, otherwise the selected
    /// destination. All-Access adds every tracked path on top of the destination.
    /// Pure so it can be unit tested.
    static func desiredRuleTopics(destinationId: String, planBCodes: [String], allAccess: Bool) -> [String] {
        let available = Set(ruleAlertCodes.values)
        let planB = planBCodes.filter { available.contains($0) }.map { "rules_\($0)" }
        let destination = ruleAlertTopic(for: destinationId)
        var out: [String] = []
        if allAccess {
            out = (destination.map { [$0] } ?? []) + planB
        } else if let first = planB.first {
            out = [first]
        } else if let destination {
            out = [destination]
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }

    /// Destination changed. Kept for CountrySelection; the topic set is recomputed as a whole.
    @MainActor
    func syncRuleAlertTopic(for countryId: String) {
        syncRuleAlertTopics(destinationId: countryId)
    }

    /// Subscribe and unsubscribe so FCM holds exactly `desiredRuleTopics`.
    /// Only acts once the user has opted in to notifications, so it never prompts.
    @MainActor
    func syncRuleAlertTopics(destinationId: String? = nil) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.subscribedKey) else { return }
        let dest = destinationId ?? defaults.string(forKey: "selectedCountryId") ?? DestinationConfig.spain
        let wanted = Self.desiredRuleTopics(destinationId: dest,
                                            planBCodes: PlanBStore.shared.alertCountryCodes,
                                            allAccess: PurchaseManager.shared.hasAllAccess)
        var current = Set(defaults.stringArray(forKey: Self.ruleTopicsKey) ?? [])
        // Migrate the single-topic key from 1.11.x.
        if let legacy = defaults.string(forKey: Self.ruleTopicKey) {
            current.insert(legacy)
            defaults.removeObject(forKey: Self.ruleTopicKey)
        }
        for topic in current.subtracting(wanted) {
            Messaging.messaging().unsubscribe(fromTopic: topic)
        }
        let keep = current.intersection(wanted)
        defaults.set(Array(keep), forKey: Self.ruleTopicsKey)
        for topic in wanted where !current.contains(topic) {
            Messaging.messaging().subscribe(toTopic: topic) { error in
                guard error == nil else { return }
                DispatchQueue.main.async {
                    var held = Set(defaults.stringArray(forKey: Self.ruleTopicsKey) ?? [])
                    held.insert(topic)
                    defaults.set(Array(held), forKey: Self.ruleTopicsKey)
                }
            }
        }
    }

    private func syncRuleAlertTopicForSelection() {
        Task { @MainActor in self.syncRuleAlertTopics() }
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
