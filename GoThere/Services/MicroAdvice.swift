import Foundation

/// Provides destination-specific tips.
enum MicroAdvice {

    static func tips(for cityId: String, countryId: String) -> [String] {
        switch countryId {
        case "spain": return spainTips(cityId)
        case "portugal": return portugalTips(cityId)
        case "mexico": return mexicoTips(cityId)
        default: return []
        }
    }

    private static func spainTips(_ cityId: String) -> [String] {
        switch cityId {
        case "madrid":
            return ["Consider Chamberí or Salamanca for family living",
                    "Metro is excellent - you may not need a car",
                    "August is very hot and many shops close"]
        case "barcelona":
            return ["Eixample and Gracia are popular expat neighborhoods",
                    "Catalan is widely spoken alongside Spanish",
                    "Tourist tax applies to short-term rentals"]
        case "valencia":
            return ["Great balance of city life and beach",
                    "Ruzafa is the trendy neighborhood",
                    "Much more affordable than Madrid/Barcelona"]
        case "malaga":
            return ["Growing tech scene with expat-friendly coworking",
                    "Easy access to Costa del Sol beaches",
                    "Consider Pedregalejo for a local feel"]
        case "seville":
            return ["Prepare for very hot summers (40°C+)",
                    "Beautiful historic center walkable on foot",
                    "Lower cost of living than coastal cities"]
        default:
            return ["Spain offers excellent healthcare system",
                    "NIE (tax ID number) is essential - apply early",
                    "Lunch is the main meal (2-4 PM)"]
        }
    }

    private static func portugalTips(_ cityId: String) -> [String] {
        switch cityId {
        case "lisbon":
            return ["Príncipe Real and Santos are popular with expats",
                    "NHR tax regime can offer significant savings",
                    "Hills can be challenging - consider accessibility"]
        case "porto":
            return ["More affordable than Lisbon with similar culture",
                    "Foz do Douro is the upscale coastal area",
                    "Strong startup ecosystem growing fast"]
        case "cascais":
            return ["Premium area with international schools",
                    "30 min train to Lisbon center",
                    "Beach lifestyle with urban amenities"]
        case "funchal":
            return ["Year-round mild climate on Madeira island",
                    "Growing digital nomad community",
                    "Beautiful nature and hiking trails"]
        default:
            return ["Portugal has one of the most expat-friendly visa systems",
                    "NIF (tax number) is needed for almost everything",
                    "English is widely spoken in urban areas"]
        }
    }

    private static func mexicoTips(_ cityId: String) -> [String] {
        switch cityId {
        case "mexico_city":
            return ["Roma Norte and Condesa are expat favorites",
                    "Excellent public transit and ride-sharing",
                    "World-class food scene at affordable prices"]
        case "merida":
            return ["One of the safest cities in Mexico",
                    "Strong American and Canadian expat community",
                    "Hot and humid - AC is essential"]
        case "playa_del_carmen":
            return ["5th Avenue is the main expat/tourist hub",
                    "Easy access to Cancún airport",
                    "Beware of tourist pricing - shop locally"]
        case "san_miguel":
            return ["Large established American retiree community",
                    "Rich arts and cultural scene",
                    "Higher cost than most Mexican cities"]
        case "guadalajara":
            return ["Known as Mexico's 'Silicon Valley'",
                    "Providencia and Chapultepec are upscale areas",
                    "Very affordable compared to US cities"]
        default:
            return ["180-day tourist visa is easy to obtain",
                    "Temporary resident visa for longer stays",
                    "Cost of living is 40-60% less than US"]
        }
    }
}
