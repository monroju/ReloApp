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
        case .localista: return String(localized: "Spain news, alerts and trámites in English")
        case .passdgt: return String(localized: "Practice the Spanish DGT theory test in English. Free, offline.")
        }
    }

    /// Asset catalog name of the app's real icon, shown next to the app name.
    var iconName: String {
        switch self {
        case .localista: return "PromoLocalista"
        case .passdgt: return "PromoPassDGT"
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
        var props: [String: Any] = ["target_app": app.rawValue, "placement": placement.rawValue]
        if let countryId { props["country_id"] = countryId }
        Analytics.log(.crossPromoTapped, properties: props)
        UIApplication.shared.open(app.storeURL)
    }
}
