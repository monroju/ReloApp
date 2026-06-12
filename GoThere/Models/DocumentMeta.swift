import Foundation
import SwiftUI

/// Broad bucket a document falls into. Optional on `UserDocument` for backward
/// compatibility — documents uploaded before the expiration engine landed have
/// no category and render as `.other`.
enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case identity, criminal, financial, civil, medical, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .identity:  return "Identity"
        case .criminal:  return "Criminal Record"
        case .financial: return "Financial"
        case .civil:     return "Civil"
        case .medical:   return "Medical"
        case .other:     return "Other"
        }
    }

    var icon: String {
        switch self {
        case .identity:  return "person.text.rectangle"
        case .criminal:  return "checkmark.shield"
        case .financial: return "banknote"
        case .civil:     return "doc.text"
        case .medical:   return "cross.case"
        case .other:     return "doc"
        }
    }
}

/// Lifecycle state of a tracked document. Superset of the wizard slot's
/// `SlotStatus` (which stays `pending`/`uploaded` for slot idempotency) — this
/// is the *document's* own status, derived from its expiration + outstanding
/// apostille/translation work.
enum DocumentStatus: String, Codable {
    case pending            // required but nothing uploaded
    case uploaded           // file present, no expiry concerns
    case apostillePending   // uploaded, still needs an apostille
    case translationPending // uploaded, still needs a sworn translation
    case complete           // uploaded, valid, all extra steps done
    case expired            // past its expiration date

    var label: String {
        switch self {
        case .pending:            return "Missing"
        case .uploaded:           return "Uploaded"
        case .apostillePending:   return "Apostille needed"
        case .translationPending: return "Translation needed"
        case .complete:           return "Complete"
        case .expired:            return "Expired"
        }
    }
}

/// Color band used by the urgency chip and vault header. Kept separate from
/// `DocumentStatus` so expiry proximity (which is date-driven, not stored) can
/// override the stored status for display.
enum DocumentUrgency: Int, Comparable {
    case expired = 0       // past expiration — most urgent
    case missing = 1       // required, not uploaded
    case expiringSoon = 2  // within the nearest reminder window
    case attention = 3     // uploaded but apostille/translation outstanding
    case ok = 4            // complete / valid / plenty of runway

