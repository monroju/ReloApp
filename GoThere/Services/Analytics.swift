import Foundation
import PostHog

/// Named analytics events for GoThere. Centralized so adding/renaming an event happens in
/// one place, and so a future SDK swap (Firebase Analytics, Amplitude, etc.) only touches
/// this file. Per `gothere_ground_truth.md` §7, no named events were firing before this —
/// PostHog was initialized but never captured.
enum AnalyticsEvent: String {
    // Wizard funnel
    case wizardStarted = "wizard_started"
    case wizardCompleted = "wizard_completed"

    // Paywall funnel — the H2 measurement spine
    case paywallViewed = "paywall_viewed"
    case bundleSavingsDisplayed = "bundle_savings_displayed"
    case purchaseInitiated = "purchase_initiated"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case countryUnlocked = "country_unlocked"

    // Feature usage
    case costCalcCompleted = "cost_calc_completed"
    case decisionTreeCompleted = "decision_tree_completed"
    case documentsTabOpened = "documents_tab_opened"
    case calendarOpened = "calendar_opened"

    // Wave 2 — AI conversational entry point
    case aiConversationOpened = "ai_conversation_opened"
    case aiMessageSent = "ai_message_sent"
    case aiToolCalled = "ai_tool_called"
    case aiFreeLimitReached = "ai_free_limit_reached"
    case aiErrorReturned = "ai_error_returned"
}

enum Analytics {
    /// Fire-and-forget. Captures via PostHog. Caller never blocks.
    static func log(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }

    /// Convenience for the very common country_id property shape.
    static func log(_ event: AnalyticsEvent, country: String, extra: [String: Any] = [:]) {
        var props = extra
        props["country_id"] = country
        log(event, properties: props)
    }
}
