import XCTest
@testable import GoThere

/// Wave 2 — AI conversational entry point.
///
/// AIStreamHandler is the unit-under-test for the streaming response. The
/// fixture below is a hand-written SSE transcript modeled on the Anthropic
/// Messages-API stream shape. We never hit the live API from CI.
final class AIStreamHandlerTests: XCTestCase {

    // MARK: - Fixtures

    /// Recorded fixture: assistant emits a short text block then a tool_use
    /// block targeting recommend_visas. Mirrors the SSE wire format Anthropic
    /// returns and the proxy re-emits unchanged.
    private let textPlusToolUseFixture = """
    event: message_start
    data: {"type":"message_start","message":{"id":"msg_fixture_01","role":"assistant","model":"claude-sonnet-4-6","content":[],"stop_reason":null}}

    event: content_block_start
    data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Let me check"}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" your options."}}

    event: content_block_stop
    data: {"type":"content_block_stop","index":0}

    event: content_block_start
    data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01abc","name":"recommend_visas","input":{}}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"country_id\\":\\"spain\\","}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"\\"household\\":\\"couple\\",\\"budget\\":\\"medium\\"}"}}

    event: content_block_stop
    data: {"type":"content_block_stop","index":1}

    event: message_delta
    data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":42}}

    event: message_stop
    data: {"type":"message_stop"}

    """

    /// Pure-text fixture (no tool calls). Common case after the model has all
    /// the info it needs.
    private let pureTextFixture = """
    event: message_start
    data: {"type":"message_start","message":{"id":"msg_fixture_text","role":"assistant","model":"claude-sonnet-4-6","content":[],"stop_reason":null}}

    event: content_block_start
    data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" there!"}}

    event: content_block_stop
    data: {"type":"content_block_stop","index":0}

    event: message_delta
    data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}

    event: message_stop
    data: {"type":"message_stop"}

    """

    // MARK: - Tests

    func test_streamHandler_assemblesTextAndToolUseBlocks() {
        let handler = AIStreamHandler()
        let result = handler.feedAll(textPlusToolUseFixture)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "msg_fixture_01")
        XCTAssertEqual(result?.role, .assistant)
        XCTAssertEqual(result?.content.count, 2)

        guard case .text(let txt) = result?.content.first else {
            XCTFail("First block must be text"); return
        }
        XCTAssertEqual(txt, "Let me check your options.")

        guard case let .toolUse(id, name, input) = result?.content.last else {
            XCTFail("Second block must be tool_use"); return
        }
        XCTAssertEqual(id, "toolu_01abc")
        XCTAssertEqual(name, "recommend_visas")
        XCTAssertEqual(input.string("country_id"), "spain")
        XCTAssertEqual(input.string("household"), "couple")
        XCTAssertEqual(input.string("budget"), "medium")
    }

    func test_streamHandler_pureTextStreamYieldsSingleBlock() {
        let handler = AIStreamHandler()
        let msg = handler.feedAll(pureTextFixture)
        XCTAssertNotNil(msg)
        XCTAssertEqual(msg?.content.count, 1)
        XCTAssertEqual(msg?.displayText, "Hello there!")
        XCTAssertEqual(handler.stopReason, "end_turn")
        XCTAssertTrue(handler.isComplete)
    }

    func test_streamHandler_partialTextIsAccessibleMidStream() {
        // Feed only the first half of the stream. partialText must reflect
        // what we've seen so far — drives the typing-indicator → live-text
        // transition on the chat view.
        let handler = AIStreamHandler()
        let firstHalf = """
        event: message_start
        data: {"type":"message_start","message":{"id":"msg_partial","role":"assistant","model":"claude-sonnet-4-6","content":[],"stop_reason":null}}

        event: content_block_start
        data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

        event: content_block_delta
        data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"In progress"}}

        """
        handler.feed(firstHalf)
        XCTAssertEqual(handler.partialText, "In progress")
        XCTAssertFalse(handler.isComplete)
    }
}

// MARK: - Tool registry tests

/// Verify on-device tool execution returns the expected JSON shapes. The model
/// reads these strings; field-name regressions silently break the assistant.
final class AIToolRegistryTests: XCTestCase {

    func test_listCitiesForCountry_returnsCityArray() {
        let input = AIToolInput([
            "country_id": .string("spain")
        ])
        let result = AIToolRegistry.execute(name: "list_cities_for_country", input: input)
        XCTAssertFalse(result.isError)
        XCTAssertTrue(result.payload.contains("\"cities\""))
        XCTAssertTrue(result.payload.contains("madrid"))
    }

