import Foundation

/// Canonical TaxRegime entries referenced from VisaCatalog. Kept here (not inline in
/// VisaCatalog) so the same regime can be attached to multiple visas without
/// drifting between copies.
///
/// Wave 2 — Autónomo deepening. Refresh annually with the rest of VisaCatalog when
/// Spain's RETA cuota or Portugal's IFICI activity list changes.
extension TaxRegime {

    // MARK: - Spain

    /// Régimen Especial para Trabajadores Desplazados — flat 24% rate on Spanish-
    /// sourced income up to €600k for the first six tax years. The 2023 reform
    /// (Ley de Startups) opened the door to certain remote workers and innovative
    /// entrepreneurs in addition to the original employee-transfer audience.
    static let beckhamLaw = TaxRegime(
        name: "Beckham Law",
        flatRatePercent: 0.24,
        eligibilityCriteria: [
            "Not Spanish tax resident in the prior 5 years",
            "Move triggered by an employment contract or by DNV-eligible remote work",
            "Most professional activity must be carried out in Spain"
        ],
        applicationWindow: "Modelo 149 must be filed within 6 months of becoming Spanish tax resident"
    )

    /// Autónomo-specific Beckham application. The 2023 reform expanded the regime
    /// to entrepreneurs developing innovative business activity (DGT/ENISA assessed)
    /// and to highly qualified professionals supplying Spanish startups. Generic
    /// trade or hospitality activities still don't qualify.
    static let beckhamLawAutonomo = TaxRegime(
        name: "Beckham Law (entrepreneur route)",
        flatRatePercent: 0.24,
        eligibilityCriteria: [
            "Business activity certified innovative by ENISA or the DGT",
            "Not Spanish tax resident in the prior 5 years",
            "Activity carried out mainly in Spain"
        ],
        applicationWindow: "Modelo 149 within 6 months of becoming Spanish tax resident"
    )

    /// Tarifa Plana — the autónomo cuota incentive. New autónomos pay a flat €80/mo
    /// social-security contribution for the first 12 months, extendable by another
    /// 12 if net yearly income stays under the minimum interprofessional wage.
    static let tarifaPlanaAutonomo = TaxRegime(
        name: "Tarifa Plana (new autónomo)",
        flatRatePercent: nil,
        eligibilityCriteria: [
            "First-time autónomo registration with the RETA",
            "No autónomo registration in the prior 2 years (3 years if previously claimed the benefit)",
            "No outstanding social-security or tax debts"
        ],
        applicationWindow: "Elect at the time of alta with the Tesorería General de la Seguridad Social"
    )

    // MARK: - Portugal

    /// IFICI — the post-NHR successor regime created by Lei 82/2023. Flat 20% IRS
    /// on qualifying employment / self-employment income and an exemption on most
    /// foreign-source income, narrower in scope than NHR (research, innovation,
    /// and certified high-value-added activities only).
    static let ifici = TaxRegime(
        name: "IFICI (NHR successor)",
        flatRatePercent: 0.20,
        eligibilityCriteria: [
            "New Portuguese tax resident (not resident in the prior 5 years)",
            "Activity in research, higher education, innovation, certified startups, or other listed high-value-added sectors",
            "Registration with the eligible-activity authority (e.g. ANI, IAPMEI, AICEP)"
        ],
        applicationWindow: "Register with AT by 15 January of the year following Portuguese tax residency"
    )
}
