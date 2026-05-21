import SwiftUI

/// Visual presentation for milestone categories shown in the Calendar tab.
/// Wave 1 (T1b-finish) — color and icon per category. Keep palette aligned
/// to the GoThere theme (goError/goWarning/goPrimary/goSuccess).
extension MilestoneCategory {
    var displayColor: Color {
        switch self {
        case .deadline:    return .goError       // red — hard deadline
        case .expiration:  return .goWarning     // orange — document expires
        case .appointment: return .goPrimary     // teal — scheduled meeting
        case .milestone:   return .goSuccess     // green — milestone reached
        }
    }

    var iconName: String {
        switch self {
        case .deadline:    return "exclamationmark.circle.fill"
        case .expiration:  return "clock.badge.exclamationmark"
        case .appointment: return "calendar.badge.clock"
        case .milestone:   return "flag.fill"
        }
    }

    var displayLabel: String {
        switch self {
        case .deadline:    return "Deadline"
        case .expiration:  return "Expires"
        case .appointment: return "Appointment"
        case .milestone:   return "Milestone"
        }
    }
}
