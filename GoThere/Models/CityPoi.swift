import Foundation
import SwiftUI

struct CityPoiData: Codable {
    let cityId: String
    let countryId: String
    let centerLat: Double
    let centerLng: Double
    let defaultZoom: Int
    let lastUpdated: String
    let pois: [Poi]
}

struct Poi: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let lat: Double
    let lng: Double
    let address: String?
    let phone: String?
    let website: String?
    let notes: String?
}

enum PoiCategory: String, CaseIterable, Identifiable {
    case bank = "bank"
    case hospital = "hospital"
    case clinic = "clinic"
    case governmentImmigration = "government_immigration"
    case governmentTax = "government_tax"
    case coworking = "coworking"
    case supermarket = "supermarket"
    case internationalSchool = "international_school"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bank: return "Banks"
        case .hospital: return "Hospitals"
        case .clinic: return "Clinics"
        case .governmentImmigration: return "Immigration"
        case .governmentTax: return "Tax Office"
        case .coworking: return "Coworking"
        case .supermarket: return "Supermarkets"
        case .internationalSchool: return "Intl Schools"
        }
    }

    var color: Color {
        switch self {
        case .bank: return .blue
        case .hospital: return .red
        case .clinic: return .pink
        case .governmentImmigration: return .purple
        case .governmentTax: return .indigo
        case .coworking: return .orange
        case .supermarket: return .green
        case .internationalSchool: return .teal
        }
    }

    var systemImage: String {
        switch self {
        case .bank: return "building.columns"
        case .hospital: return "cross.case"
        case .clinic: return "stethoscope"
        case .governmentImmigration: return "person.text.rectangle"
        case .governmentTax: return "doc.text"
        case .coworking: return "desktopcomputer"
        case .supermarket: return "cart"
        case .internationalSchool: return "graduationcap"
        }
    }

    static func from(_ id: String) -> PoiCategory? {
        allCases.first { $0.rawValue == id }
    }
}
