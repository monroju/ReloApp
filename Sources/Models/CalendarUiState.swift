import Foundation

struct CalendarUiState: Codable, Hashable {
    var month: String
    var selected: String
    var note: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var isSaving: Bool
    var message: String?

    init(
        month: String = "",
        selected: String = "",
        note: String = "",
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        isSaving: Bool = false,
        message: String? = nil
    ) {
        self.month = month
        self.selected = selected
        self.note = note
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isSaving = isSaving
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case month
        case selected
        case note
        case reminderEnabled = "reminder_enabled"
        case reminderHour = "reminder_hour"
        case reminderMinute = "reminder_minute"
        case isSaving = "is_saving"
        case message
    }
}
