import Foundation

/// On-device tool implementations for the AI conversational entry point.
///
/// Mirrors the tool definitions the proxy advertises to Claude. When the model
/// emits a `tool_use` block, AIService routes it here. The output is a string
/// (Claude-friendly) — typically a small JSON document so the model can pick
/// out fields by name in the follow-up turn.
///
/// Add tools by appending an `AIToolDefinition` to `allDefinitions` and a
/// matching case in `execute(name:input:)`. Keep the on-device implementation
/// pure (no Firestore, no network) — these run hot inside the conversation
/// loop.
enum AIToolRegistry {

    // MARK: - Tool catalog (advertised to Claude)

    static let allDefinitions: [AIToolDefinition] = [
        recommendVisas,
        listCitiesForCountry,
        listWizardTracksForCountry
    ]

    static let recommendVisas = AIToolDefinition(
        name: "recommend_visas",
        description: "Rank up to 5 visa tracks for the given destination country against a household profile, budget, and optional ancestry. Mirrors the Decision Tree's visa-recommendation logic on the device.",
        inputSchema: AIToolInputSchema(
            properties: [
                "country_id": AIToolPropertySchema(
                    type: "string",
                    description: "Destination country slug, e.g. 'spain', 'portugal', 'mexico', 'canada', 'italy', 'ireland', 'germany', 'poland', 'hungary', 'argentina', 'uk_ancestry'."
                ),
                "household": AIToolPropertySchema(
                    type: "string",
                    description: "Household shape.",
                    enum: ["single", "couple", "family_kids", "single_parent", "retiree"]
                ),
                "budget": AIToolPropertySchema(
                    type: "string",
                    description: "Approximate monthly budget tier.",
                    enum: ["low", "medium", "high"]
                ),
                "ancestry": AIToolPropertySchema(
                    type: "string",
                    description: "Optional ancestry, if the user has disclosed one.",
                    enum: ["none", "italian", "irish", "polish", "german", "hungarian", "argentine", "british"]
                )
            ],
            required: ["country_id", "household", "budget"]
        )
    )

    static let listCitiesForCountry = AIToolDefinition(
        name: "list_cities_for_country",
        description: "Return GoThere's bundled cost-of-living data for cities in a country (USD per month: rent, groceries, transport, etc.). Use this when the user asks about cost of living or asks to compare cities within a country.",
        inputSchema: AIToolInputSchema(
            properties: [
                "country_id": AIToolPropertySchema(
                    type: "string",
                    description: "Destination country slug."
                )
            ],
            required: ["country_id"]
        )
    )

    static let listWizardTracksForCountry = AIToolDefinition(
        name: "list_wizard_tracks_for_country",
        description: "Return the visa-wizard tracks GoThere ships for a given destination country, including each track's eligibility-rule summary and whether the underlying law is currently in flux.",
        inputSchema: AIToolInputSchema(
            properties: [
                "country_id": AIToolPropertySchema(
                    type: "string",
                    description: "Destination country slug."
                )
            ],
            required: ["country_id"]
        )
    )

    // MARK: - Execution

    struct ToolResult {
        let payload: String
        let isError: Bool
    }

    static func execute(name: String, input: AIToolInput) -> ToolResult {
        switch name {
        case recommendVisas.name:
            return executeRecommendVisas(input)
        case listCitiesForCountry.name:
            return executeListCities(input)
        case listWizardTracksForCountry.name:
            return executeListWizardTracks(input)
        default:
            return ToolResult(payload: "Unknown tool: \(name)", isError: true)
        }
    }

    private static func executeRecommendVisas(_ input: AIToolInput) -> ToolResult {
        guard let countryId = input.string("country_id") else {
            return ToolResult(payload: "country_id is required", isError: true)
        }
        let household = mapHouseholdSlug(input.string("household") ?? "")
        let budget = mapBudgetSlug(input.string("budget") ?? "")
        let ancestry = mapAncestrySlug(input.string("ancestry") ?? "")

        var profile = UserProfile()
        profile.countryId = countryId
        profile.household = household
        profile.budget = budget
        let ranked = VisaRecommender.recommend(profile: profile, ancestry: ancestry)
        let payload = ranked.map { ranked -> [String: Any] in
            [
                "visa_id": ranked.visa.id,
                "name": ranked.visa.name,
                "short_name": ranked.visa.shortName,
                "category": ranked.visa.category.rawValue,
                "income_summary": ranked.visa.income,
                "monthly_income_eur": ranked.visa.monthlyIncomeEUR as Any,
                "wizard_track_id": ranked.visa.wizardTrackId as Any,
                "score": ranked.score,
                "reasons": ranked.reasons
            ]
        }
        return encodeJSONPayload(["results": payload])
    }

