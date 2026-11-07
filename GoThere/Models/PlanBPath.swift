import Foundation

/// One generation in a descent line. Raw values match `planb_path.schema.json`.
enum PlanBRole: String, Codable, CaseIterable, Identifiable {
    case me = "self"
    case parent
    case grandparent
    case ggp

    var id: String { rawValue }
    var depth: Int {
        switch self {
        case .me: return 0
        case .parent: return 1
        case .grandparent: return 2
        case .ggp: return 3
        }
    }

    var displayName: String {
        switch self {
        case .me: return String(localized: "You")
        case .parent: return String(localized: "Parent")
        case .grandparent: return String(localized: "Grandparent")
        case .ggp: return String(localized: "Great-grandparent")
        }
    }
}

/// Paper trail state for one document. Order matters: it is the order shown in the picker.
enum PlanBDocState: String, Codable, CaseIterable, Identifiable {
    case notStarted = "not_started"
    case ordered, received, apostilled, translated, done

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .notStarted: return String(localized: "Not started")
        case .ordered: return String(localized: "Ordered")
        case .received: return String(localized: "Received")
        case .apostilled: return String(localized: "Apostilled")
        case .translated: return String(localized: "Translated")
        case .done: return String(localized: "Done")
        }
    }
}

enum PlanBStage: String, Codable, CaseIterable, Identifiable {
    case gather, apply, wait, decision, passport
    var id: String { rawValue }
}

/// A path the user tracks in the Plan B tab. Same JSON shape as Android and as
/// `shared/data/schema/planb_path.schema.json`. Stored on device only.
struct PlanBPath: Codable, Identifiable, Equatable {
    struct Person: Codable, Equatable {
        var role: PlanBRole
        var name: String?
        var born: String?
    }

    struct Item: Codable, Identifiable, Equatable {
        var id: String
        /// A lineage role raw value, or "ancestor" for the citizen at the top of the line.
        var personRole: String
        var kind: String
        var state: PlanBDocState
        var orderedOn: String?
        var expectedDays: Int?
        var documentId: String?
        var skipped: Bool?
    }

    struct Visa: Codable, Equatable {
        var incomeFit: Double?
        var savingsGoalSet: Bool?
    }

    var id: String
    var type: String            // "descent" | "visa"
    var countryCode: String
    var pathwayId: String
    var createdAt: String
    var planMode: String        // "planB" | "move"
    var lineage: [Person]
    var items: [Item]
    var stage: PlanBStage
    var filedOn: String?
    var appointmentOn: String?
    var alertsOn: Bool?
    var visa: Visa?

    var alertsEnabled: Bool { alertsOn ?? true }
    var activeItems: [Item] { items.filter { $0.skipped != true } }
    var doneCount: Int { activeItems.filter { $0.state == .done }.count }
}

/// Readiness score (growth item F15). Port of `shared/data/planb_score.py`;
/// `PlanBScoreTests` checks it against the shared vectors so platforms agree.
enum PlanBScore {
    static func path(_ p: PlanBPath) -> Int {
        let active = p.activeItems
        let ratio = active.isEmpty ? 0.0 : Double(p.doneCount) / Double(active.count)
        let raw: Double
        if p.type == "visa" {
            let fit = min(1.0, max(0.0, p.visa?.incomeFit ?? 0))
            raw = 30 * fit + 50 * ratio + ((p.visa?.savingsGoalSet ?? false) ? 20 : 0)
        } else {
            raw = 70 * ratio + (p.filedOn != nil ? 20 : 0) + (p.appointmentOn != nil ? 10 : 0)
        }
        return max(0, min(100, Int((raw + 0.5).rounded(.down))))
    }

    static func overall(_ paths: [PlanBPath]) -> Int {
        paths.map(path).max() ?? 0
    }

    /// Analytics bucket for `planb_score_viewed`; the raw score is never sent.
    static func bucket(_ score: Int) -> String {
        switch score {
        case ...0: return "0"
        case 1..<25: return "1-24"
        case 25..<50: return "25-49"
        case 50..<75: return "50-74"
        case 75..<100: return "75-99"
        default: return "100"
        }
    }
}

enum PlanBDate {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(_ date: Date) -> String { formatter.string(from: date) }
    static func date(_ string: String?) -> Date? { string.flatMap { formatter.date(from: $0) } }
}

/// Builds the document checklist for a newly tracked descent path.
enum PlanBChainBuilder {
    /// Lineage from you up to the ancestor's generation.
    static func lineage(upTo ancestor: PlanBRole) -> [PlanBPath.Person] {
        PlanBRole.allCases.filter { $0.depth <= ancestor.depth }.map { PlanBPath.Person(role: $0) }
    }

    /// One item per document per person it applies to. "ancestor" documents attach to
    /// the top of the line. Roles above the chosen ancestor are dropped.
    static func items(for chain: DescentChain, ancestor: PlanBRole) -> [PlanBPath.Item] {
        var out: [PlanBPath.Item] = []
        var seen = Set<String>()
        for doc in chain.documents {
            for role in doc.appliesTo {
                if role != "ancestor" {
                    guard let r = PlanBRole(rawValue: role), r.depth <= ancestor.depth else { continue }
                }
                let id = "\(doc.kind)|\(role)|\(doc.condition ?? "")"
                guard seen.insert(id).inserted else { continue }
                out.append(PlanBPath.Item(id: id, personRole: role, kind: doc.kind, state: .notStarted))
            }
        }
        return out
    }

    /// The chain document behind an item (matched on kind, role and condition).
    static func document(for item: PlanBPath.Item, in chain: DescentChain) -> DescentChain.Document? {
        let parts = item.id.split(separator: "|", omittingEmptySubsequences: false)
        let condition = parts.count > 2 ? String(parts[2]) : ""
        return chain.documents.first {
            $0.kind == item.kind && $0.appliesTo.contains(item.personRole) && ($0.condition ?? "") == condition
        }
    }
}
