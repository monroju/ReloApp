import Foundation

/// Headline numbers describing the depth of GoThere's content for one country.
///
/// Computed at runtime from VisaCatalog + CostDatabase + the bundled task seed JSON.
/// No app state, no network, no caching needed — call from any view at any time.
///
/// Powers the blurred-dashboard paywall reveal (LockedCountryPreviewView), metric-led
/// IAP descriptions on PaywallView, and any future surface that needs to summarize
/// "what you get when you unlock this country."
struct CountryMetrics: Equatable {
    /// Number of visa paths covered in VisaCatalog (e.g. Spain = 4: NLV, DNV, Work, Student).
    let visaPathsCount: Int
    /// Tasks in the country's seed JSON tagged to phase_2_documents (the docs-gathering phase).
    /// Approximates "required documents" for paywall teaser copy.
    let documentsCount: Int
    /// Min/max monthly income threshold across the country's passive/digital-nomad visas,
    /// normalized to EUR. Nil when no visa in the country has a parseable monthly income.
    let incomeRangeEUR: ClosedRange<Int>?
    /// Min/max processing time in weeks across the country's visas. Nil when none parse.
    let processingWeeksRange: ClosedRange<Int>?
    /// Count of visas with a built Wizard. Drives the "N step-by-step paths" teaser.
    let wizardTracksCount: Int
    /// Cities in CostDatabase covering the country.
    let citiesCovered: Int
    /// Total seed tasks across all phases for the country.
    let totalTasks: Int
}

enum CountryMetricsService {

    /// Pure function — call freely. Returns zero/nil metrics for unknown countryIds.
    static func compute(for countryId: String) -> CountryMetrics {
        let visas = VisaCatalog.byCountry(countryId)
        let seedTasks = loadSeedTasks(for: countryId)

        let monthlyEURs = visas.compactMap { parseMonthlyIncomeEUR($0.income) }.sorted()
        let incomeRange: ClosedRange<Int>? = monthlyEURs.isEmpty
            ? nil
            : (monthlyEURs.first! ... monthlyEURs.last!)

        let weekRanges = visas.compactMap { parseProcessingWeeks($0.processingTime) }
        let weeksMin = weekRanges.map(\.lowerBound).min()
        let weeksMax = weekRanges.map(\.upperBound).max()
        let processingRange: ClosedRange<Int>? = (weeksMin != nil && weeksMax != nil)
            ? (weeksMin! ... weeksMax!)
            : nil

        return CountryMetrics(
            visaPathsCount: visas.count,
            documentsCount: seedTasks.filter { $0.phaseId.hasPrefix("phase_2") }.count,
            incomeRangeEUR: incomeRange,
            processingWeeksRange: processingRange,
            wizardTracksCount: visas.filter { $0.wizardTrackId != nil }.count,
            citiesCovered: CostDatabase.cities(for: countryId).count,
            totalTasks: seedTasks.count
        )
    }

    /// Renders the income range as a one-line teaser, e.g. "€870–€2,400/mo".
    /// Returns nil when no monthly threshold exists (e.g. Canada is points-based).
    static func incomeRangeTeaser(_ metrics: CountryMetrics) -> String? {
        guard let range = metrics.incomeRangeEUR else { return nil }
        let lo = formatEUR(range.lowerBound)
        let hi = formatEUR(range.upperBound)
        return range.lowerBound == range.upperBound ? "\(lo)/mo" : "\(lo)–\(hi)/mo"
    }

    /// Renders the processing time range as a one-line teaser, e.g. "4 weeks–24 months".
    static func processingTeaser(_ metrics: CountryMetrics) -> String? {
        guard let range = metrics.processingWeeksRange else { return nil }
        return "\(formatWeeks(range.lowerBound))–\(formatWeeks(range.upperBound))"
    }

    // MARK: - Seed loading

    private struct SeedTask: Decodable {
        let phaseId: String
    }

