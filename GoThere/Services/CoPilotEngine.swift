import Foundation

// MARK: - Read model

/// Aggregate of everything GoThere knows about a user's move, assembled from the
/// existing stores (visa, calculator, household, tasks, documents, cita). This is
/// a pure value type with NO dependencies on Firestore/UserDefaults so the
/// insight engine below is fully unit-testable. `CoPilotViewModel` builds it from
/// live sources; tests build it by hand.
struct UserMoveState {
    var selectedCountryName: String?
    var selectedVisa: VisaInfo?
    var targetMoveDate: Date?
    var estimatedMonthlyCostEUR: Int?
    var estimateCity: String?
    var dependents: Int = 0

    // Tasks
    var taskTotal: Int = 0
    var taskCompleted: Int = 0
    var earliestTaskDate: Date?

    // Documents (from the vault summary + the specific docs nearing expiry)
    var docComplete: Int = 0
    var docExpiringSoon: Int = 0
    var docExpired: Int = 0
    var docMissing: Int = 0
    /// Uploaded documents that still need an apostille or sworn translation.
    var docPrepPending: Int = 0
    var prepDocuments: [String] = []
    /// Documents with an expiration concern, for per-document gap cards.
    var expiringDocuments: [ExpiringDoc] = []

    // Cita
    var activeCitaMonitors: Int = 0
    var citaSample: String?   // "NIE — Initial · Madrid"

    struct ExpiringDoc: Equatable {
        var name: String
        var daysUntil: Int      // negative = already expired
    }

    /// True when the user has done essentially nothing yet — drives the setup state.
    var isEmpty: Bool {
        selectedVisa == nil && targetMoveDate == nil &&
        estimatedMonthlyCostEUR == nil && taskTotal == 0
    }

    /// Required monthly income for the selected visa at the user's dependent count.
    /// Nil when no visa is selected or the visa uses non-income criteria.
    var requiredMonthlyIncomeEUR: Int? {
        selectedVisa?.requiredMonthlyEUR(dependents: dependents)
    }

    var daysToTarget: Int? {
        guard let t = targetMoveDate else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: t)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }
}

// MARK: - Insight cards

enum InsightSeverity: Int, Comparable {
    case red = 0, amber = 1, green = 2
    static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Where a card's CTA routes. The dashboard maps these to navigation.
enum InsightRoute: String, Identifiable, Hashable {
    case documents, tasks, calculator, wizard, cita, decision, resources
    var id: String { rawValue }
}

struct InsightCard: Identifiable, Equatable {
    let id: String
    let severity: InsightSeverity
    let icon: String
    let title: String
    let message: String
    var ctaLabel: String?
    var route: InsightRoute?
}

// MARK: - Readiness

struct ReadinessScore {
    let value: Int            // 0...100
    let label: String
    let taskComponent: Double // 0...1, for debugging/UI rings if desired
    let docComponent: Double
    let incomeComponent: Double
    let timelineComponent: Double
}

// MARK: - Engine

/// Pure functions turning a `UserMoveState` into a readiness score and a sorted
/// list of compound-intelligence cards. No I/O — every output is a function of
/// the input value. All copy is informational; nothing here is legal/financial
/// advice (validity periods and income thresholds are "verify with official
/// sources").
enum CoPilotEngine {

    // Readiness weights (sum 100). Components with no data are dropped and the
    // remaining weights renormalized, so early users aren't punished for steps
    // they literally can't have done yet — the setup cards nudge those instead.
    private static let wTask = 40.0
    private static let wDoc = 30.0
    private static let wIncome = 20.0
    private static let wTimeline = 10.0

