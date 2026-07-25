import Foundation

/// Curated directory of health-insurance + expat-banking providers for the
/// Money & Insurance view. Country-aware via each provider's `regions`.
///
/// AFFILIATE: `url` is the provider homepage today. To monetise, the operator
/// replaces each with the provider's affiliate/referral link (same URL + the
/// affiliate params). No code change needed — the view just opens `url`.
/// This is an informational directory, not an endorsement; the view carries a
/// "verify it meets your visa" disclaimer.
struct MoneyProvider: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    /// Short positioning tag, e.g. "Residency visas", "Nomads & short stays".
    let bestFor: String
    let url: String
    /// "*" = available everywhere; otherwise a DestinationCountry.region value
    /// ("Europe" / "North America" / "South America").
    let regions: Set<String>
}

enum MoneyInsuranceProviders {

    // MARK: - Health insurance

    static let insurance: [MoneyProvider] = [
        MoneyProvider(
            id: "cigna_global",
            name: "Cigna Global",
            blurb: "International health insurance widely accepted for residency-visa applications. Modular cover you can tailor to a visa's minimum requirements.",
            bestFor: "Residency visas · global",
            url: "https://www.cignaglobal.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "allianz_care",
            name: "Allianz Care",
            blurb: "International private medical insurance for expats and families, accepted for many long-stay visas.",
            bestFor: "Families · long-stay visas",
            url: "https://www.allianzcare.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "william_russell",
            name: "William Russell",
            blurb: "International health, life and income cover built for long-term expats.",
            bestFor: "Long-term expats",
            url: "https://www.william-russell.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "safetywing",
            name: "SafetyWing",
            blurb: "Nomad Insurance for travel and shorter stays. Check it meets your visa's in-country requirement before relying on it for residency.",
            bestFor: "Nomads · short stays",
            url: "https://safetywing.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "genki",
            name: "Genki",
            blurb: "Flexible long-term health cover popular with remote workers living in the EU.",
            bestFor: "Nomads · EU",
            url: "https://genki.world/",
            regions: ["Europe"]),
        MoneyProvider(
            id: "feather",
            name: "Feather",
            blurb: "English-speaking expat insurance in Germany and the EU: public and private health, liability and more.",
            bestFor: "Germany & EU",
            url: "https://feather-insurance.com/",
            regions: ["Europe"]),
    ]

    // MARK: - Banking

    static let banking: [MoneyProvider] = [
        MoneyProvider(
            id: "wise",
            name: "Wise",
            blurb: "Multi-currency account and low-cost transfers in 40+ currencies. The usual first account to open before you land.",
            bestFor: "Multi-currency · transfers",
            url: "https://wise.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "revolut",
            name: "Revolut",
            blurb: "App-based multi-currency account and cards for everyday spending abroad.",
            bestFor: "Everyday spending",
            url: "https://www.revolut.com/",
            regions: ["*"]),
        MoneyProvider(
            id: "n26",
            name: "N26",
            blurb: "EU digital bank with a real local IBAN — useful for rent, utilities and residency paperwork.",
            bestFor: "EU IBAN · residency",
            url: "https://n26.com/",
            regions: ["Europe"]),
        MoneyProvider(
            id: "bunq",
            name: "bunq",
            blurb: "European digital bank with multi-currency accounts and local IBANs.",
            bestFor: "EU IBAN",
            url: "https://www.bunq.com/",
            regions: ["Europe"]),
        MoneyProvider(
            id: "remitly",
            name: "Remitly",
            blurb: "Lower-cost international transfers for sending money home or funding your move.",
            bestFor: "Sending money home",
            url: "https://www.remitly.com/",
            regions: ["*"]),
    ]

    // MARK: - Filtering

    private static func applicable(_ list: [MoneyProvider], region: String?) -> [MoneyProvider] {
        list.filter { $0.regions.contains("*") || (region != nil && $0.regions.contains(region!)) }
    }

    static func insurance(forRegion region: String?) -> [MoneyProvider] {
        applicable(insurance, region: region)
    }

    static func banking(forRegion region: String?) -> [MoneyProvider] {
        applicable(banking, region: region)
    }
}
