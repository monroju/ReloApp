import XCTest
@testable import GoThere

/// Wave 2 — Autónomo deepening. Locks in the TaxRegime contract used by the
/// Wizard summary "tax regime hint" card and by VisaCompare. Beckham + IFICI
/// drive operator-credible content; regressions here remove the most-asked-about
/// piece of self-employed Spain/Portugal context.
final class TaxRegimeTests: XCTestCase {

    // MARK: - Codable roundtrip

    func test_taxRegime_decodeEncodeRoundtrip() throws {
        let original = TaxRegime(
            name: "Beckham Law",
            flatRatePercent: 0.24,
            eligibilityCriteria: [
                "Not Spanish tax resident in the prior 5 years",
                "Move triggered by an employment contract or DNV-eligible remote work"
            ],
            applicationWindow: "Modelo 149 within 6 months of becoming Spanish tax resident"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaxRegime.self, from: encoded)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.flatRatePercent, original.flatRatePercent)
        XCTAssertEqual(decoded.eligibilityCriteria, original.eligibilityCriteria)
        XCTAssertEqual(decoded.applicationWindow, original.applicationWindow)
    }

    func test_taxRegime_nilFlatRateRoundtrips() throws {
        let original = TaxRegime(
            name: "Tarifa Plana (new autónomo)",
            flatRatePercent: nil,
            eligibilityCriteria: ["First-time autónomo registration with the RETA"],
            applicationWindow: nil
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaxRegime.self, from: encoded)

        XCTAssertNil(decoded.flatRatePercent)
        XCTAssertNil(decoded.applicationWindow)
        XCTAssertEqual(decoded.eligibilityCriteria.count, 1)
    }

    // MARK: - Wired tax regimes on Spain / Portugal visas

    func test_spainDNV_carriesBeckhamLaw() {
        let dnv = VisaCatalog.byId("es_dnv")
        XCTAssertNotNil(dnv)
        XCTAssertTrue(
            dnv?.taxRegimes.contains(where: { $0.name == "Beckham Law" }) ?? false,
            "Spain DNV must surface the Beckham Law regime — the highest-signal tax fact for the audience"
        )
    }

    func test_spainAutonomo_carriesBeckhamAndTarifaPlana() {
        let autonomo = VisaCatalog.byId("es_autonomo")
        XCTAssertNotNil(autonomo)
        let regimeNames = autonomo?.taxRegimes.map(\.name) ?? []
        XCTAssertTrue(regimeNames.contains("Beckham Law (entrepreneur route)"))
        XCTAssertTrue(regimeNames.contains("Tarifa Plana (new autónomo)"))
    }

    func test_portugalD2_carriesIFICI() {
        let d2 = VisaCatalog.byId("pt_d2")
        XCTAssertNotNil(d2)
        let regime = d2?.taxRegimes.first { $0.name.contains("IFICI") }
        XCTAssertNotNil(regime, "Portugal D2 must surface IFICI (NHR successor) — NHR ended Mar 2024 and operator briefing flags this as the #1 obsolete-info trap")
        XCTAssertEqual(regime?.flatRatePercent, 0.20)
    }

    // MARK: - Wizard milestones on the es_autonomo track

    func test_esAutonomo_carriesAtLeastSixMilestones() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let track = config.tracks["es_autonomo"]
        XCTAssertNotNil(track)
        let milestones = track?.taskRules.flatMap { $0.milestones ?? [] } ?? []
        XCTAssertGreaterThanOrEqual(milestones.count, 6, "Wave 2 brief: 6-8 autónomo milestones")
        XCTAssertLessThanOrEqual(milestones.count, 12)
    }

    func test_esAutonomo_milestoneKeysAreUnique() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let milestones = config.tracks["es_autonomo"]?
            .taskRules.flatMap { $0.milestones ?? [] } ?? []
        let keys = milestones.map(\.key)
        XCTAssertEqual(Set(keys).count, keys.count, "Milestone keys must be unique within a track for idempotent calendar fan-out")
    }

    func test_esAutonomo_includesAltaAndTrimestralKeys() throws {
        guard let config = WizardRepository.shared.loadConfig() else {
            throw XCTSkip("Bundled wizard_config.json not visible to test target")
        }
        let keys = Set(
            config.tracks["es_autonomo"]?
                .taskRules.flatMap { $0.milestones ?? [] }
                .map(\.key) ?? []
        )
        XCTAssertTrue(keys.contains("autonomo_alta_deadline"))
        XCTAssertTrue(keys.contains("autonomo_reta_alta"))
        XCTAssertTrue(keys.contains("autonomo_q1_filings"))
        XCTAssertTrue(keys.contains("autonomo_renta_deadline"))
    }

    // MARK: - Real Journey

    func test_spainAutonomo_realJourneyExists() {
        let journey = RealJourneys.forVisa("es_autonomo")
        XCTAssertNotNil(journey, "Wave 2 ships an autónomo-specific Real Journey")
        XCTAssertEqual(journey?.countryId, "spain")
        XCTAssertGreaterThanOrEqual(journey?.phases.count ?? 0, 4, "Journey must walk Hacienda alta, TGSS alta, first trimestral, and year-end")
    }
}
