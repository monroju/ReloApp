import Foundation

/// Healthcare cost comparison — a top middle-class pain point. Anchors each destination
/// against the US so the savings are concrete. Figures are typical private-insurance
/// premiums in USD for 2025-2026; public-system access is described separately.
/// Informational only — actual premiums vary by age, health, and coverage.
struct HealthcareProfile {
    let countryId: String
    let flag: String
    let name: String
    /// Public/national system name + how a US expat accesses it.
    let publicSystem: String
    /// Typical private health-insurance premium, single adult, per month (USD).
    let privateMonthlySingleUSD: Int
    /// Typical private premium for a family of four, per month (USD).
    let privateMonthlyFamilyUSD: Int
    /// One-line nuance (waiting periods, visa requirements, quality).
    let note: String
}

enum HealthcareCostData {
    /// US reference points so the comparison is honest and concrete.
    /// 2024 KFF: avg employer family premium ~$25,500/yr total (~$2,125/mo);
    /// worker share ~$6,300/yr (~$525/mo). ACA marketplace silver single ~$500/mo pre-subsidy.
    static let usFamilyMonthlyTotalUSD = 2125
    static let usFamilyWorkerShareMonthlyUSD = 525
    static let usSingleMarketplaceMonthlyUSD = 500

    static let profiles: [HealthcareProfile] = [
        HealthcareProfile(countryId: "spain", flag: "🇪🇸", name: "Spain",
            publicSystem: "SNS public health — free/low-cost once you're a registered resident paying social security (or via the convenio especial pay-in for non-workers).",
            privateMonthlySingleUSD: 90, privateMonthlyFamilyUSD: 280,
            note: "Visa applicants must hold private insurance with no copays (e.g. Sanitas, Adeslas). Excellent quality, short waits."),
        HealthcareProfile(countryId: "portugal", flag: "🇵🇹", name: "Portugal",
            publicSystem: "SNS public health — open to registered residents at near-zero cost.",
            privateMonthlySingleUSD: 60, privateMonthlyFamilyUSD: 220,
            note: "Private insurance (Médis, Multicare) is cheap and widely used to skip public waits."),
        HealthcareProfile(countryId: "mexico", flag: "🇲🇽", name: "Mexico",
            publicSystem: "IMSS public health — voluntary enrollment open to residents for a low annual fee (~$400/yr).",
            privateMonthlySingleUSD: 70, privateMonthlyFamilyUSD: 250,
            note: "Private care is high-quality and inexpensive; many expats pay cash for routine visits (~$30–50)."),
        HealthcareProfile(countryId: "canada", flag: "🇨🇦", name: "Canada",
            publicSystem: "Provincial medicare — free for residents after a waiting period (up to ~3 months in some provinces).",
            privateMonthlySingleUSD: 70, privateMonthlyFamilyUSD: 200,
            note: "Public covers core care; private 'extended' plans cover dental/vision/drugs. Insure the initial waiting period."),
        HealthcareProfile(countryId: "ireland", flag: "🇮🇪", name: "Ireland",
            publicSystem: "Public health for residents; under-8s get free GP care. Public waits can be long.",
            privateMonthlySingleUSD: 130, privateMonthlyFamilyUSD: 420,
            note: "Private insurance (Vhi, Laya) is common to bypass waits. Still well below US cost."),
        HealthcareProfile(countryId: "italy", flag: "🇮🇹", name: "Italy",
            publicSystem: "SSN public health — register for a low annual contribution; excellent in the north.",
            privateMonthlySingleUSD: 80, privateMonthlyFamilyUSD: 260,
            note: "Elective Residency visa requires private cover; SSN enrollment available once resident."),
        HealthcareProfile(countryId: "germany", flag: "🇩🇪", name: "Germany",
            publicSystem: "Statutory health insurance (GKV) — mandatory, ~14.6% of income; children covered free under a parent.",
            privateMonthlySingleUSD: 250, privateMonthlyFamilyUSD: 250,
            note: "GKV family coverage adds spouse/kids at no extra premium — a huge saving vs US family plans. Private (PKV) is an option for high earners."),
        HealthcareProfile(countryId: "poland", flag: "🇵🇱", name: "Poland",
            publicSystem: "NFZ public health for insured residents.",
            privateMonthlySingleUSD: 40, privateMonthlyFamilyUSD: 130,
            note: "Private packages (Medicover, LUX MED) are very cheap and skip public queues."),
        HealthcareProfile(countryId: "argentina", flag: "🇦🇷", name: "Argentina",
            publicSystem: "Universal public healthcare — free to everyone, including residents-in-process.",
            privateMonthlySingleUSD: 60, privateMonthlyFamilyUSD: 180,
            note: "Private prepagas (OSDE, Swiss Medical) are affordable; peso means USD income stretches far."),
        HealthcareProfile(countryId: "hungary", flag: "🇭🇺", name: "Hungary",
            publicSystem: "Public health (TAJ) for insured residents.",
            privateMonthlySingleUSD: 50, privateMonthlyFamilyUSD: 160,
            note: "Private clinics in Budapest are inexpensive and English-friendly."),
        HealthcareProfile(countryId: "uk_ancestry", flag: "🇬🇧", name: "UK (Ancestry)",
            publicSystem: "NHS — covers residents. Visa holders pre-pay the Immigration Health Surcharge (~$1,000/person/yr).",
            privateMonthlySingleUSD: 90, privateMonthlyFamilyUSD: 300,
            note: "The IHS is the real cost — paid up front for the full visa term. After that, NHS care is free at point of use."),
    ]

    static func profile(for countryId: String) -> HealthcareProfile? {
        profiles.first { $0.countryId == countryId }
    }
}
