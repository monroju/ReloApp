import Foundation

/// In-app "Policy Watch" — leans into the us_policy_alerts FCM channel by giving it a
/// home screen. Push delivers breaking changes; this view explains the standing US
/// policy factors every would-be emigrant should understand, each framed as
/// "what it means → who it's for → your fastest route." Evergreen + verifiable, not
/// fabricated breaking news. Refresh as US law changes.
struct PolicyWatchItem: Identifiable {
    let id: String
    let icon: String
    let headline: String
    /// Who this most affects.
    let whoAffected: String
    /// The pragmatic move / fastest route in response.
    let fastestRoute: String
}

enum PolicyWatchData {
    static let items: [PolicyWatchItem] = [
        PolicyWatchItem(id: "worldwide_tax", icon: "globe.americas",
            headline: "The US taxes citizens on worldwide income — forever",
            whoAffected: "Everyone who leaves while keeping US citizenship or a green card.",
            fastestRoute: "You almost never pay double thanks to the FEIE (~$126k) + Foreign Tax Credit — but you must keep filing. Pick a destination with a US tax treaty; lean on a preferential regime (Beckham, IFICI)."),
        PolicyWatchItem(id: "exit_tax", icon: "arrow.up.forward.square",
            headline: "Renouncing citizenship can trigger an exit tax",
            whoAffected: "High-net-worth individuals considering giving up US citizenship.",
            fastestRoute: "Secure a second nationality FIRST (citizenship by descent if you qualify — far cheaper than CBI), then take expatriation advice. Never renounce without a tax attorney."),
        PolicyWatchItem(id: "passport_backlog", icon: "book.closed",
            headline: "Passport demand keeps processing times volatile",
            whoAffected: "Anyone whose passport expires within ~18 months of moving.",
            fastestRoute: "Renew every family member's passport now — it's the cheapest, highest-leverage first step. Build it into your move timeline."),
        PolicyWatchItem(id: "totalization", icon: "shield.lefthalf.filled",
            headline: "Social Security totalization protects your benefits abroad",
            whoAffected: "Retirees and workers who've paid into US Social Security.",
            fastestRoute: "Most GoThere destinations have a totalization agreement so you don't pay into two systems and don't lose credits. Mexico and Argentina are the gaps — verify before relying on it."),
        PolicyWatchItem(id: "rights_shifts", icon: "person.2.badge.gearshape",
            headline: "State-level rights changes are driving relocation",
            whoAffected: "LGBTQ+ families, those needing reproductive care, and others affected by shifting state law.",
            fastestRoute: "Use the rights & safety filter to weight destinations on the protections that matter to you — several GoThere countries lead the US on these."),
    ]

    static let footer = "Policy Watch is educational, not legal or tax advice. Enable alerts to get notified when a US policy change materially affects moving abroad."
}
