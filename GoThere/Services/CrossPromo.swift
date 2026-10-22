import Foundation
import UIKit

/// Our other apps, promoted from Settings and Resources. Mirrors Android `CrossPromo.kt`.
enum PromoApp: String {
    case localista
    case passdgt

    var title: String {
        switch self {
        case .localista: return "Localista"
        case .passdgt: return "PassDGT"
        }
    }

    var subtitle: String {
        switch self {
        case .localista: return "Spain news, alerts and trámites in English"
        case .passdgt: return "Practice the Spanish DGT theory test in English. Free, offline."
        }
    }

    /// SF Symbol shown next to the app name.
    var systemImage: String {
        switch self {
        case .localista: return "newspaper"
        case .passdgt: return "car"
        }
    }

    var storeURL: URL {
        switch self {
        case .localista: return URL(string: "https://apps.apple.com/app/id6760856341")!
        case .passdgt: return URL(string: "https://apps.apple.com/app/id6817719675")!
        }
    }
}

enum CrossPromoPlacement: String {
    case settings
    case resources
}

enum CrossPromo {
    /// Logs `cross_promo_tapped` and opens the App Store listing.
    static func open(_ app: PromoApp, placement: CrossPromoPlacement, countryId: String? = nil) {
        var props: [String: Any] = ["app": app.rawValue, "placement": placement.rawValue]
        if let countryId { props["country_id"] = countryId }
        Analytics.log(.crossPromoTapped, properties: props)
        UIApplication.shared.open(app.storeURL)
    }
}
