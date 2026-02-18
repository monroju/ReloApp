import Foundation

/// Monthly cost data for a city (all values in USD).
struct CityCostData: Identifiable {
    var id: String { cityId }
    let cityId: String
    let cityName: String
    let countryId: String
    let rent1Bed: Int
    let rent3Bed: Int
    let groceries: Int
    let dining: Int
    let transport: Int
    let utilities: Int
    let internet: Int
    let healthcare: Int

    var totalBudget: Int { rent1Bed + groceries + dining + transport + utilities + internet + healthcare }
    var totalFamily: Int { rent3Bed + groceries + dining + transport + utilities + internet + healthcare }
}

enum CostDatabase {
    static let all: [CityCostData] = [
        // Spain
        CityCostData(cityId: "madrid", cityName: "Madrid", countryId: "spain",
            rent1Bed: 900, rent3Bed: 1600, groceries: 300, dining: 200, transport: 55, utilities: 120, internet: 35, healthcare: 80),
        CityCostData(cityId: "barcelona", cityName: "Barcelona", countryId: "spain",
            rent1Bed: 950, rent3Bed: 1700, groceries: 300, dining: 200, transport: 55, utilities: 120, internet: 35, healthcare: 80),
        CityCostData(cityId: "valencia", cityName: "Valencia", countryId: "spain",
            rent1Bed: 700, rent3Bed: 1200, groceries: 250, dining: 160, transport: 45, utilities: 100, internet: 30, healthcare: 80),
        CityCostData(cityId: "malaga", cityName: "Malaga", countryId: "spain",
            rent1Bed: 750, rent3Bed: 1300, groceries: 250, dining: 160, transport: 40, utilities: 100, internet: 30, healthcare: 80),
        CityCostData(cityId: "seville", cityName: "Sevilla", countryId: "spain",
            rent1Bed: 650, rent3Bed: 1100, groceries: 240, dining: 150, transport: 40, utilities: 100, internet: 30, healthcare: 80),

        // Portugal
        CityCostData(cityId: "lisbon", cityName: "Lisbon", countryId: "portugal",
            rent1Bed: 850, rent3Bed: 1500, groceries: 250, dining: 150, transport: 40, utilities: 100, internet: 30, healthcare: 60),
        CityCostData(cityId: "porto", cityName: "Porto", countryId: "portugal",
            rent1Bed: 650, rent3Bed: 1100, groceries: 220, dining: 130, transport: 35, utilities: 90, internet: 30, healthcare: 60),
        CityCostData(cityId: "faro", cityName: "Faro", countryId: "portugal",
            rent1Bed: 550, rent3Bed: 900, groceries: 200, dining: 120, transport: 30, utilities: 85, internet: 30, healthcare: 60),
        CityCostData(cityId: "funchal", cityName: "Funchal", countryId: "portugal",
            rent1Bed: 600, rent3Bed: 1000, groceries: 220, dining: 130, transport: 35, utilities: 90, internet: 30, healthcare: 60),
        CityCostData(cityId: "cascais", cityName: "Cascais", countryId: "portugal",
            rent1Bed: 900, rent3Bed: 1600, groceries: 260, dining: 160, transport: 40, utilities: 100, internet: 30, healthcare: 60),

        // Mexico
        CityCostData(cityId: "mexico_city", cityName: "Mexico City", countryId: "mexico",
            rent1Bed: 600, rent3Bed: 1100, groceries: 200, dining: 120, transport: 25, utilities: 50, internet: 25, healthcare: 40),
        CityCostData(cityId: "guadalajara", cityName: "Guadalajara", countryId: "mexico",
            rent1Bed: 450, rent3Bed: 800, groceries: 180, dining: 100, transport: 20, utilities: 45, internet: 25, healthcare: 40),
        CityCostData(cityId: "merida", cityName: "Merida", countryId: "mexico",
            rent1Bed: 400, rent3Bed: 700, groceries: 170, dining: 90, transport: 20, utilities: 50, internet: 25, healthcare: 35),
        CityCostData(cityId: "playa_del_carmen", cityName: "Playa del Carmen", countryId: "mexico",
            rent1Bed: 550, rent3Bed: 950, groceries: 200, dining: 120, transport: 20, utilities: 50, internet: 25, healthcare: 40),
        CityCostData(cityId: "san_miguel", cityName: "San Miguel de Allende", countryId: "mexico",
            rent1Bed: 500, rent3Bed: 900, groceries: 190, dining: 110, transport: 20, utilities: 45, internet: 25, healthcare: 35),
        CityCostData(cityId: "puerto_vallarta", cityName: "Puerto Vallarta", countryId: "mexico",
            rent1Bed: 500, rent3Bed: 900, groceries: 190, dining: 110, transport: 20, utilities: 50, internet: 25, healthcare: 35),
    ]

    static func cities(for countryId: String) -> [CityCostData] {
        all.filter { $0.countryId == countryId }
    }
}
