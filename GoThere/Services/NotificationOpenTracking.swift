import Foundation

/// Builds the properties for `notification_opened`, fired when the user opens the app
/// from a notification. Pure so it can be unit tested without UNNotification instances.
/// Properties carry only an internal identifier and the kind of notification: never the
/// notification text, document names or dates.
enum NotificationOpenTracking {

    /// Local notification identifier prefix -> analytics `type`.
    /// Keep in sync with the prefixes in `NotificationManager`.
    static let localPrefixes: [(prefix: String, type: String)] = [
        ("docexp_", "document_expiry"),
        ("cita_", "cita_reminder"),
        ("event_", "calendar_event"),
        ("timeline_", "timeline")
    ]

    static func properties(identifier: String,
                           userInfo: [AnyHashable: Any],
                           isRemote: Bool) -> [String: Any] {
        var props: [String: Any] = ["platform": "ios"]
        if isRemote {
            props["source"] = "push"
            let topic = (userInfo["from"] as? String).flatMap(topicName(from:))
            if let topic { props["topic"] = topic }
            if let explicit = userInfo["type"] as? String, !explicit.isEmpty {
                props["type"] = String(explicit.prefix(40))
            } else if let topic, topic.hasPrefix("rules_") {
                props["type"] = "rule_alert"
            } else if topic == PushNotificationService.usPolicyAlertsTopic {
                props["type"] = "us_policy_alert"
            } else {
                props["type"] = "push"
            }
            if let messageId = userInfo["gcm.message_id"] as? String {
                props["id"] = String(messageId.prefix(64))
            }
        } else {
            props["source"] = "local"
            props["type"] = localPrefixes.first { identifier.hasPrefix($0.prefix) }?.type ?? "local_other"
            props["id"] = String(identifier.prefix(64))
        }
        return props
    }

    /// "/topics/rules_es" -> "rules_es". Returns nil for direct (token) sends.
    static func topicName(from: String) -> String? {
        let marker = "/topics/"
        guard from.hasPrefix(marker) else { return nil }
        let name = String(from.dropFirst(marker.count))
        return name.isEmpty ? nil : name
    }
}
