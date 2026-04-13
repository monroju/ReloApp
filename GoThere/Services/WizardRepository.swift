import Foundation

/// Loads visa wizard config and generates personalized tasks from user answers.
final class WizardRepository {
    static let shared = WizardRepository()
    private var cachedConfig: WizardConfig?

    private init() {}

    func loadConfig() -> WizardConfig? {
        if let cached = cachedConfig { return cached }

        guard let url = Bundle.main.url(forResource: "wizard_config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(WizardConfig.self, from: data)
        else { return nil }

        cachedConfig = config
        return config
    }

    func tracksForCountry(_ countryId: String) -> [(String, WizardTrack)] {
        guard let config = loadConfig() else { return [] }
        return config.tracks
            .filter { $0.value.countryId == countryId }
            .map { ($0.key, $0.value) }
    }

    /// Generate personalized TaskItem list from wizard answers.
    func generateTasks(
        track: WizardTrack,
        answers: [String: Any],
        targetWeeksFromNow: Int
    ) -> [TaskItem] {
        let now = Date()

        return track.taskRules
            .filter { evaluateConditions($0.conditions, answers: answers) }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            .map { rule in
                let title = replaceVars(rule.taskTitle, answers: answers)
                let desc = rule.description.map { replaceVars($0, answers: answers) }

                let weeks = rule.estimatedWeeks ?? 0
                let dueAt: Date? = if weeks > 0, targetWeeksFromNow > 0 {
                    Calendar.current.date(
                        byAdding: .weekOfYear,
                        value: max(targetWeeksFromNow - weeks, 0),
                        to: now
                    )
                } else {
                    nil
                }

                let links = rule.links?.map { AppLink(label: $0.label, url: $0.url) }

                return TaskItem(
                    title: title,
                    description: desc,
                    category: rule.phase,
                    completed: false,
                    dueAt: dueAt,
                    createdAt: Date(),
                    countryId: track.countryId,
                    links: links
                )
            }
    }

    static func targetWeeks(from choice: String) -> Int {
        switch choice {
        case "asap": return 12
        case "3_months": return 13
        case "6_months": return 26
        case "1_year": return 52
        default: return 26
        }
    }

    // MARK: - Private

    private func evaluateConditions(_ conditions: [String: AnyCodableValue], answers: [String: Any]) -> Bool {
        if conditions.isEmpty { return true }
        for (key, expected) in conditions {
            guard let actual = answers[key] else { return false }
            if !expected.matches(actual) { return false }
        }
        return true
    }

    private func replaceVars(_ text: String, answers: [String: Any]) -> String {
        var result = text
        for (key, value) in answers {
            result = result.replacingOccurrences(of: "{\(key)}", with: "\(value)")
        }
        return result
    }
}
