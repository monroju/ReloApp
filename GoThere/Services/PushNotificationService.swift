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
    }
}