    private static func loadSeedTasks(for countryId: String) -> [SeedTask] {
        let fileName = "\(countryId)_tasks"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "Seeds")
                ?? Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tasks = try? JSONDecoder().decode([SeedTask].self, from: data)
        else { return [] }
        return tasks
    }

    // MARK: - Parsers

    /// 2026 approximate FX rates used for income normalization.
    /// Update annually alongside the VisaCatalog refresh note in that file.
    private static let usdToEUR: Double = 0.92
    private static let gbpToEUR: Double = 1.17

    /// Extracts a monthly EUR threshold from a free-form income string.
    /// Handles: explicit /mo, explicit /yr (divides by 12), USD/EUR/GBP currency symbols,
    /// commas as thousands separators. Returns nil for non-monetary entries ("Points-based",
    /// "No income test", "Sufficient maintenance funds", etc.).
    static func parseMonthlyIncomeEUR(_ s: String) -> Int? {
        let lower = s.lowercased()
        let pattern = #"([€$£])\s?([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]+)?)\s?(k)?\s*(/mo|/yr|\+/yr)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let currencyRange = Range(match.range(at: 1), in: s),
              let numberRange = Range(match.range(at: 2), in: s)
        else { return nil }

        let currency = String(s[currencyRange])
        let numberStr = String(s[numberRange]).replacingOccurrences(of: ",", with: "")
        guard var amount = Double(numberStr) else { return nil }

        let isThousands = match.range(at: 3).location != NSNotFound
        if isThousands { amount *= 1000 }

        let unit: String
        if let unitRange = Range(match.range(at: 4), in: s) {
            unit = String(s[unitRange])
        } else {
            unit = ""
        }
        let isYearly = unit.contains("yr") || lower.contains("/yr")
        let isMonthly = unit.contains("mo") || lower.contains("/mo")

        // Reject ambiguous strings with no monthly/yearly marker — likely a salary floor with no rhythm,
        // or a savings amount, or a fee. Better to return nil than guess.
        guard isMonthly || isYearly else { return nil }

        let monthlyNative = isYearly ? amount / 12.0 : amount
        let monthlyEUR: Double
        switch currency {
        case "$": monthlyEUR = monthlyNative * usdToEUR
        case "£": monthlyEUR = monthlyNative * gbpToEUR
        default: monthlyEUR = monthlyNative
        }
        return Int(monthlyEUR.rounded())
    }

    /// Parses processing-time strings into a week range.
    /// Handles: "2-3 months", "4-8 weeks", "12-24 months", "20-45 days", "1-3 years",
    /// "30-90 days", "~6 months", "6-12 months".
    static func parseProcessingWeeks(_ s: String) -> ClosedRange<Int>? {
        let pattern = #"([0-9]+)\s*(?:-|–|to)\s*([0-9]+)\s*(day|days|week|weeks|month|months|year|years|yr|yrs)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let loRange = Range(match.range(at: 1), in: s),
              let hiRange = Range(match.range(at: 2), in: s),
              let unitRange = Range(match.range(at: 3), in: s),
              let lo = Int(s[loRange]),
              let hi = Int(s[hiRange])
        else {
            // Fallback for "~N months" or single-number strings.
            return parseSingleProcessingWeeks(s).map { $0 ... $0 }
        }
        let unit = String(s[unitRange]).lowercased()
        let multiplier = weeksMultiplier(forUnit: unit)
        return (lo * multiplier) ... (hi * multiplier)
    }

    private static func parseSingleProcessingWeeks(_ s: String) -> Int? {
        let pattern = #"([0-9]+)\s*(day|days|week|weeks|month|months|year|years|yr|yrs)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let numRange = Range(match.range(at: 1), in: s),
              let unitRange = Range(match.range(at: 2), in: s),
              let num = Int(s[numRange])
        else { return nil }
        return num * weeksMultiplier(forUnit: String(s[unitRange]).lowercased())
    }

    private static func weeksMultiplier(forUnit unit: String) -> Int {
        if unit.hasPrefix("day") { return 1 }  // rounded down — "30 days" ≈ 4 weeks is close enough
        if unit.hasPrefix("week") { return 1 }
        if unit.hasPrefix("month") { return 4 }
        if unit.hasPrefix("year") || unit.hasPrefix("yr") { return 52 }
        return 1
    }

    // MARK: - Display helpers

    private static func formatEUR(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let n = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "€\(n)"
    }

    private static func formatWeeks(_ weeks: Int) -> String {
        if weeks < 8 { return "\(weeks) week\(weeks == 1 ? "" : "s")" }
        if weeks < 52 {
            let months = max(1, weeks / 4)
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        let years = max(1, weeks / 52)
        return "\(years) year\(years == 1 ? "" : "s")"
    }

    // MARK: - Preview teaser data (LockedCountryPreviewView v1.1)

    /// A curated city + region pair used as a silhouette row in the blurred
    /// Decision Tree preview on LockedCountryPreviewView.
    struct PreviewCity {
        let name: String
        let region: String
    }

    /// Up to 4 cities for the blurred Decision Tree teaser on the locked country preview.
    ///
    /// For Spain/Portugal/Mexico the DecisionEngine already has first-class destination data —
    /// we surface the first 4 of those so the preview matches what the user sees post-unlock.
    /// For the other locked countries DecisionEngine currently falls back to SpainDestinations
    /// (known gap); the curated entries below reflect the cities that would seed the
    /// Decision Tree once that data lands. Until then, these are teaser-only.
    static func previewCities(for countryId: String) -> [PreviewCity] {
        switch countryId {
        case "spain":
            return [
                PreviewCity(name: "Madrid", region: "Capital · Big City"),
                PreviewCity(name: "Barcelona", region: "Catalonia · Coastal"),
                PreviewCity(name: "Valencia", region: "Valencia · Coastal"),
                PreviewCity(name: "Malaga", region: "Andalusia · Coastal")
            ]
        case "portugal":
            return [
                PreviewCity(name: "Lisbon", region: "Capital · Coastal"),
                PreviewCity(name: "Porto", region: "Norte · Coastal"),
                PreviewCity(name: "Cascais", region: "Lisboa · Coastal"),
                PreviewCity(name: "Funchal", region: "Madeira · Island")
            ]
        case "mexico":
            return [
                PreviewCity(name: "Mexico City", region: "Capital · Big City"),
                PreviewCity(name: "Guadalajara", region: "Jalisco · Big City"),
                PreviewCity(name: "Merida", region: "Yucatán · Mid City"),
                PreviewCity(name: "Playa del Carmen", region: "Quintana Roo · Coastal")
            ]
        case "canada":
            return [
                PreviewCity(name: "Toronto", region: "Ontario · Big City"),
                PreviewCity(name: "Montreal", region: "Quebec · Big City"),
                PreviewCity(name: "Vancouver", region: "BC · Coastal"),
                PreviewCity(name: "Halifax", region: "Nova Scotia · Coastal")
            ]
        case "ireland":
            return [
                PreviewCity(name: "Dublin", region: "Leinster · Capital"),
                PreviewCity(name: "Cork", region: "Munster · Coastal"),
                PreviewCity(name: "Galway", region: "Connacht · Coastal"),
                PreviewCity(name: "Limerick", region: "Munster · Mid City")
            ]
        case "italy":
            return [
                PreviewCity(name: "Milan", region: "Lombardy · Big City"),
                PreviewCity(name: "Rome", region: "Lazio · Capital"),
                PreviewCity(name: "Florence", region: "Tuscany · Mid City"),
                PreviewCity(name: "Bologna", region: "Emilia-Romagna · Mid City")
            ]
        case "germany":
            return [
                PreviewCity(name: "Berlin", region: "Capital · Big City"),
                PreviewCity(name: "Munich", region: "Bavaria · Big City"),
                PreviewCity(name: "Hamburg", region: "Hamburg · Coastal"),
                PreviewCity(name: "Leipzig", region: "Saxony · Mid City")
            ]
        case "poland":
            return [
                PreviewCity(name: "Warsaw", region: "Mazovia · Capital"),
                PreviewCity(name: "Krakow", region: "Lesser Poland · Mid City"),
                PreviewCity(name: "Wroclaw", region: "Lower Silesia · Mid City"),
                PreviewCity(name: "Gdansk", region: "Pomerania · Coastal")
            ]
        case "argentina":
            return [
                PreviewCity(name: "Buenos Aires", region: "Capital · Big City"),
                PreviewCity(name: "Cordoba", region: "Cordoba · Mid City"),
                PreviewCity(name: "Mendoza", region: "Cuyo · Mid City"),
                PreviewCity(name: "Bariloche", region: "Patagonia · Mountain")
            ]
        case "hungary":
            return [
                PreviewCity(name: "Budapest", region: "Pest · Capital"),
                PreviewCity(name: "Debrecen", region: "Hajdú-Bihar · Mid City"),
                PreviewCity(name: "Szeged", region: "Csongrád · Mid City"),
                PreviewCity(name: "Pécs", region: "Baranya · Mid City")
            ]
        case "uk_ancestry":
            return [
                PreviewCity(name: "London", region: "Greater London · Capital"),
                PreviewCity(name: "Manchester", region: "North West · Big City"),
                PreviewCity(name: "Edinburgh", region: "Scotland · Capital"),
                PreviewCity(name: "Bristol", region: "South West · Mid City")
            ]
        default:
            return []
        }
    }

    /// One-line cost teaser for the locked country preview.
    /// Returns the primary city + an approximate studio rent in EUR/mo.
    ///
    /// Sources: for Portugal/Mexico, derived from CostDatabase (rent1Bed × 0.85 to approximate studio,
    /// USD→EUR at 0.92). For other countries where CostDatabase has no rows, curated 2026 ballparks
    /// from Numbeo/Idealista equivalents — flagged as "approx" by the caller's copy.
    static func costTeaser(for countryId: String) -> (city: String, studioEUR: Int)? {
        if let city = CostDatabase.cities(for: countryId).first {
            let studioUSD = Double(city.rent1Bed) * 0.85
            let studioEUR = Int((studioUSD * usdToEUR).rounded())
            return (city.cityName, studioEUR)
        }

        // Curated approximations for countries without CostDatabase rows.
        // Numbers are deliberately conservative — they're shown alongside "approx" copy.
        switch countryId {
        case "canada": return ("Montreal", 900)
        case "ireland": return ("Cork", 1_100)
        case "italy": return ("Bologna", 750)
        case "germany": return ("Leipzig", 700)
        case "poland": return ("Krakow", 550)
        case "argentina": return ("Buenos Aires", 350)
        case "hungary": return ("Budapest", 500)
        case "uk_ancestry": return ("Manchester", 950)
        default: return nil
        }
    }
}

#if DEBUG

/// One-shot self-validator — call from a debug screen or Xcode breakpoint to confirm
/// every country produces sensible metrics. Returns the first failure description, or nil.
extension CountryMetricsService {
    static func selfCheck() -> String? {
        let countries = ["spain", "portugal", "mexico", "canada", "ireland", "italy",
                         "germany", "poland", "argentina", "hungary", "uk_ancestry"]
        for country in countries {
            let m = compute(for: country)
            if m.visaPathsCount == 0 {
                return "\(country): zero visa paths — VisaCatalog mapping broken?"
            }
            if m.totalTasks == 0 {
                return "\(country): zero seed tasks — JSON missing or unreadable?"
            }
            if m.totalTasks > 0 && m.documentsCount == 0 {
                return "\(country): \(m.totalTasks) tasks but zero in phase_2 — seed phaseId schema mismatch?"
            }
        }
        return nil
    }
}

#endif