    static func readiness(_ s: UserMoveState) -> ReadinessScore {
        var weighted = 0.0, totalWeight = 0.0

        let task = taskScore(s)
        if let task { weighted += task * wTask; totalWeight += wTask }

        let doc = docScore(s)
        if let doc { weighted += doc * wDoc; totalWeight += wDoc }

        let income = incomeScore(s)
        if let income { weighted += income * wIncome; totalWeight += wIncome }

        let timeline = timelineScore(s)
        if let timeline { weighted += timeline * wTimeline; totalWeight += wTimeline }

        let value = totalWeight > 0 ? Int((weighted / totalWeight * 100).rounded()) : 0
        return ReadinessScore(
            value: value,
            label: label(for: value, hasData: totalWeight > 0),
            taskComponent: task ?? 0,
            docComponent: doc ?? 0,
            incomeComponent: income ?? 0,
            timelineComponent: timeline ?? 0
        )
    }

    private static func label(for value: Int, hasData: Bool) -> String {
        guard hasData else { return "Let's set up your move" }
        if value >= 80 { return "You're well-prepared" }
        if value >= 50 { return "A few things need attention" }
        return "Action required before your target date"
    }

    // Component scores — each returns nil when there's no data to judge it on.

    static func taskScore(_ s: UserMoveState) -> Double? {
        guard s.taskTotal > 0 else { return nil }
        return Double(s.taskCompleted) / Double(s.taskTotal)
    }

    static func docScore(_ s: UserMoveState) -> Double? {
        let denom = s.docComplete + s.docExpiringSoon + s.docExpired + s.docMissing
        guard denom > 0 else { return nil }
        // Expiring-soon counts as half credit; expired/missing as none.
        let credit = Double(s.docComplete) + Double(s.docExpiringSoon) * 0.5
        return credit / Double(denom)
    }

    static func incomeScore(_ s: UserMoveState) -> Double? {
        guard let visa = s.selectedVisa else { return nil }
        // Points-based / employer / ancestry tracks have no income test → satisfied.
        guard let required = visa.requiredMonthlyEUR(dependents: s.dependents) else { return 1.0 }
        guard let estimate = s.estimatedMonthlyCostEUR else { return nil } // nudge calculator
        guard required > 0 else { return 1.0 }
        return min(1.0, Double(estimate) / Double(required))
    }

    static func timelineScore(_ s: UserMoveState) -> Double? {
        guard s.targetMoveDate != nil, s.taskTotal > 0, let weeksToFinish = projectedWeeksToFinish(s) else {
            return nil
        }
        let remaining = s.taskTotal - s.taskCompleted
        if remaining <= 0 { return 1.0 }
        guard let daysLeft = s.daysToTarget else { return nil }
        let weeksToTarget = Double(daysLeft) / 7.0
        if weeksToTarget <= 0 { return 0.0 }            // target already passed
        if weeksToFinish <= weeksToTarget { return 1.0 } // on or ahead of pace
        return max(0.0, min(1.0, weeksToTarget / weeksToFinish))
    }

    /// Projected weeks to finish the remaining tasks at the user's observed pace.
    /// Nil when we can't establish a pace yet (no start anchor / nothing done).
    static func projectedWeeksToFinish(_ s: UserMoveState) -> Double? {
        let remaining = s.taskTotal - s.taskCompleted
        if remaining <= 0 { return 0 }
        guard s.taskCompleted > 0, let start = s.earliestTaskDate else { return nil }
        let weeksElapsed = max(0.5, Date().timeIntervalSince(start) / (7 * 24 * 3600))
        let pace = Double(s.taskCompleted) / weeksElapsed   // tasks per week
        guard pace > 0 else { return nil }
        return Double(remaining) / pace
    }

    // MARK: - Cards

    static func generateInsightCards(_ s: UserMoveState) -> [InsightCard] {
        var cards: [InsightCard] = []
        cards.append(contentsOf: setupCards(s))
        cards.append(contentsOf: documentCards(s))
        cards.append(contentsOf: prepCards(s))
        cards.append(contentsOf: incomeCards(s))
        cards.append(contentsOf: timelineCards(s))
        cards.append(contentsOf: citaCards(s))
        cards.append(contentsOf: readyCards(s))
        // Red → amber → green, stable within a band by insertion order.
        return cards.enumerated()
            .sorted { ($0.element.severity, $0.offset) < ($1.element.severity, $1.offset) }
            .map(\.element)
    }

