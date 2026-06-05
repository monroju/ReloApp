import XCTest
@testable import GoThere

/// Differentiation Wave — user-guided Cita Monitor. Covers the pure model: type
/// metadata, booking-URL resolution, and the UserDefaults-backed store CRUD.
final class CitaMonitorTests: XCTestCase {

    override func tearDown() {
        // Clean the shared store key so tests don't leak into each other / the app.
        UserDefaults.standard.removeObject(forKey: "gothere.cita.monitors")
        super.tearDown()
    }

    func test_usesProvince_falseOnlyForConsulate() {
        XCTAssertTrue(CitaAppointmentType.nieInitial.usesProvince)
        XCTAssertTrue(CitaAppointmentType.tie.usesProvince)
        XCTAssertFalse(CitaAppointmentType.consulate.usesProvince)
    }

    func test_bookingURL_extranjeria_isSedePortal() {
        let url = CitaAppointmentType.tie.bookingURL(area: "Madrid")
        XCTAssertEqual(url.host, "sede.administracionespublicas.gob.es")
    }

    func test_bookingURL_consulate_isCitaConsular() {
        let url = CitaAppointmentType.consulate.bookingURL(area: "New York")
        XCTAssertEqual(url.host, "www.citaconsular.es")
    }

    func test_bookingURL_empadronamiento_encodesAreaInSearch() {
        let url = CitaAppointmentType.empadronamiento.bookingURL(area: "Málaga")
        XCTAssertEqual(url.host, "www.google.com")
        // Area must be percent-encoded into the query.
        XCTAssertTrue(url.absoluteString.contains("empadronamiento"))
        XCTAssertFalse(url.absoluteString.contains(" "), "spaces must be encoded")
    }

    func test_monitor_codableRoundTrip() throws {
        let monitor = CitaMonitor(type: .nieRenewal, area: "Barcelona", remindersEnabled: false)
        let data = try JSONEncoder().encode(monitor)
        let decoded = try JSONDecoder().decode(CitaMonitor.self, from: data)
        XCTAssertEqual(decoded.type, .nieRenewal)
        XCTAssertEqual(decoded.area, "Barcelona")
        XCTAssertFalse(decoded.remindersEnabled)
        XCTAssertEqual(decoded.id, monitor.id)
    }

    func test_store_upsert_addsThenUpdatesInPlace() {
        var m = CitaMonitor(type: .nieInitial, area: "Madrid")
        var all = CitaMonitorStore.upsert(m)
        XCTAssertEqual(all.count, 1)

        m.area = "Valencia"
        all = CitaMonitorStore.upsert(m)
        XCTAssertEqual(all.count, 1, "same id should update, not duplicate")
        XCTAssertEqual(all.first?.area, "Valencia")
    }

    func test_store_remove() {
        let m = CitaMonitor(type: .tie, area: "Sevilla")
        _ = CitaMonitorStore.upsert(m)
        let after = CitaMonitorStore.remove(id: m.id)
        XCTAssertTrue(after.isEmpty)
        XCTAssertTrue(CitaMonitorStore.load().isEmpty)
    }

    func test_provinces_includesKeyExpatHubs() {
        for p in ["Madrid", "Barcelona", "Málaga", "Alicante", "Valencia"] {
            XCTAssertTrue(CitaProvinces.all.contains(p), "missing province \(p)")
        }
    }
}
