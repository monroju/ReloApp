import Foundation

/// A document the user needs for their visa application, generated from a
/// Wizard taskRule that carries a documentSlot annotation. Slots live in
/// `users/{uid}/documentSlots` keyed deterministically by (key, visaTrackId)
/// so re-running the wizard is idempotent.
struct DocumentSlot: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var key: String                    // semantic: "fbi_check", "it_ancestor_birth_cert"
    var label: String                  // shown in DocumentsView
    var slotDescription: String?       // 'description' is taken on Identifiable in some sites
    var countryId: String              // for grouping
    var visaTrackId: String            // for grouping + idempotency
    var status: SlotStatus
    var uploadedDocumentId: String?    // points at users/{uid}/documents/{docId}
    var generatedAt: Date = Date()

    // MARK: Foundation Wave 1 fields (all optional for backward compat with
    // existing Firestore docs written before the schema bump).

    /// Free-text guidance on where to obtain the document.
    var whereToObtain: String? = nil
    /// Free-text validity window (e.g. "90 days from issue").
    var validityPeriod: String? = nil
    /// Apostille of the Hague required to be valid abroad.
    var apostilleRequired: Bool? = nil
    /// Sworn / certified translation required.
    var swornTranslationRequired: Bool? = nil
    /// Back-pointer to the originating task rule, so completing the slot can
    /// mark the linked task complete. Currently advisory; mirror happens at
    /// the upload-finished call site, not via cascading writes.
    var sourceTaskRuleKey: String? = nil
}

enum SlotStatus: String, Codable {
    case pending
    case uploaded
    // .verified intentionally omitted — v1 cap per gothere-growth Item 21
}

extension DocumentSlot {
    /// Stable Firestore document id. Keying by (key, visaTrackId) means re-running
    /// the wizard upserts this slot instead of duplicating it. Underscores are
    /// safe in Firestore doc ids.
    var firestoreId: String { "\(visaTrackId)__\(key)" }
}
