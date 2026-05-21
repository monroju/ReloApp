import XCTest
import Combine
@testable import GoThere

/// Foundation Wave 1: the integration bus is additive plumbing. These tests
/// confirm publish/subscribe round-trips and that subscribers correctly see
/// each event variant.
final class IntegrationEventsTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_publishedEvent_isReceivedBySubscriber() {
        let expectation = expectation(description: "subscriber receives event")
        var receivedTrackId: String?
        var receivedCountryId: String?

        IntegrationEvents.shared.publisher
            .sink { event in
                if case let .visaCompletion(trackId, countryId, _) = event {
                    receivedTrackId = trackId
                    receivedCountryId = countryId
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        IntegrationEvents.shared.publish(
            .visaCompletion(trackId: "es_nlv", countryId: "spain", anchorDate: Date())
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTrackId, "es_nlv")
        XCTAssertEqual(receivedCountryId, "spain")
    }

    func test_documentSlotStatusChanged_carriesStatus() {
        let exp = expectation(description: "status change received")
        var received: SlotStatus?

        IntegrationEvents.shared.publisher
            .sink { event in
                if case let .documentSlotStatusChanged(_, status) = event {
                    received = status
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        IntegrationEvents.shared.publish(
            .documentSlotStatusChanged(slotId: "slot_1", status: .uploaded)
        )

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(received, .uploaded)
    }

    func test_multipleSubscribers_receiveSameEvent() {
        // Bus must deliver to all current subscribers, not just one.
        let exp1 = expectation(description: "first subscriber")
        let exp2 = expectation(description: "second subscriber")

        IntegrationEvents.shared.publisher
            .sink { event in
                if case .visaUpdate = event { exp1.fulfill() }
            }
            .store(in: &cancellables)
        IntegrationEvents.shared.publisher
            .sink { event in
                if case .visaUpdate = event { exp2.fulfill() }
            }
            .store(in: &cancellables)

        IntegrationEvents.shared.publish(.visaUpdate(visaId: "es_nlv"))

        wait(for: [exp1, exp2], timeout: 1.0)
    }
}
