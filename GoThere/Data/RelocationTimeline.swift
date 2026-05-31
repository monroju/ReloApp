import Foundation

/// "Gone in N months" timeline generator. Middle-class planner core: turns a target
/// departure date into a personalized month-by-month checklist. Generic across
/// destinations; pairs with the per-country visa wizard for specifics.
enum RelocationTimeline {

    /// A milestone with its ideal lead time, expressed as *months before departure*.
    /// `monthsBefore` is the recommended START point counting back from move month.
    struct Milestone: Identifiable {
        let id: String
        let title: String
        let detail: String
        let monthsBefore: Int       // e.g. 9 = ~9 months before departure
        let familyOnly: Bool        // surfaced only when the user has children
    }

    /// Master milestone set, longest-lead-first. Tuned for a comfortable ~12-month move;
    /// the generator compresses these into shorter timelines proportionally.
    static let milestones: [Milestone] = [
        Milestone(id: "decide_visa", title: "Choose your visa pathway",
            detail: "Use the Visa Compare + Wizard to lock in the track you qualify for. Everything else hangs off this.",
            monthsBefore: 12, familyOnly: false),
        Milestone(id: "budget", title: "Set your move budget & start saving",
            detail: "Run the Cost-to-Move calculator. Build the landing fund + a 3-month runway.",
            monthsBefore: 12, familyOnly: false),
        Milestone(id: "passport", title: "Renew passports (6+ months validity)",
            detail: "Every family member needs a passport valid well beyond your intended stay.",
            monthsBefore: 10, familyOnly: false),
        Milestone(id: "documents", title: "Gather & apostille core documents",
            detail: "Birth/marriage certificates, FBI background check, diplomas — apostilled and translated as the visa requires.",
            monthsBefore: 9, familyOnly: false),
        Milestone(id: "kids_docs", title: "Gather children's documents",
            detail: "Apostille kids' birth certificates, vaccination + school records. Single parents: notarized consent from the other parent.",
            monthsBefore: 9, familyOnly: true),
        Milestone(id: "employer", title: "Sort your income / employer authorization",
            detail: "Remote workers: get the employer remote-work letter (see Bring Your Job). Freelancers: assemble client contracts + invoices.",
            monthsBefore: 7, familyOnly: false),
        Milestone(id: "visa_apply", title: "Submit your visa application",
            detail: "Book the consulate appointment and file. This is the long pole — start the moment documents are ready.",
            monthsBefore: 6, familyOnly: false),
        Milestone(id: "schools", title: "Research & contact schools",
            detail: "Shortlist public vs international schools, check enrollment windows, and email admissions. (See Moving with Kids.)",
            monthsBefore: 5, familyOnly: true),
        Milestone(id: "housing", title: "Research housing & neighborhoods",
            detail: "Identify target areas; line up short-term housing for your first 1–2 months on the ground.",
            monthsBefore: 4, familyOnly: false),
        Milestone(id: "healthcare", title: "Arrange health insurance",
            detail: "Secure the private policy your visa requires + bridge cover for the residency-registration gap.",
            monthsBefore: 3, familyOnly: false),
        Milestone(id: "downsize", title: "Sell, store, or ship belongings",
            detail: "Decide what comes with you. Get shipping quotes early; sell big items while you have time.",
            monthsBefore: 3, familyOnly: false),
        Milestone(id: "flights", title: "Book one-way flights",
            detail: "Lock in dates once your visa is approved (or appointment confirmed).",
            monthsBefore: 2, familyOnly: false),
        Milestone(id: "wind_down", title: "Wind down US life",
            detail: "Mail forwarding, cancel/transfer subscriptions & utilities, notify the IRS of your new address, set up a US mailing solution.",
            monthsBefore: 1, familyOnly: false),
        Milestone(id: "pack", title: "Final packing & document folder",
            detail: "Carry originals of all apostilled docs, visa approval, and proof of funds in your hand luggage.",
            monthsBefore: 1, familyOnly: false),
        Milestone(id: "arrival", title: "Arrival: register as a resident",
            detail: "Empadronamiento / address registration, local tax ID, residency card appointment, open a bank account, register for healthcare.",
            monthsBefore: 0, familyOnly: false),
    ]

    /// A generated bucket: the milestones the user should be working on in a given month.
    struct MonthBucket: Identifiable {
        let id: Int                 // 0 = move month, increasing = earlier
        let label: String           // e.g. "Now (start here)" / "Month 5" / "Move month"
        let milestones: [Milestone]
    }

    /// Generate the month-by-month plan for a target timeline.
    /// - Parameters:
    ///   - totalMonths: how many months until departure (1...18).
    ///   - hasKids: include family-only milestones.
    /// Milestones whose ideal lead time exceeds the user's runway are pulled into the
    /// first ("start now") bucket so nothing is dropped on compressed timelines.
    static func generate(totalMonths: Int, hasKids: Bool) -> [MonthBucket] {
        let n = max(1, min(18, totalMonths))
        let relevant = milestones.filter { !$0.familyOnly || hasKids }

        // Bucket index counts down from departure: 0 = move month, n = "now".
        var byIndex: [Int: [Milestone]] = [:]
        for m in relevant {
            // Clamp lead time into our runway; anything longer-lead lands in the "now" bucket.
            let idx = min(m.monthsBefore, n)
            byIndex[idx, default: []].append(m)
        }

        return byIndex.keys.sorted(by: >).map { idx in
            let label: String
            if idx == n {
                label = "Now — start here"
            } else if idx == 0 {
                label = "Move month 🎉"
            } else {
                label = "~\(idx) month\(idx == 1 ? "" : "s") before"
            }
            return MonthBucket(id: idx, label: label, milestones: byIndex[idx] ?? [])
        }
    }
}