    private static func setupCards(_ s: UserMoveState) -> [InsightCard] {
        var out: [InsightCard] = []
        if s.selectedVisa == nil {
            out.append(InsightCard(
                id: "setup_visa", severity: .amber, icon: "wand.and.stars",
                title: "Pick your visa path",
                message: "Choose a visa so GoThere can check your income fit and build your document list.",
                ctaLabel: "Open Visa Wizard", route: .wizard))
        }
        if s.targetMoveDate == nil {
            out.append(InsightCard(
                id: "setup_date", severity: .amber, icon: "calendar.badge.plus",
                title: "Set a target move date",
                message: "Add when you want to land. We'll pace your tasks and flag documents that expire before then.",
                ctaLabel: "Open Visa Wizard", route: .wizard))
        }
        if s.estimatedMonthlyCostEUR == nil {
            out.append(InsightCard(
                id: "setup_cost", severity: .amber, icon: "dollarsign.circle",
                title: "Estimate your monthly cost",
                message: "Run the Cost Calculator so we can compare your budget to the income your visa requires.",
                ctaLabel: "Open Cost Calculator", route: .calculator))
        }
        return out
    }

    private static func documentCards(_ s: UserMoveState) -> [InsightCard] {
        var out: [InsightCard] = []
        // Most urgent first; cap at 3 so the feed doesn't drown.
        let sorted = s.expiringDocuments.sorted { $0.daysUntil < $1.daysUntil }
        for doc in sorted.prefix(3) {
            let beforeTarget = (s.daysToTarget.map { doc.daysUntil < $0 } ?? false)
            if doc.daysUntil < 0 {
                out.append(InsightCard(
                    id: "doc_\(doc.name)", severity: .red, icon: "doc.badge.ellipsis",
                    title: "Document expired",
                    message: "\(doc.name) expired \(-doc.daysUntil) day\(-doc.daysUntil == 1 ? "" : "s") ago. Renew it before you submit.",
                    ctaLabel: "See documents", route: .documents))
            } else {
                let targetNote = beforeTarget ? " — before your target date" : ""
                out.append(InsightCard(
                    id: "doc_\(doc.name)", severity: doc.daysUntil <= 14 ? .red : .amber,
                    icon: "doc.badge.clock",
                    title: "Document expiring",
                    message: "\(doc.name) expires in \(doc.daysUntil) day\(doc.daysUntil == 1 ? "" : "s")\(targetNote). Plan its renewal.",
                    ctaLabel: "See documents", route: .documents))
            }
        }
        if s.docMissing > 0 {
            out.append(InsightCard(
                id: "doc_missing", severity: .amber, icon: "tray.full",
                title: "\(s.docMissing) document\(s.docMissing == 1 ? "" : "s") still needed",
                message: "Your visa checklist has \(s.docMissing) document\(s.docMissing == 1 ? "" : "s") not yet uploaded.",
                ctaLabel: "Open vault", route: .documents))
        }
        return out
    }

    private static func prepCards(_ s: UserMoveState) -> [InsightCard] {
        guard s.docPrepPending > 0 else { return [] }
        // Name the specific documents when we have a couple; otherwise summarize.
        let named = s.prepDocuments.prefix(2).joined(separator: ", ")
        let detail = named.isEmpty
            ? "\(s.docPrepPending) uploaded document\(s.docPrepPending == 1 ? "" : "s") still need an apostille or sworn translation."
            : "\(named)\(s.docPrepPending > 2 ? " and others" : "") still need an apostille or sworn translation before they're accepted."
        return [InsightCard(
            id: "doc_prep", severity: .amber, icon: "rosette",
            title: "Apostille / translation pending",
            message: detail,
            ctaLabel: "See documents", route: .documents)]
    }

