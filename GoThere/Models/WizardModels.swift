import Foundation

// MARK: - Wizard Config (parsed from wizard_config.json)

struct WizardConfig: Codable {
    let wizardVersion: Int
    let tracks: [String: WizardTrack]
    /// Optional top-level question asked once before track selection. Used to
    /// anchor milestones to a real user-chosen date (e.g. consulate appointment
    /// target). Nil for backward compatibility with v1 configs.
    let anchorDateQuestion: AnchorDateQuestion?
}

struct AnchorDateQuestion: Codable {
    let id: String          // e.g. "anchor_date"
    let label: String
    let hint: String?
    /// Default offset in days from today when the user skips the question.
    /// Wave 1 default: 90.
    let defaultOffsetDays: Int
}

struct WizardTrack: Codable {
    let displayName: String
    let countryId: String
    let shortName: String
    let steps: [WizardStep]
    let taskRules: [TaskRule]
    /// Wave 2 — Ancestry deepening. Structured eligibility metadata used by the
    /// Wizard intro card and the Decision Tree explanation layer. Optional for
    /// backward compat with v1/v2 tracks that don't carry a rule yet.
    let eligibilityRule: EligibilityRule?
}

/// Structured eligibility metadata for ancestry / citizenship-by-descent tracks.
/// Surfaced in the Wizard intro card and the Decision Tree handoff. Carries the
/// in-flux flag that drives the "rules changing — verify before you start"
/// banner.
struct EligibilityRule: Codable, Hashable {
    /// Headline rule, e.g. "Limited to descendants of an Italian-born parent or
    /// grandparent (Law 74/2025)".
    let summary: String
    /// Generations of descent the track currently allows, e.g. 2 for
    /// post-DL-36/2025 Italy, 4 for older Italian rules, nil for tracks where
    /// the concept doesn't apply.
    let generationCutoff: Int?
    /// True for tracks with a special-court / pre-1948 maternal-line carve-out
    /// (Italy Jure Sanguinis). Drives an extra "1948 case" callout.
    let maternalLineCutoff: Bool
    /// Bullet criteria the user should self-check before starting the track.
    let criteria: [String]
    /// True when the underlying law is in active change and the user must
    /// re-verify before relying on this track. Drives the warning banner on
    /// the Wizard intro screen.
    let inFlux: Bool
    /// Free-text note explaining what is changing — surfaced only when inFlux.
    let inFluxNote: String?
}

struct WizardStep: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let questions: [WizardQuestion]
}

struct WizardQuestion: Codable, Identifiable {
    let id: String
    let type: String // "single_choice", "boolean", "number"
    let label: String
    let options: [QuestionOption]?
    let required: Bool?
    let hint: String?
    let showIf: [String: AnyCodableValue]?
    let min: Int?
    let max: Int?
}

struct QuestionOption: Codable, Identifiable {
    let id: String
    let label: String
}

struct TaskRule: Codable {
    let taskTitle: String
    let phase: String
    let description: String?
    let links: [TaskRuleLink]?
    let conditions: [String: AnyCodableValue]
    let estimatedWeeks: Int?
    let order: Int?
    /// When present, this taskRule also produces a DocumentSlot the user can
    /// fill from the Documents tab. Slots are idempotent via (key, trackId).
    let documentSlot: DocumentSlotRule?
    /// Milestones are time-sensitive calendar events anchored to the wizard's
    /// anchor date. Foundation Wave 1 — see BUILD_PLAN.md for usage.
    let milestones: [MilestoneRule]?
}

struct TaskRuleLink: Codable {
    let label: String
    let url: String
}

struct DocumentSlotRule: Codable {
    let key: String
    let label: String
    let description: String?
    /// Free-text guidance on where to obtain the document. Optional; falls back
    /// to the legacy `description` when absent.
    let whereToObtain: String?
    /// Free-text validity window (e.g. "90 days from issue"). Optional.
    let validityPeriod: String?
    /// True if the document requires Apostille of the Hague to be valid abroad.
    let apostilleRequired: Bool?
    /// True if the document requires a sworn / certified translation.
    let swornTranslationRequired: Bool?
}

/// A time-sensitive event derived from a task rule, anchored to the wizard's
/// anchor date. Materialized into `EventItem` records on the Calendar.
struct MilestoneRule: Codable {
    let key: String
    let title: String
    let description: String?
    let category: String     // matches MilestoneCategory raw values
    /// Days relative to the anchor date. Negative = before anchor, positive = after.
    let daysOffsetFromAnchor: Int
    /// When true, the milestone is scheduled as a local push reminder at 9:00am
    /// on the event day. Default false on decode for backward compat.
    let notificationEnabled: Bool?
}

// MARK: - AnyCodableValue (handles mixed JSON types: string, bool, [string])

enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([String].self) {
            self = .array(arr)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .array(let a): try container.encode(a)
        }
    }

    func matches(_ actual: Any) -> Bool {
        switch self {
        case .bool(let expected):
            return (actual as? Bool) == expected
        case .string(let expected):
            return "\(actual)" == expected
        case .int(let expected):
            return (actual as? Int) == expected
        case .array(let expected):
            return expected.contains("\(actual)")
        }
    }
}
