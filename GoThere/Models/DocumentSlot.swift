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
