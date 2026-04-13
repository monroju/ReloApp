import Foundation

// MARK: - Wizard Config (parsed from wizard_config.json)

struct WizardConfig: Codable {
    let wizardVersion: Int
    let tracks: [String: WizardTrack]
}

struct WizardTrack: Codable {
    let displayName: String
    let countryId: String
    let shortName: String
    let steps: [WizardStep]
    let taskRules: [TaskRule]
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
}

struct TaskRuleLink: Codable {
    let label: String
    let url: String
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
