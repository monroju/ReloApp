import Foundation

/// Spanish government appointment ("cita previa") types relevant to relocating
/// users. Each maps to the official booking portal that handles it. Empadronamiento
/// is municipal and consulate appointments are abroad, so those resolve to a
/// search/booking entry point scoped by the user's province/area.
enum CitaAppointmentType: String, Codable, CaseIterable, Identifiable {
    case nieInitial          // NIE — initial assignment
    case nieRenewal          // NIE / certificate renewal
    case tie                 // TIE card (fingerprinting / issuance)
    case residencyCertificate // EU citizen registration certificate
    case empadronamiento     // town-hall registration (padrón)
    case consulate           // pre-departure consulate appointment (visa)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nieInitial:          return "NIE — Initial"
        case .nieRenewal:          return "NIE / Cert Renewal"
        case .tie:                 return "TIE Card"
        case .residencyCertificate: return "Residency Certificate"
        case .empadronamiento:     return "Empadronamiento (Padrón)"
        case .consulate:           return "Consulate (pre-departure)"
        }
    }

    /// Whether a Spanish province is meaningful for this type. Consulate
    /// appointments are abroad, so they use a country/area free-text instead.
    var usesProvince: Bool { self != .consulate }

    /// One-line instruction shown under the type, since the official portals
    /// can't be deep-linked with the selection pre-filled (form POST, not query
    /// params). We open the correct portal; the user picks the rest.
    var instruction: String {
        switch self {
        case .nieInitial, .nieRenewal, .tie, .residencyCertificate:
            return "Opens the Extranjería booking portal. Choose your province, then this procedure."
        case .empadronamiento:
            return "Empadronamiento is booked at your town hall. Opens a search for your area's padrón booking."
        case .consulate:
            return "Opens the Spanish consular appointment system. Pick your consulate abroad."
        }
    }

    /// Official portal to open for this appointment type, scoped where possible.
    func bookingURL(area: String) -> URL {
        switch self {
        case .nieInitial, .nieRenewal, .tie, .residencyCertificate:
            // Cita Previa Extranjería (sede AGE) — province selected in-portal.
            return URL(string: "https://sede.administracionespublicas.gob.es/icpplus/index.html")!
        case .empadronamiento:
            let q = "cita previa empadronamiento \(area)"
            let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "cita%20previa%20empadronamiento"
            return URL(string: "https://www.google.com/search?q=\(encoded)")!
        case .consulate:
            // citaconsular.es is the booking system used by Spanish consulates abroad.
            return URL(string: "https://www.citaconsular.es/")!
        }
    }
}

/// A user-configured cita reminder. This is the client-only guided model: GoThere
/// does NOT poll the government system server-side. Instead it deep-links into
/// the correct portal and (optionally) nudges the user to check during weekday
/// release windows. `lastChecked` is stamped when the user opens the portal.
struct CitaMonitor: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var typeRaw: String
    var area: String          // province (or country/city for consulate)
    var remindersEnabled: Bool = true
    var createdAt: Date = Date()
    var lastChecked: Date? = nil

    var type: CitaAppointmentType { CitaAppointmentType(rawValue: typeRaw) ?? .nieInitial }

    init(type: CitaAppointmentType, area: String, remindersEnabled: Bool = true,
         id: String = UUID().uuidString, createdAt: Date = Date(), lastChecked: Date? = nil) {
        self.id = id
        self.typeRaw = type.rawValue
        self.area = area
        self.remindersEnabled = remindersEnabled
        self.createdAt = createdAt
        self.lastChecked = lastChecked
    }
}

/// Spanish provinces (+ Ceuta/Melilla) for the area picker. Used for the reminder
/// text and to scope the empadronamiento search; the Extranjería portal still
/// asks the user to confirm the province on its own form.
enum CitaProvinces {
    static let all: [String] = [
        "A Coruña", "Álava", "Albacete", "Alicante", "Almería", "Asturias", "Ávila",
        "Badajoz", "Baleares", "Barcelona", "Bizkaia", "Burgos", "Cáceres", "Cádiz",
        "Cantabria", "Castellón", "Ciudad Real", "Córdoba", "Cuenca", "Gipuzkoa",
        "Girona", "Granada", "Guadalajara", "Huelva", "Huesca", "Jaén", "La Rioja",
        "Las Palmas", "León", "Lleida", "Lugo", "Madrid", "Málaga", "Murcia",
        "Navarra", "Ourense", "Palencia", "Pontevedra", "Salamanca",
        "Santa Cruz de Tenerife", "Segovia", "Sevilla", "Soria", "Tarragona",
        "Teruel", "Toledo", "Valencia", "Valladolid", "Zamora", "Zaragoza",
        "Ceuta", "Melilla"
    ]
}

/// UserDefaults-backed persistence for cita monitors. Codable array under one key.
enum CitaMonitorStore {
    private static let key = "gothere.cita.monitors"

    static func load() -> [CitaMonitor] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let monitors = try? JSONDecoder().decode([CitaMonitor].self, from: data) else { return [] }
        return monitors
    }

    static func save(_ monitors: [CitaMonitor]) {
        guard let data = try? JSONEncoder().encode(monitors) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    @discardableResult
    static func upsert(_ monitor: CitaMonitor) -> [CitaMonitor] {
        var monitors = load()
        if let idx = monitors.firstIndex(where: { $0.id == monitor.id }) {
            monitors[idx] = monitor
        } else {
            monitors.append(monitor)
        }
        save(monitors)
        return monitors
    }

    @discardableResult
    static func remove(id: String) -> [CitaMonitor] {
        var monitors = load().filter { $0.id != id }
        save(monitors)
        return monitors
    }
}
