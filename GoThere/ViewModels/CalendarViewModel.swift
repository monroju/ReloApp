import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [EventItem] = []
    @Published var selectedDate = Date()
    @Published var showAddEvent = false
    @Published var newEventTitle = ""

    private let repo = EventsRepository.shared
    private var cancellables = Set<AnyCancellable>()

    var eventsForSelectedDate: [EventItem] {
        let cal = Calendar.current
        return events.filter { event in
            cal.isDate(event.date, inSameDayAs: selectedDate)
        }
    }

    var upcomingEvents: [EventItem] {
        repo.upcomingEvents(limit: 10)
    }

    func startListening() {
        repo.startListening()
        repo.$events
            .receive(on: DispatchQueue.main)
            .assign(to: &$events)
    }

    func addEvent() {
        guard !newEventTitle.isEmpty else { return }
        let title = newEventTitle
        let date = selectedDate
        newEventTitle = ""
        showAddEvent = false
        Task {
            try? await repo.addEvent(title: title, date: date)
            NotificationManager.shared.scheduleNotification(for: EventItem(
                title: title,
                dateMillis: date.timeIntervalSince1970 * 1000
            ))
        }
    }

    func updateTitle(_ event: EventItem, title: String) {
        Task { try? await repo.updateTitle(eventId: event.id, title: title) }
    }

    func updateDate(_ event: EventItem, date: Date) {
        Task { try? await repo.updateDate(eventId: event.id, date: date) }
    }

    func deleteEvent(_ event: EventItem) {
        NotificationManager.shared.cancelNotification(eventId: event.id)
        Task { try? await repo.deleteEvent(eventId: event.id) }
    }
}
