import Foundation

/// Wire format for the GoThere AI conversation. Mirrors a subset of the Anthropic
/// Messages API content blocks. The iOS app handles tool execution locally and
/// loops back through the proxy at api.getgothere.app/ai/messages — the proxy adds
/// the API key + system prompt and never sees user state beyond what we send.

enum AIRole: String, Codable {
    case user
    case assistant
}

/// A single content block inside a Messages-API turn. We support exactly three
/// block types: plain text, tool_use (model → app), and tool_result (app → model).
enum AIContentBlock: Codable, Equatable {
    case text(String)
    case toolUse(id: String, name: String, input: AIToolInput)
    case toolResult(toolUseId: String, content: String, isError: Bool)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case id
        case name
        case input
        case toolUseId = "tool_use_id"
        case content
        case isError = "is_error"
    }

    enum BlockType: String, Codable {
        case text
        case toolUse = "tool_use"
        case toolResult = "tool_result"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(BlockType.self, forKey: .type)
        switch type {
        case .text:
            self = .text(try c.decode(String.self, forKey: .text))
        case .toolUse:
            self = .toolUse(
                id: try c.decode(String.self, forKey: .id),
                name: try c.decode(String.self, forKey: .name),
                input: try c.decode(AIToolInput.self, forKey: .input)
            )
        case .toolResult:
            self = .toolResult(
                toolUseId: try c.decode(String.self, forKey: .toolUseId),
                content: try c.decode(String.self, forKey: .content),
                isError: (try? c.decode(Bool.self, forKey: .isError)) ?? false
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let txt):
            try c.encode(BlockType.text, forKey: .type)
            try c.encode(txt, forKey: .text)
        case .toolUse(let id, let name, let input):
            try c.encode(BlockType.toolUse, forKey: .type)
            try c.encode(id, forKey: .id)
            try c.encode(name, forKey: .name)
            try c.encode(input, forKey: .input)
        case .toolResult(let toolUseId, let content, let isError):
            try c.encode(BlockType.toolResult, forKey: .type)
            try c.encode(toolUseId, forKey: .toolUseId)
            try c.encode(content, forKey: .content)
            if isError { try c.encode(true, forKey: .isError) }
        }
    }
}

/// Per-turn message shape used both on the wire and in the on-device transcript.
struct AIMessage: Codable, Equatable, Identifiable {
    let id: String
    let role: AIRole
    let content: [AIContentBlock]

    init(id: String = UUID().uuidString, role: AIRole, content: [AIContentBlock]) {
        self.id = id
        self.role = role
        self.content = content
    }

    /// Convenience: flat plain-text projection of the message for rendering in
    /// the chat bubble. Tool-use blocks render as a small "calling X" line;
    /// tool-result blocks are hidden from the user.
    var displayText: String {
        content.compactMap { block in
            switch block {
            case .text(let t): return t
            case .toolUse(_, let name, _): return "_Calling \(name)…_"
            case .toolResult: return nil
            }
        }.joined(separator: "\n")
    }

    /// True when the message contains at least one tool_use block — the iOS app
    /// must execute the tool(s) and feed results back on the next turn.
    var hasPendingToolUses: Bool {
        content.contains {
            if case .toolUse = $0 { return true }
            return false
        }
    }
}

/// Strongly-typed input parameter container for a tool call. We do not try to
/// model the full JSON Schema universe — the tools we expose take string- and
/// int-valued arguments only.
struct AIToolInput: Codable, Equatable {
    private var values: [String: AIToolValue]

    init(_ values: [String: AIToolValue] = [:]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.values = try c.decode([String: AIToolValue].self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(values)
    }

    subscript(key: String) -> AIToolValue? {
        values[key]
    }

    func string(_ key: String) -> String? {
        guard let v = values[key], case .string(let s) = v else { return nil }
        return s
    }

    func int(_ key: String) -> Int? {
        if let v = values[key] {
            switch v {
            case .int(let n): return n
            case .double(let d): return Int(d)
            case .string(let s): return Int(s)
            default: return nil
            }
        }
        return nil
    }
}

enum AIToolValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported tool input value")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .int(let i): try c.encode(i)
        case .double(let d): try c.encode(d)
        case .bool(let b): try c.encode(b)
        }
    }
}

/// Tool definitions advertised to the model. Mirrors the Anthropic tool schema
/// shape but expressed as Swift literals so we can compile-check the input keys
/// we then read in the on-device executor.
struct AIToolDefinition: Codable, Equatable {
    let name: String
    let description: String
    let inputSchema: AIToolInputSchema

    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case inputSchema = "input_schema"
    }
}

struct AIToolInputSchema: Codable, Equatable {
    let type: String
    let properties: [String: AIToolPropertySchema]
    let required: [String]

    init(type: String = "object", properties: [String: AIToolPropertySchema], required: [String] = []) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

struct AIToolPropertySchema: Codable, Equatable {
    let type: String
    let description: String?
    let `enum`: [String]?

    init(type: String, description: String? = nil, enum enumValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.enum = enumValues
    }
}

// MARK: - Proxy request / response

/// Body sent to `POST api.getgothere.app/ai/messages`. The proxy adds the API key,
/// the system prompt (keyed by version), and the model name on its side — we
/// pin the version here so the app can render a "Tap to update" hint if the
/// proxy advertises a newer one.
struct AIProxyRequest: Codable {
    let systemPromptVersion: String
    let messages: [AIMessage]
    let tools: [AIToolDefinition]

    private enum CodingKeys: String, CodingKey {
        case systemPromptVersion = "system_prompt_version"
        case messages
        case tools
    }
}

/// Non-streaming response shape. Streaming SSE responses are decoded into the
/// same message via AIStreamHandler before reaching the view layer.
struct AIProxyResponse: Codable {
    let message: AIMessage
    let stopReason: String?
    let usage: AIUsage?

    private enum CodingKeys: String, CodingKey {
        case message
        case stopReason = "stop_reason"
        case usage
    }
}

struct AIUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?

    private enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}
