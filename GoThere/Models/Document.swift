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
}
