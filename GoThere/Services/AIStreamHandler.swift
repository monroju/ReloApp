import Foundation

/// Pure parser for Anthropic-Messages-API SSE streams as relayed by the GoThere
/// proxy. The handler accumulates content_block_start + content_block_delta +
/// content_block_stop events into a typed `AIMessage`, then exposes the result
/// when message_stop arrives.
///
/// This is the unit-under-test for the streaming response. Network code lives
/// in AIService; the handler stays pure and synchronous so the test suite can
/// drive it with a recorded fixture rather than hitting the live API.
///
/// SSE event reference (Anthropic):
///   event: message_start          { "type": "message_start", "message": {...} }
///   event: content_block_start    { "type": "content_block_start", "index": 0, "content_block": {...} }
///   event: content_block_delta    { "type": "content_block_delta", "index": 0, "delta": {...} }
///   event: content_block_stop     { "type": "content_block_stop", "index": 0 }
///   event: message_delta          { "type": "message_delta", "delta": {...} }
///   event: message_stop           { "type": "message_stop" }
final class AIStreamHandler {

    // MARK: - Public state

    /// Updated as text deltas arrive. The view layer can observe the current
    /// in-progress assistant text by reading `partialText` between events.
    private(set) var partialText: String = ""
    private(set) var stopReason: String?
    private(set) var isComplete: Bool = false

    // MARK: - Internal accumulators

    private var assistantId: String = UUID().uuidString
    private var blocks: [Int: BlockBuilder] = [:]

    enum BlockBuilder {
        case text(String)
        case toolUse(id: String, name: String, partialJSON: String)
    }

    // MARK: - Input API

    /// Feed one full SSE chunk (may contain multiple lines) into the handler.
    /// Returns true when the stream is complete.
    @discardableResult
    func feed(_ chunk: String) -> Bool {
        // SSE events are separated by blank lines; each event is one-or-more
        // `field: value` lines. We only care about the `data:` payload.
        for line in chunk.split(separator: "\n", omittingEmptySubsequences: false) {
            let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard s.hasPrefix("data:") else { continue }
            let json = s.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
            if json.isEmpty { continue }
            if json == "[DONE]" { isComplete = true; continue }
            guard let data = json.data(using: .utf8) else { continue }
            handleEvent(data)
        }
        return isComplete
    }

    /// Convenience for tests: feed an entire fixture in one shot.
    func feedAll(_ fixture: String) -> AIMessage? {
        feed(fixture)
        return finalize()
    }

    /// Produce the materialized AIMessage. Safe to call multiple times — emits
    /// whatever has been accumulated so far. Returns nil before any content has
    /// arrived.
    func finalize() -> AIMessage? {
        let ordered = blocks.keys.sorted().compactMap { blocks[$0] }
        let content: [AIContentBlock] = ordered.compactMap { builder in
            switch builder {
            case .text(let t):
                return t.isEmpty ? nil : .text(t)
            case .toolUse(let id, let name, let partial):
                let input = decodeToolInput(partial)
                return .toolUse(id: id, name: name, input: input)
            }
        }
        guard !content.isEmpty else { return nil }
        return AIMessage(id: assistantId, role: .assistant, content: content)
    }

    // MARK: - Event routing

    private func handleEvent(_ data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String
        else { return }

        switch type {
        case "message_start":
            if let msg = obj["message"] as? [String: Any], let id = msg["id"] as? String {
                assistantId = id
            }
        case "content_block_start":
            handleBlockStart(obj)
        case "content_block_delta":
            handleBlockDelta(obj)
        case "content_block_stop":
            break
        case "message_delta":
            if let delta = obj["delta"] as? [String: Any], let reason = delta["stop_reason"] as? String {
                stopReason = reason
            }
        case "message_stop":
            isComplete = true
        default:
            break
        }
    }

    private func handleBlockStart(_ obj: [String: Any]) {
        guard let idx = obj["index"] as? Int,
              let cb = obj["content_block"] as? [String: Any],
              let cbType = cb["type"] as? String
        else { return }
        switch cbType {
        case "text":
            let initial = cb["text"] as? String ?? ""
            blocks[idx] = .text(initial)
        case "tool_use":
            let id = cb["id"] as? String ?? ""
            let name = cb["name"] as? String ?? ""
            blocks[idx] = .toolUse(id: id, name: name, partialJSON: "")
        default:
            break
        }
    }

    private func handleBlockDelta(_ obj: [String: Any]) {
        guard let idx = obj["index"] as? Int,
              let delta = obj["delta"] as? [String: Any],
              let dType = delta["type"] as? String,
              let current = blocks[idx]
        else { return }

        switch (dType, current) {
        case ("text_delta", .text(let acc)):
            let chunk = delta["text"] as? String ?? ""
            let next = acc + chunk
            blocks[idx] = .text(next)
            partialText.append(chunk)
        case ("input_json_delta", .toolUse(let id, let name, let acc)):
            let partial = delta["partial_json"] as? String ?? ""
            blocks[idx] = .toolUse(id: id, name: name, partialJSON: acc + partial)
        default:
            break
        }
    }

    private func decodeToolInput(_ json: String) -> AIToolInput {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let input = try? JSONDecoder().decode(AIToolInput.self, from: data)
        else { return AIToolInput([:]) }
        return input
    }
}