    func test_listWizardTracksForCountry_returnsAtLeastOneTrack() {
        let input = AIToolInput([
            "country_id": .string("italy")
        ])
        let result = AIToolRegistry.execute(name: "list_wizard_tracks_for_country", input: input)
        XCTAssertFalse(result.isError)
        XCTAssertTrue(result.payload.contains("\"tracks\""))
        XCTAssertTrue(result.payload.contains("it_jure_sanguinis"), "Italy track must be discoverable by the model")
    }

    func test_listWizardTracks_surfacesInFluxFlag() {
        let input = AIToolInput([
            "country_id": .string("italy")
        ])
        let result = AIToolRegistry.execute(name: "list_wizard_tracks_for_country", input: input)
        XCTAssertTrue(result.payload.contains("\"in_flux\":true"),
                      "Italy in-flux signal must reach the model — otherwise it gives confidently wrong DL 36/2025 advice")
    }

    func test_recommendVisas_returnsResultsArray() {
        let input = AIToolInput([
            "country_id": .string("spain"),
            "household": .string("couple"),
            "budget": .string("medium")
        ])
        let result = AIToolRegistry.execute(name: "recommend_visas", input: input)
        XCTAssertFalse(result.isError)
        XCTAssertTrue(result.payload.contains("\"results\""))
    }

    func test_unknownTool_returnsError() {
        let result = AIToolRegistry.execute(name: "definitely_not_a_tool", input: AIToolInput())
        XCTAssertTrue(result.isError)
    }

    func test_missingCountryId_returnsError() {
        let result = AIToolRegistry.execute(name: "list_cities_for_country", input: AIToolInput())
        XCTAssertTrue(result.isError)
    }

    // MARK: - Tool definition surface

    func test_allDefinitionsHaveDistinctNames() {
        let names = AIToolRegistry.allDefinitions.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "Tool names must be unique — duplicates make Claude's tool routing ambiguous")
    }

    func test_definitionsRoundtripThroughJSON() throws {
        for def in AIToolRegistry.allDefinitions {
            let data = try JSONEncoder().encode(def)
            let decoded = try JSONDecoder().decode(AIToolDefinition.self, from: data)
            XCTAssertEqual(decoded.name, def.name)
            XCTAssertEqual(decoded.description, def.description)
        }
    }
}

// MARK: - AIMessage Codable tests

final class AIMessageCodableTests: XCTestCase {

    func test_textBlock_roundtripsThroughJSON() throws {
        let msg = AIMessage(role: .user, content: [.text("Hello")])
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(AIMessage.self, from: data)
        XCTAssertEqual(decoded, msg)
    }

    func test_toolUseBlock_roundtrips() throws {
        let block = AIContentBlock.toolUse(
            id: "tu_1",
            name: "recommend_visas",
            input: AIToolInput([
                "country_id": .string("spain"),
                "budget": .string("medium")
            ])
        )
        let msg = AIMessage(role: .assistant, content: [block])
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(AIMessage.self, from: data)
        XCTAssertEqual(decoded.content.count, 1)
        guard case let .toolUse(id, name, input) = decoded.content.first else {
            XCTFail("Expected tool_use block"); return
        }
        XCTAssertEqual(id, "tu_1")
        XCTAssertEqual(name, "recommend_visas")
        XCTAssertEqual(input.string("country_id"), "spain")
    }

    func test_toolResultBlock_roundtrips() throws {
        let block = AIContentBlock.toolResult(
            toolUseId: "tu_1",
            content: "{\"results\":[]}",
            isError: false
        )
        let msg = AIMessage(role: .user, content: [block])
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(AIMessage.self, from: data)
        XCTAssertEqual(decoded, msg)
    }

    func test_messageWithToolUse_flagsAsPending() {
        let msg = AIMessage(role: .assistant, content: [
            .text("Looking that up."),
            .toolUse(id: "tu_2", name: "list_cities_for_country", input: AIToolInput(["country_id": .string("spain")]))
        ])
        XCTAssertTrue(msg.hasPendingToolUses)
    }

    func test_pureTextMessage_notFlaggedAsPending() {
        let msg = AIMessage(role: .assistant, content: [.text("Hi")])
        XCTAssertFalse(msg.hasPendingToolUses)
    }
}
