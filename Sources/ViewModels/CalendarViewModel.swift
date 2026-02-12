import Foundation
import Observation

@Observable
final class CalendarViewModel {

    // MARK: - Calendar State

    var selectedDate: Date = Date()
    var displayedMonth: Date = Date()
    var events: [EventItem] = []

    // MARK: - Event Editor State

    var isEditorPresented: Bool = false
    var editorTitle: String = ""
    var editorNote: String = ""
    var editorReminderEnabled: Bool = false
    var editorReminderHour: Int = 9
    var editorReminderMinute: Int = 0

    // MARK: - General UI

    var isSaving: Bool = false
    var toastMessage: String? = nil
    var editingEvent: EventItem? = nil

    // MARK: - Computed

    var eventsForSelectedDate: [EventItem] {
        let cal = Calendar.current
        return events.filter { event in
            let eventDate = Date(timeIntervalSince1970: TimeInterval(event.dateMillis) / 1000)
            return cal.isDate(eventDate, inSameDayAs: selectedDate)
        }
        .sorted { $0.dateMillis < $1.dateMillis }
    }

    var daysInMonth: [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        return range.compactMap { day in
            cal.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    var firstWeekdayOffset: Int {
        let cal = Calendar.current
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) else {
            return 0
        }
        let weekday = cal.component(.weekday, from: firstOfMonth)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Month Navigation

    func previousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = prev
        }
    }

    func nextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = next
        }
    }

    // MARK: - Event Helpers

    func hasEvents(on date: Date) -> Bool {
        let cal = Calendar.current
        return events.contains { event in
            let eventDate = Date(timeIntervalSince1970: TimeInterval(event.dateMillis) / 1000)
            return cal.isDate(eventDate, inSameDayAs: date)
        }
    }

    func eventCount(on date: Date) -> Int {
        let cal = Calendar.current
        return events.filter { event in
            let eventDate = Date(timeIntervalSince1970: TimeInterval(event.dateMillis) / 1000)
            return cal.isDate(eventDate, inSameDayAs: date)
        }.count
    }

    // MARK: - CRUD Actions

    func presentNewEvent() {
        editingEvent = nil
        editorTitle = ""
        editorNote = ""
        editorReminderEnabled = false
        editorReminderHour = 9
        editorReminderMinute = 0
        isEditorPresented = true
    }

    func presentEditEvent(_ event: EventItem) {
        editingEvent = event
        editorTitle = event.title
        editorNote = event.notes ?? ""
        isEditorPresented = true
    }

    func saveEvent() {
        guard !editorTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true

        let millis = Int64(selectedDate.timeIntervalSince1970 * 1000)

        if let existing = editingEvent, let idx = events.firstIndex(where: { $0.id == existing.id }) {
            events[idx] = EventItem(
                id: existing.id,
                title: editorTitle.trimmingCharacters(in: .whitespaces),
                dateMillis: millis,
                notes: editorNote.isEmpty ? nil : editorNote,
                createdAt: existing.createdAt
            )
            toastMessage = "Event updated"
        } else {
            let newEvent = EventItem(
                id: UUID().uuidString,
                title: editorTitle.trimmingCharacters(in: .whitespaces),
                dateMillis: millis,
                notes: editorNote.isEmpty ? nil : editorNote
            )
            events.append(newEvent)
            toastMessage = "Event added"
        }

        // Placeholder: persist to Firestore
        isSaving = false
        isEditorPresented = false
        editingEvent = nil
    }

    func deleteEvent(_ event: EventItem) {
        events.removeAll { $0.id == event.id }
        toastMessage = "Event deleted"
        // Placeholder: remove from Firestore
    }

    func dismissToast() {
        toastMessage = nil
    }

    // MARK: - Snapshot

    func snapshot() -> CalendarUiState {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthStr = formatter.string(from: displayedMonth)
        formatter.dateFormat = "yyyy-MM-dd"
        let selectedStr = formatter.string(from: selectedDate)
        return CalendarUiState(
            month: monthStr,
            selected: selectedStr,
            note: editorNote,
            reminderEnabled: editorReminderEnabled,
            reminderHour: editorReminderHour,
            reminderMinute: editorReminderMinute,
            isSaving: isSaving,
            message: toastMessage
        )
    }
}