    static func < (lhs: DocumentUrgency, rhs: DocumentUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: Color {
        switch self {
        case .expired:      return .goError
        case .missing:      return .goError
        case .expiringSoon: return .goWarning
        case .attention:    return .goWarning
        case .ok:           return .goSuccess
        }
    }
}

/// Default reminder offsets (days before expiration) when a document doesn't
/// specify its own. Mirrors the differentiation spec: 30 / 14 / 3.
enum DocumentReminders {
    static let defaultDays = [30, 14, 3]
    /// A document is "expiring soon" once it's within this many days of expiry.
    static let soonThresholdDays = 30
}

/// Informational validity rule for a known document type. Validity periods and
/// requirements are GUIDANCE ONLY — every value here should be verified against
/// the relevant consulate/official source; rules drift year to year.
struct DocumentValidityRule {
    /// Canonical display name suggested on upload.
    let canonicalName: String
    /// Days the document stays valid from issuance. 0 = does not expire.
    let validityDays: Int
    let apostilleRequired: Bool
    let swornTranslationRequired: Bool
    let category: DocumentCategory
    /// Lowercased keywords used to match an uploaded filename to this rule.
    let keywords: [String]
    let note: String?
}

/// Lookup table mapping common relocation documents to their validity windows.
/// Informational only — surfaced with a "verify with official sources" caveat in
/// the UI. Refresh annually alongside `VisaCatalog`'s income thresholds.
enum DocumentValidityRules {
    static let all: [DocumentValidityRule] = [
        DocumentValidityRule(
            canonicalName: "FBI Background Check", validityDays: 90,
            apostilleRequired: true, swornTranslationRequired: true, category: .criminal,
            keywords: ["fbi", "identity history", "ident history", "background check"],
            note: "Apostille after issuance, not before. Many consulates treat it as valid ~90 days."),
        DocumentValidityRule(
            canonicalName: "State Criminal Background Check", validityDays: 90,
            apostilleRequired: true, swornTranslationRequired: true, category: .criminal,
            keywords: ["state criminal", "state background check", "state background", "police clearance", "criminal record"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Medical Certificate", validityDays: 90,
            apostilleRequired: false, swornTranslationRequired: true, category: .medical,
            keywords: ["medical certificate", "medical cert", "health certificate", "certificado medico"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Bank Statements", validityDays: 90,
            apostilleRequired: false, swornTranslationRequired: false, category: .financial,
            keywords: ["bank statement", "bank statements", "account statement"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Employment Letter / Proof of Income", validityDays: 90,
            apostilleRequired: false, swornTranslationRequired: false, category: .financial,
            keywords: ["employment letter", "proof of income", "income letter", "pay stub", "payslip"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Passport Photo", validityDays: 180,
            apostilleRequired: false, swornTranslationRequired: false, category: .identity,
            keywords: ["passport photo", "id photo", "photo"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Passport", validityDays: 0,
            apostilleRequired: false, swornTranslationRequired: false, category: .identity,
            keywords: ["passport"],
            note: "Check the expiry printed on your passport — many visas require 6+ months of validity."),
        DocumentValidityRule(
            canonicalName: "Birth Certificate (Apostilled)", validityDays: 0,
            apostilleRequired: true, swornTranslationRequired: true, category: .civil,
            keywords: ["birth certificate", "birth cert", "atto di nascita", "acta de nacimiento"],
            note: "Does not expire, but verify consulate policy — some want a recent re-issue."),
        DocumentValidityRule(
            canonicalName: "Marriage Certificate (Apostilled)", validityDays: 0,
            apostilleRequired: true, swornTranslationRequired: true, category: .civil,
            keywords: ["marriage certificate", "marriage cert", "acta de matrimonio"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Health Insurance Certificate", validityDays: 365,
            apostilleRequired: false, swornTranslationRequired: false, category: .medical,
            keywords: ["health insurance", "insurance certificate", "insurance policy", "seguro"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Tax Return / Transcript", validityDays: 0,
            apostilleRequired: false, swornTranslationRequired: true, category: .financial,
            keywords: ["tax return", "irs transcript", "tax transcript", "1040"],
            note: "Most recent filing; check whether a sworn translation is needed."),
        DocumentValidityRule(
            canonicalName: "Pension / Social Security Statement", validityDays: 90,
            apostilleRequired: false, swornTranslationRequired: false, category: .financial,
            keywords: ["pension", "social security", "ssa statement", "retirement statement"],
            note: nil),
        DocumentValidityRule(
            canonicalName: "Driver's License", validityDays: 0,
            apostilleRequired: false, swornTranslationRequired: false, category: .identity,
            keywords: ["driver license", "driver's license", "drivers license", "driving licence", "driving license"],
            note: "Check the expiry on the card; some countries require an exchange within a window."),
    ]

    /// Best-effort match of an uploaded filename to a known document type.
    /// Returns the rule whose keyword appears in the (lowercased) filename, with
    /// the longest matching keyword winning so "state background" beats a bare
    /// "background". Nil when nothing matches — the upload stays a plain file.
    static func match(fileName: String) -> DocumentValidityRule? {
        let haystack = fileName.lowercased()
        var best: (rule: DocumentValidityRule, len: Int)?
        for rule in all {
            for kw in rule.keywords where haystack.contains(kw) {
                if best == nil || kw.count > best!.len {
                    best = (rule, kw.count)
                }
            }
        }
        return best?.rule
    }

    /// Expiration date for a document issued/uploaded on `from` with the given
    /// validity window. Nil when `validityDays <= 0` (non-expiring).
    static func expiration(from date: Date, validityDays: Int) -> Date? {
        guard validityDays > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: validityDays, to: date)
    }
}