    private static func executeListCities(_ input: AIToolInput) -> ToolResult {
        guard let countryId = input.string("country_id") else {
            return ToolResult(payload: "country_id is required", isError: true)
        }
        let cities = CostDatabase.cities(for: countryId)
        let payload = cities.map { city -> [String: Any] in
            [
                "city_id": city.cityId,
                "city_name": city.cityName,
                "country_id": city.countryId,
                "rent_1bed_usd": city.rent1Bed,
                "rent_3bed_usd": city.rent3Bed,
                "groceries_usd": city.groceries,
                "dining_usd": city.dining,
                "transport_usd": city.transport,
                "utilities_usd": city.utilities,
                "internet_usd": city.internet,
                "healthcare_usd": city.healthcare,
                "total_single_usd": city.totalBudget,
                "total_family_usd": city.totalFamily
            ]
        }
        return encodeJSONPayload(["cities": payload])
    }

    private static func executeListWizardTracks(_ input: AIToolInput) -> ToolResult {
        guard let countryId = input.string("country_id") else {
            return ToolResult(payload: "country_id is required", isError: true)
        }
        let tracks = WizardRepository.shared.tracksForCountry(countryId)
        let payload = tracks.map { (id, track) -> [String: Any] in
            var entry: [String: Any] = [
                "track_id": id,
                "display_name": track.displayName,
                "short_name": track.shortName,
                "step_count": track.steps.count,
                "task_count": track.taskRules.count
            ]
            if let rule = track.eligibilityRule {
                entry["eligibility_summary"] = rule.summary
                entry["in_flux"] = rule.inFlux
                if let note = rule.inFluxNote {
                    entry["in_flux_note"] = note
                }
                if let gen = rule.generationCutoff {
                    entry["generation_cutoff"] = gen
                }
            }
            return entry
        }
        return encodeJSONPayload(["tracks": payload])
    }

    // MARK: - Slug → rawValue mapping

    private static func mapHouseholdSlug(_ slug: String) -> String {
        switch slug.lowercased() {
        case "single", "singles": return Household.singles.rawValue
        case "couple": return Household.couple.rawValue
        case "family_kids", "family": return Household.familyKids.rawValue
        case "single_parent": return Household.singleParent.rawValue
        case "retiree", "retired": return Household.retiree.rawValue
        default: return Household.couple.rawValue
        }
    }

    private static func mapBudgetSlug(_ slug: String) -> String {
        switch slug.lowercased() {
        case "low", "budget", "budget_friendly": return Budget.low.rawValue
        case "high", "premium": return Budget.high.rawValue
        case "medium", "mid", "mid_range": return Budget.medium.rawValue
        default: return Budget.medium.rawValue
        }
    }

    private static func mapAncestrySlug(_ slug: String) -> Ancestry {
        switch slug.lowercased() {
        case "italian": return .italian
        case "irish": return .irish
        case "polish": return .polish
        case "german": return .german
        case "hungarian": return .hungarian
        case "argentine", "argentinian": return .argentine
        case "british", "uk", "english": return .british
        default: return .none
        }
    }

    // MARK: - JSON helpers

    private static func encodeJSONPayload(_ payload: [String: Any]) -> ToolResult {
        let sanitized = sanitize(payload)
        guard let data = try? JSONSerialization.data(withJSONObject: sanitized, options: [.sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return ToolResult(payload: "{\"error\":\"failed to encode\"}", isError: true)
        }
        return ToolResult(payload: str, isError: false)
    }

    /// JSONSerialization rejects `Any` values that are NSNull / nil-wrapped via
    /// `as Any`. Walk the tree and replace nil-bearing leaves with NSNull.
    private static func sanitize(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            return dict.mapValues { sanitize($0) }
        }
        if let arr = value as? [Any] {
            return arr.map { sanitize($0) }
        }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            if mirror.children.isEmpty {
                return NSNull()
            }
            return sanitize(mirror.children.first!.value)
        }
        return value
    }
}
