import Foundation

/// Plan B tracked paths, stored on device only (UserDefaults JSON). Names and
/// dates the user types never leave the phone; analytics carry country, kind and
/// state only.
@MainActor
final class PlanBStore: ObservableObject {
    static let shared = PlanBStore()

    nonisolated static let pathsKey = "gothere.planb.paths.v1"
    nonisolated static let planModeKey = "gothere.planMode"  // also read raw in MainTabView

    @Published private(set) var paths: [PlanBPath] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.pathsKey),
           let decoded = try? JSONDecoder().decode([PlanBPath].self, from: data) {
            paths = decoded
        }
    }

    // MARK: Plan mode

    /// "planB" when the user picked "Just keeping my options open". Lands them on the Plan B tab.
    var isPlanBMode: Bool { defaults.string(forKey: Self.planModeKey) == "planB" }

    func selectPlanBIntent(source: String) {
        guard !isPlanBMode else { return }
        defaults.set("planB", forKey: Self.planModeKey)
        Analytics.log(.planbIntentSelected, properties: ["source": source])
    }

    // MARK: Paths

    var overallScore: Int { PlanBScore.overall(paths) }

    func isTracking(pathwayId: String) -> Bool { paths.contains { $0.pathwayId == pathwayId } }

    @discardableResult
    func trackDescent(chain: DescentChain, ancestor: PlanBRole, now: Date = Date()) -> PlanBPath {
        if let existing = paths.first(where: { $0.pathwayId == chain.pathwayId }) { return existing }
        let path = PlanBPath(
            id: UUID().uuidString,
            type: "descent",
            countryCode: chain.countryCode,
            pathwayId: chain.pathwayId,
            createdAt: ISO8601DateFormatter().string(from: now),
            planMode: isPlanBMode ? "planB" : "move",
            lineage: PlanBChainBuilder.lineage(upTo: ancestor),
            items: PlanBChainBuilder.items(for: chain, ancestor: ancestor),
            stage: .gather,
            alertsOn: true
        )
        paths.append(path)
        save()
        Analytics.log(.planbPathTracked, properties: ["cc": chain.countryCode, "type": "descent",
                                                      "ancestor": ancestor.rawValue])
        return path
    }

    func remove(_ path: PlanBPath) {
        paths.removeAll { $0.id == path.id }
        save()
    }

    func setState(_ state: PlanBDocState, itemId: String, in pathId: String, now: Date = Date()) {
        update(pathId) { p in
            guard let i = p.items.firstIndex(where: { $0.id == itemId }) else { return }
            p.items[i].state = state
            if state == .ordered, p.items[i].orderedOn == nil { p.items[i].orderedOn = PlanBDate.string(now) }
            Analytics.log(.planbDocState, properties: ["cc": p.countryCode, "kind": p.items[i].kind,
                                                       "state": state.rawValue])
        }
    }

    func setSkipped(_ skipped: Bool, itemId: String, in pathId: String) {
        update(pathId) { p in
            guard let i = p.items.firstIndex(where: { $0.id == itemId }) else { return }
            p.items[i].skipped = skipped ? true : nil
        }
    }

    func setStage(_ stage: PlanBStage, in pathId: String) {
        update(pathId) { $0.stage = stage }
    }

    func setFiled(_ date: Date?, in pathId: String) {
        update(pathId) { $0.filedOn = date.map(PlanBDate.string) }
    }

    func setAppointment(_ date: Date?, in pathId: String) {
        update(pathId) { $0.appointmentOn = date.map(PlanBDate.string) }
    }

    func setAlerts(_ on: Bool, in pathId: String) {
        update(pathId) { $0.alertsOn = on }
    }

    /// Two-letter codes of tracked paths that want rule alerts, oldest first.
    var alertCountryCodes: [String] {
        paths.filter(\.alertsEnabled).map(\.countryCode)
    }

    private func update(_ pathId: String, _ change: (inout PlanBPath) -> Void) {
        guard let i = paths.firstIndex(where: { $0.id == pathId }) else { return }
        change(&paths[i])
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(paths) {
            defaults.set(data, forKey: Self.pathsKey)
        }
        PushNotificationService.shared.syncRuleAlertTopics()
    }
}

#if DEBUG
extension PlanBStore {
    /// CI store screenshots only (launch argument -GTSeedPlanB). Replaces any paths with one
    /// Ireland grandparent path: most documents done, one apostilled, one ordered, so the
    /// readiness ring reads about 60. Also opens the app on the Plan B tab.
    func seedForScreenshots() {
        for p in paths { remove(p) }
        guard let chain = DescentChainRepository.shared.chain(pathwayId: "ie_foreign_births_register") else { return }
        defaults.set("planB", forKey: Self.planModeKey)
        let path = trackDescent(chain: chain, ancestor: .grandparent)
        let items = path.activeItems
        let done = Int((Double(items.count) * 6.0 / 7.0).rounded(.up))
        for (i, item) in items.enumerated() {
            let state: PlanBDocState = i < done ? .done : (i == done ? .apostilled : .ordered)
            setState(state, itemId: item.id, in: path.id)
        }
    }
}
#endif
