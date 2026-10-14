import Foundation
import PostHog

/// Named analytics events for GoThere. Centralized so adding/renaming an event happens in
/// one place, and so a future SDK swap (Firebase Analytics, Amplitude, etc.) only touches
/// this file. Names follow the canonical list in `Projects/growth-plan/02-metrics.md`,
/// shared with Localista and Android, so one PostHog dashboard template works everywhere.
enum AnalyticsEvent: String {
    // Onboarding and identity
    case guestStarted = "guest_started"
    case signupCompleted = "signup_completed"
    case loginCompleted = "login_completed"
    case installAttributed = "install_attributed"

    // Wizard funnel
    case wizardStarted = "wizard_started"
    case wizardCompleted = "wizard_completed"

    // Activation. `activated` fires once, on the first of the candidate events below.
    case activated = "activated"
    case ancestryResultViewed = "ancestry_result_viewed"
    case visaCompareViewed = "visa_compare_viewed"

    // Paywall funnel
    case paywallViewed = "paywall_viewed"
    case paywallDismissed = "paywall_dismissed"
    case bundleSavingsDisplayed = "bundle_savings_displayed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseRestored = "purchase_restored"
    case countryUnlocked = "country_unlocked"
    case legacyInstallConfirmed = "legacy_install_confirmed"

    // Feature usage
    case costCalcCompleted = "cost_calc_completed"
    case decisionTreeCompleted = "decision_tree_completed"
    case documentsTabOpened = "documents_tab_opened"
    case calendarOpened = "calendar_opened"
    case documentScanCompleted = "document_scan_completed"
    case referralRedeemed = "referral_redeemed"
    case conciergeWaitlistJoined = "concierge_waitlist_joined"
    case reviewPromptRequested = "review_prompt_requested"

    // Wave 2 — AI conversational entry point
    case aiConversationOpened = "ai_conversation_opened"
    case aiMessageSent = "ai_message_sent"
    case aiToolCalled = "ai_tool_called"
    case freeLimitReached = "free_limit_reached"   // prop `limit`: ai, document_scan
    case aiErrorReturned = "ai_error_returned"

    // Differentiation Wave — the chatbot-proof operational features
    case coPilotOpened = "copilot_opened"
    case citaMonitorOpened = "cita_monitor_opened"
    case citaPortalOpened = "cita_portal_opened"
    case documentExpirySet = "document_expiry_set"
}

enum Analytics {
    private static let firstOpenKey = "analytics_first_open_at"
    private static let activatedKey = "analytics_activated_v1"

    /// Events that count as activation (02-metrics.md). The first one fired also fires `activated`.
    private static let activationEvents: Set<AnalyticsEvent> = [
        .wizardCompleted, .decisionTreeCompleted, .ancestryResultViewed, .visaCompareViewed
    ]

    /// Which screen opened the paywall currently on screen. Purchase events carry it so
    /// paywall-to-purchase conversion can be split by trigger.
    static var paywallSource = "unknown"
    private static var lastPurchaseAt: Date?

    /// True when a purchase completed after `date` (so closing the paywall then is not a dismissal).
    static func purchased(since date: Date) -> Bool {
        guard let lastPurchaseAt else { return false }
        return lastPurchaseAt >= date
    }

    /// Fire-and-forget. Captures via PostHog. Caller never blocks.
    static func log(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
        if event == .purchaseCompleted { lastPurchaseAt = Date() }
        if activationEvents.contains(event) { markActivated(via: event) }
    }

    /// Convenience for the very common country_id property shape.
    static func log(_ event: AnalyticsEvent, country: String, extra: [String: Any] = [:]) {
        var props = extra
        props["country_id"] = country
        log(event, properties: props)
    }

    private static func markActivated(via event: AnalyticsEvent) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: activatedKey) else { return }
        defaults.set(true, forKey: activatedKey)
        PostHogSDK.shared.capture(AnalyticsEvent.activated.rawValue, properties: [
            "via": event.rawValue,
            "$set_once": ["activated_at": ISO8601DateFormatter().string(from: Date())]
        ])
    }

    // MARK: - Super properties and identity

    /// Registers the properties every event carries. Call once at launch, after PostHog setup.
    static func registerSuperProperties() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: firstOpenKey) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: firstOpenKey)
        }
        let firstOpen = Date(timeIntervalSince1970: defaults.double(forKey: firstOpenKey))
        PostHogSDK.shared.register([
            "app": "gothere",
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "install_week": isoWeek(firstOpen),
            "acq_source": InstallAttribution.storedSource,
            "is_internal": isInternalBuild
        ])
    }

    static func setAcquisitionSource(_ source: String) {
        PostHogSDK.shared.register(["acq_source": source])
    }

    /// Ties events to the Firebase uid so web, server (IAP notifications) and app events join.
    static func identify(uid: String) {
        guard PostHogSDK.shared.getDistinctId() != uid else { return }
        PostHogSDK.shared.identify(uid, userPropertiesSetOnce: [
            "acq_source": InstallAttribution.storedSource
        ])
    }

    static func reset() {
        PostHogSDK.shared.reset()
        registerSuperProperties()
    }

    /// Simulator (Appetize) and TestFlight/dev-signed builds, so tester traffic can be filtered out.
    private static var isInternalBuild: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    private static func isoWeek(_ date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }
}
