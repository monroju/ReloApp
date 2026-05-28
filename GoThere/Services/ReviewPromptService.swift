import Foundation
import StoreKit
import UIKit

enum ReviewMilestone: String {
    case firstTaskCompleted = "rp_first_task_completed"
    case visaCompareViewed = "rp_visa_compare_viewed"
    case wizardCompleted = "rp_wizard_completed"
}

enum ReviewPromptService {
    private static let lastPromptKey = "rp_last_prompt_at"
    private static let promptedThisVersionKey = "rp_prompted_for_version"
    private static let minDaysBetween: TimeInterval = 60 * 60 * 24 * 120

    static func recordAndMaybeRequest(_ milestone: ReviewMilestone) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: milestone.rawValue) { return }
        defaults.set(true, forKey: milestone.rawValue)
        requestIfEligible()
    }

    private static func requestIfEligible() {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        if defaults.string(forKey: promptedThisVersionKey) == version { return }

        let last = defaults.double(forKey: lastPromptKey)
        if last > 0, Date().timeIntervalSince1970 - last < minDaysBetween { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
            defaults.set(Date().timeIntervalSince1970, forKey: lastPromptKey)
            defaults.set(version, forKey: promptedThisVersionKey)
        }
    }
}