    private static func incomeCards(_ s: UserMoveState) -> [InsightCard] {
        guard let visa = s.selectedVisa else { return [] }
        guard let required = visa.requiredMonthlyEUR(dependents: s.dependents), required > 0 else { return [] }
        guard let estimate = s.estimatedMonthlyCostEUR else { return [] } // setup card already nudges
        let depSuffix = s.dependents > 0 ? " (you + \(s.dependents))" : ""
        let cityNote = s.estimateCity.map { "Your \($0) cost estimate" } ?? "Your cost estimate"
        if estimate >= required {
            let over = estimate - required
            return [InsightCard(
                id: "income_ok", severity: .green, icon: "checkmark.seal",
                title: "Income bar in reach",
                message: "\(cityNote) (€\(estimate.formatted())/mo) already meets the \(visa.shortName) minimum of €\(required.formatted())/mo\(depSuffix) — €\(over.formatted())/mo of headroom. Make sure your provable income clears it.",
                ctaLabel: "Understand the requirement", route: .resources)]
        } else {
            let gap = required - estimate
            return [InsightCard(
                id: "income_gap", severity: .amber, icon: "exclamationmark.triangle",
                title: "Mind the income minimum",
                message: "The \(visa.shortName) asks you to prove €\(required.formatted())/mo\(depSuffix). Your budget estimate is €\(estimate.formatted())/mo — €\(gap.formatted())/mo under the bar you must document.",
                ctaLabel: "Adjust your budget", route: .calculator)]
        }
    }

    private static func timelineCards(_ s: UserMoveState) -> [InsightCard] {
        guard let daysLeft = s.daysToTarget else { return [] }
        if daysLeft < 0 {
            return [InsightCard(
                id: "timeline_past", severity: .amber, icon: "calendar.badge.exclamationmark",
                title: "Update your timeline",
                message: "Your target move date has passed. Set a new one to re-pace your checklist.",
                ctaLabel: "Open Visa Wizard", route: .wizard)]
        }
        guard let weeksToFinish = projectedWeeksToFinish(s), weeksToFinish > 0 else { return [] }
        let weeksToTarget = Double(daysLeft) / 7.0
        let projected = Int(weeksToFinish.rounded())
        if weeksToFinish > weeksToTarget {
            return [InsightCard(
                id: "timeline_behind", severity: .red, icon: "tortoise",
                title: "Pace check",
                message: "Your target is \(daysLeft) days away. At your current pace you'll finish in ~\(projected) weeks. Pick up a few tasks to stay on track.",
                ctaLabel: "View your tasks", route: .tasks)]
        } else {
            return [InsightCard(
                id: "timeline_ontrack", severity: .green, icon: "hare",
                title: "On pace",
                message: "Your target is \(daysLeft) days away and your current pace finishes the remaining tasks in ~\(projected) weeks. Nicely ahead.",
                ctaLabel: "View your tasks", route: .tasks)]
        }
    }

    private static func citaCards(_ s: UserMoveState) -> [InsightCard] {
        guard s.activeCitaMonitors > 0 else { return [] }
        let sample = s.citaSample.map { " — \($0)" } ?? ""
        return [InsightCard(
            id: "cita_active", severity: .green, icon: "calendar.badge.clock",
            title: "Cita reminders active",
            message: "You're tracking \(s.activeCitaMonitors) cita target\(s.activeCitaMonitors == 1 ? "" : "s")\(sample). Tap to open the portal and check now.",
            ctaLabel: "Manage cita monitor", route: .cita)]
    }

    private static func readyCards(_ s: UserMoveState) -> [InsightCard] {
        // Only celebrate documents when there's nothing urgent dragging them down.
        guard s.docComplete > 0, s.docExpired == 0, s.docExpiringSoon == 0, s.docMissing == 0 else { return [] }
        return [InsightCard(
            id: "docs_ready", severity: .green, icon: "checkmark.circle",
            title: "Documents in good shape",
            message: "\(s.docComplete) document\(s.docComplete == 1 ? "" : "s") complete and valid. No action needed right now.",
            ctaLabel: nil, route: nil)]
    }
}
