import Foundation

struct UserDocument: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var downloadUrl: String = ""
    var path: String = ""
    /// When this upload was attached to a Wizard documentSlot, the slot's key
    /// and trackId are stamped here for traceability. Both nil for "Other
    /// uploads" — the legacy flow.
    var slotKey: String? = nil
    var slotTrackId: String? = nil

    // MARK: Expiration engine (Differentiation Wave). All optional so documents
    // written before this schema bump decode cleanly (Firestore merge-friendly).

    /// Broad bucket; populated from the validity-rules lookup on upload.
    var category: DocumentCategory? = nil
    /// When this document stops being valid for an application. Nil = non-expiring
    /// or unknown. User-overridable in the detail screen.
    var expirationDate: Date? = nil
    /// Validity window in days, from the lookup or a user override. Drives the
    /// suggested expiration when the issue date changes.
    var validityPeriodDays: Int? = nil
    /// True when the document needs an apostille to be valid abroad.
    var apostilleRequired: Bool? = nil
    /// True when the document needs a sworn / certified translation.
    var swornTranslationRequired: Bool? = nil
    /// Whether the apostille has been obtained (sub-checklist state).
    var apostilleDone: Bool? = nil
    /// Whether the sworn translation has been obtained.
    var translationDone: Bool? = nil
    /// ISO-ish issuing country string, free text. Informational.
    var issuingCountry: String? = nil
    /// Reminder offsets (days before expiry). Defaults applied at schedule time.
    var reminderDays: [Int]? = nil
    /// User notes.
    var notes: String? = nil
}

extension UserDocument {
    var effectiveReminderDays: [Int] { reminderDays ?? DocumentReminders.defaultDays }

    /// Whole days until expiration (negative when already expired). Nil for
    /// non-expiring documents.
    var daysUntilExpiration: Int? {
        guard let exp = expirationDate else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: exp)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    var isExpired: Bool { (daysUntilExpiration ?? Int.max) < 0 }

    /// Within the nearest "expiring soon" window (but not yet expired).
    var isExpiringSoon: Bool {
        guard let d = daysUntilExpiration else { return false }
        return d >= 0 && d <= DocumentReminders.soonThresholdDays
    }

    /// Outstanding apostille/translation work the document still needs.
    var hasOutstandingPrep: Bool {
        (apostilleRequired == true && apostilleDone != true) ||
        (swornTranslationRequired == true && translationDone != true)
    }

    /// Display-time urgency band, blending expiry proximity with prep state.
    var urgency: DocumentUrgency {
        if isExpired { return .expired }
        if isExpiringSoon { return .expiringSoon }
        if hasOutstandingPrep { return .attention }
        return .ok
    }

    /// Document's own lifecycle status, derived (not stored) so it can never go
    /// stale relative to the current date.
    var derivedStatus: DocumentStatus {
        if isExpired { return .expired }
        if apostilleRequired == true && apostilleDone != true { return .apostillePending }
        if swornTranslationRequired == true && translationDone != true { return .translationPending }
        return .complete
    }

    /// Short human-readable countdown, e.g. "Expires in 14 days", "Expired
    /// 3 days ago", "No expiry". Used on the row + detail header.
    var expiryLabel: String {
        guard let days = daysUntilExpiration else { return "No expiry date" }
        if days < 0 { return "Expired \(-days) day\(-days == 1 ? "" : "s") ago" }
        if days == 0 { return "Expires today" }
        return "Expires in \(days) day\(days == 1 ? "" : "s")"
    }
}
