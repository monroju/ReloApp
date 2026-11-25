import XCTest

/// Google Play rejected the Android twin on 2026-11-25 for a broken government source link
/// (Misleading Claims). These URLs were dead on that date (404/410, gone domain, or TLS failure
/// for US and automated clients) and must not come back in the iOS app or the site API.
/// Twin of OfficialSourcesTest in monroju/GoThere. Rerun `scripts/check_gov_links.py --src GoThere`
/// from that repo before each release to catch new ones.
final class OfficialLinksTests: XCTestCase {

    private let deadUrls = [
        "//vistos.mne.gov.pt", "//www.vistos.mne.gov.pt",
        "//aima.gov.pt", "//www.aima.gov.pt",
        "//novaiorque.consuladoportugal.mne.gov.pt", "//www.novaiorque.consuladoportugal.mne.gov.pt",
        "//dgert.gov.pt", "//www.dgert.gov.pt",
        "//oif.gov.hu", "//www.oif.gov.hu",
        "//enterhungary.gov.hu", "//www.enterhungary.gov.hu",
        "Restoration-of-citizenship/restoration-of-citizenship_node.html",
        "employment-social-affairs.ec.europa.eu/policies-and-activities/social-protection-social-inclusion/persons-disabilities/european-disability-card_en",
        "vistoperitalia.esteri.it/home/dettagliovisto",
        "agenziaentrate.gov.it/portale/codice-fiscale-tessera-sanitaria",
        "argentina.gob.ar/interior/renaper/dni",
        "cancilleria.gob.ar/en/foreign-policy/embassies-and-consulates",
        "cancilleria.gob.ar/en/services/argentinians-abroad",
        "esteri.it/en/ministero/laministero/lerappresentanze",
        "esteri.it/en/servizi-consolari-e-visti/italiani-all-estero/aire",
        "esteri.it/en/servizi-consolari-e-visti/visti-per-litalia",
        "\"https://www.exteriores.gob.es/Consulados/\"",
        "/InformacionParaExtranjeros/Paginas/Estudios.aspx",
        "/InformacionParaExtranjeros/Paginas/Visados.aspx",
        "germany.info/us-en/service/passport",
        "gov.ie/en/service/civil-registration-service",
        "irishimmigration.ie/coming-to-join-family-in-ireland/stamp-0",
        "nidirect.gov.uk/articles/general-register-office",
        "www2.hse.ie/services/maternity-services",
        "buenosaires.gob.ar/registrocivil",
        "berlin.de/en/visa/visa-categories/freelance-self-employment",
        "//cbi.gov.gd", "//www.cbi.gov.gd",
        "//nemzetikartya.gov.hu", "//www.nemzetikartya.gov.hu",
        "//nyilvantarto.hu", "//www.nyilvantarto.hu",
        "//www.sanidad.gob.es", "//sanidad.gob.es",
        "//chlc.min-saude.pt", "//www.chlc.min-saude.pt",
        "//hjmatos.min-saude.pt", "//www.hjmatos.min-saude.pt",
        "//hff.min-saude.pt", "//www.hff.min-saude.pt",
        "//chualgarve.min-saude.pt", "//www.chualgarve.min-saude.pt",
        "//chbv.min-saude.pt", "//www.chbv.min-saude.pt",
        "//bicsp.min-saude.pt", "//www.bicsp.min-saude.pt",
        "inclusion.gob.es/web/migraciones/w/empleo-y-trabajo",
        "inclusion.gob.es/web/migraciones/w/extranjeria",
        "inclusion.gob.es/web/migraciones/w/reagrupacion-familiar",
        "permisos-de-conducir/canje-de-permisos/",
        "benefits.va.gov/persona/veteran-livingabroad.asp",
    ]

    /// Claims that were true once and are wrong now.
    private let staleClaims = [
        // EU Disability Card: Directive 2024/2841, cards issued from 5 June 2028.
        "EU Disability Card recognised",
        "Mutual recognition across EU member states",
        // Portugal nationality law (Lei Organica 1/2026): 10 years, 7 for EU/CPLP, from 19 May 2026.
        "Citizenship after 5 years applies to the whole family",
    ]

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func scan(_ folder: String, for needles: [String]) throws -> [String] {
        let base = repoRoot.appendingPathComponent(folder)
        let exts: Set<String> = ["swift", "json", "xcstrings", "strings", "plist"]
        guard let walker = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else {
            XCTFail("cannot read \(base.path)")
            return []
        }
        var hits: [String] = []
        for case let file as URL in walker where exts.contains(file.pathExtension) {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            for needle in needles where text.contains(needle) {
                hits.append("\(file.lastPathComponent): \(needle)")
            }
        }
        return hits
    }

    func testAppHasNoDeadGovernmentLinks() throws {
        let hits = try scan("GoThere", for: deadUrls)
        XCTAssertTrue(hits.isEmpty, "dead government links still in the app: \(hits)")
    }

    func testSiteApiHasNoDeadGovernmentLinks() throws {
        let hits = try scan("marketing/landing-page/api", for: deadUrls)
        XCTAssertTrue(hits.isEmpty, "dead government links in the site API: \(hits)")
    }

    func testAppHasNoStaleClaims() throws {
        let hits = try scan("GoThere", for: staleClaims)
        XCTAssertTrue(hits.isEmpty, "outdated claims still in the app: \(hits)")
    }
}
