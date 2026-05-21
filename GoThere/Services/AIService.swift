import Foundation

/// Wave 2 — AI conversational entry point.
///
/// Calls a thin proxy at `https://api.gothere.app/ai/messages` that adds the
/// Anthropic API key + system prompt server-side. The iOS app never sees the
/// key. Tools are executed on-device against `VisaCatalog`, `CostDatabase`, and
/// `WizardRepository`; the tool registry is duplicated between proxy (so it can
/// advertise the schema to Claude) and the app (so it can execute the call).
///
/// Streaming: `AIStreamHandler` is a pure parser over the Anthropic SSE event
/// shape. The handler is the unit under test; the network layer here is a thin
/// wrapper that drives the handler with bytes from `URLSession.bytes(for:)`.
@MainActor
final class AIService: ObservableObject {

    // MARK: - Constants

    /// Server-side system prompt is keyed by this version string. Bump when the
    /// app needs to enforce a particular prompt revision.
    static let systemPromptVersion = "v1"

    /// Free-tier cap before the paywall gate kicks in. The brief specifies 5.
    static let maxFreeMessages = 5

    /// Proxy endpoint. Override-able via UserDefaults for QA against staging.
    /// The proxy is responsible for choosing the model (currently
    /// `claude-sonnet-4-6` per the operator briefing) and adding the API key.
    static let proxyURL: URL = {
        if let override = UserDefaults.standard.string(forKey: "ai_proxy_url_override"),
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://api.gothere.app/ai/messages")!
    }()

    static let shared = AIService(purchaseManager: PurchaseManager.shared)

    // MARK: - Published state

    @Published var messages: [AIMessage] = []
    @Published var isWaitingForReply: Bool = false
    @Published var lastError: String?
    /// User-facing counter — incremented on each user-initiated send (not on
    /// tool-result loopbacks). Surfaces the "X of 5 free messages" hint.
    @Published var sentMessageCount: Int

    // MARK: - Dependencies

    private let purchaseManager: PurchaseManager
    private let session: URLSession
    private let tools: [AIToolDefinition]
    private let counterKey = "ai_sent_message_count"

    init(
        purchaseManager: PurchaseManager,
        session: URLSession = .shared,
        tools: [AIToolDefinition] = AIToolRegistry.allDefinitions
    ) {
        self.purchaseManager = purchaseManager
        self.session = session
        self.tools = tools
        self.sentMessageCount = UserDefaults.standard.integer(forKey: counterKey)
    }

    // MARK: - Paywall gate

    /// True when the user has used all free messages AND is not entitled to all-access.
    /// View layer must show the paywall before allowing message N+1.
    var isPaywallGated: Bool {
        sentMessageCount >= Self.maxFreeMessages && !purchaseManager.hasAllAccess
    }

    /// Resets the local counter — used after a successful all-access purchase
    /// so the user sees a fresh quota in case they downgrade later.
    func resetFreeMessageCounter() {
        sentMessageCount = 0
        UserDefaults.standard.set(0, forKey: counterKey)
    }

    // MARK: - Sending

    /// Append a user message and drive the proxy → tools → proxy loop until the
    /// assistant lands a final text response (no pending tool_use blocks).
    /// Returns when the conversation reaches a steady state or fails.
    func send(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isPaywallGated else {
            Analytics.log(.aiFreeLimitReached)
            lastError = "You've used all free messages. Upgrade to keep going."
            return
        }

        let userMsg = AIMessage(role: .user, content: [.text(text)])
        messages.append(userMsg)
        bumpCounter()
        Analytics.log(.aiMessageSent, properties: [
            "message_index": sentMessageCount,
            "char_count": text.count
        ])

        await runTurnLoop()
    }

    // MARK: - Conversation loop

    private func runTurnLoop() async {
        isWaitingForReply = true
        defer { isWaitingForReply = false }

        var safetyTurns = 6
        while safetyTurns > 0 {
            safetyTurns -= 1
            do {
                let assistant = try await callProxy()
                messages.append(assistant)

                guard assistant.hasPendingToolUses else { return }

                // Execute every tool_use, append a single user message that
                // collects the corresponding tool_result blocks, then loop.
                let toolResults = assistant.content.compactMap(executeToolBlock)
                guard !toolResults.isEmpty else { return }
                messages.append(AIMessage(role: .user, content: toolResults))
            } catch {
                let summary = (error as? AIServiceError)?.userFacing ?? error.localizedDescription
                lastError = summary
                Analytics.log(.aiErrorReturned, properties: ["error": summary])
                return
            }
        }
        // Conversation exceeded the safety limit — surface a soft message.
        messages.append(AIMessage(
            role: .assistant,
            content: [.text("I'm tripping over my own tools. Try rephrasing your question and I'll start over.")]
        ))
    }

    private func callProxy() async throws -> AIMessage {
        var request = URLRequest(url: Self.proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.systemPromptVersion, forHTTPHeaderField: "X-System-Prompt-Version")

        let body = AIProxyRequest(
            systemPromptVersion: Self.systemPromptVersion,
            messages: messages,
            tools: tools
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.transport("Unexpected response type")
        }
        guard (200..<300).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "(no body)"
            throw AIServiceError.proxyStatus(http.statusCode, raw)
        }
        do {
            let decoded = try JSONDecoder().decode(AIProxyResponse.self, from: data)
            return decoded.message
        } catch {
            throw AIServiceError.decode(error.localizedDescription)
        }
    }

    // MARK: - Tool execution

    private func executeToolBlock(_ block: AIContentBlock) -> AIContentBlock? {
        guard case let .toolUse(id, name, input) = block else { return nil }
        Analytics.log(.aiToolCalled, properties: ["tool": name])
        let result = AIToolRegistry.execute(name: name, input: input)
        return .toolResult(toolUseId: id, content: result.payload, isError: result.isError)
    }

    // MARK: - Counter

    private func bumpCounter() {
        sentMessageCount += 1
        UserDefaults.standard.set(sentMessageCount, forKey: counterKey)
    }
}

// MARK: - Errors

enum AIServiceError: Error {
    case transport(String)
    case proxyStatus(Int, String)
    case decode(String)

    var userFacing: String {
        switch self {
        case .transport(let s):
            return "Connection problem: \(s)"
        case .proxyStatus(let code, _):
            return "Couldn't reach the assistant (HTTP \(code))."
        case .decode(let s):
            return "I received an unexpected reply: \(s)"
        }
    }
}
