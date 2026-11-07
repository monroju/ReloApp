import Foundation

/// Per-country document chain for the Plan B descent tracker. Decoded from
/// `descent_chains.json`, built in the parent repo by `shared/data/descent_chains.py`
/// from sourced research. Every fact carries its source; a nil value means
/// "Not yet verified" and must render that way, never as a guess.
struct DescentChainBundle: Decodable {
    let version: Int
    let generatedAt: String
    let disclaimer: String
    let disclaimerEs: String
    let usOrderHints: [DescentOrderHint]
    let chains: [String: DescentChain]
}

struct DescentChain: Decodable {
    let pathwayId: String
    let ancestryPathId: String
    let countryCode: String
    let lastVerified: String?
    let sources: [Source]
    let lineage: Lineage
    let documents: [Document]
    let orderHints: [DescentOrderHint]?
    let stages: [Stage]

    struct Source: Decodable, Hashable {
        let title: String
        let url: String
        let type: String
    }

    struct Lineage: Decodable {
        let maxRole: PlanBRole
        let note: String?
        let noteEs: String?
        let sourceUrl: String?
        let lastVerified: String?
    }

    struct Document: Decodable {
        let kind: String
        let label: String
        let labelEs: String
        let appliesTo: [String]
        let condition: String?
        let conditionEs: String?
        let needsApostille: Bool?
        let needsTranslation: Bool?
        let orderHintIds: [String]
        let sourceUrl: String?
        let lastVerified: String?
        let note: String?
    }

    struct Stage: Decodable, Identifiable {
        let id: String
        let label: String
        let labelEs: String
        let typicalMonths: Months?
        let sourceUrl: String?
        let lastVerified: String?
        let note: String?

        struct Months: Decodable {
            let low: Double
            let high: Double
        }
    }

    /// Roles the user can pick as "where the citizen ancestor sits", from parent up to `maxRole`.
    var ancestorChoices: [PlanBRole] {
        PlanBRole.allCases.filter { $0 != .me && $0.depth <= lineage.maxRole.depth }
    }
}

struct DescentOrderHint: Decodable, Identifiable {
    let id: String
    let label: String
    let labelEs: String
    let howTo: String?
    let howToEs: String?
    let url: String?
    let fee: String?
    let sourceUrl: String?
    let lastVerified: String?
    let note: String?
}

/// Picks the Spanish copy of a data string when the app runs in Spanish.
/// Data files carry both languages; UI chrome uses the String Catalog instead.
enum DataLanguage {
    static var isSpanish: Bool {
        (Bundle.main.preferredLocalizations.first ?? "en").hasPrefix("es")
    }

    static func pick(_ en: String, _ es: String?) -> String {
        guard isSpanish, let es, !es.isEmpty else { return en }
        return es
    }
}

final class DescentChainRepository {
    static let shared = DescentChainRepository()
    let bundle: DescentChainBundle?

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "descent_chains", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            self.bundle = nil
            return
        }
        self.bundle = try? JSONDecoder().decode(DescentChainBundle.self, from: data)
    }

    var disclaimer: String {
        guard let bundle else { return "" }
        return DataLanguage.pick(bundle.disclaimer, bundle.disclaimerEs)
    }

    func chain(pathwayId: String) -> DescentChain? { bundle?.chains[pathwayId] }

    /// The chain for a checker result (`AncestryPath.id`), if one has been researched.
    func chain(forAncestryPathId id: String) -> DescentChain? {
        bundle?.chains.values.first { $0.ancestryPathId == id }
    }

    /// Country hints first, then the shared US hints.
    func hints(for chain: DescentChain, ids: [String]) -> [DescentOrderHint] {
        let all = (chain.orderHints ?? []) + (bundle?.usOrderHints ?? [])
        return ids.compactMap { id in all.first { $0.id == id } }
    }
}
