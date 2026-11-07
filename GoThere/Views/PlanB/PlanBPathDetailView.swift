import SwiftUI

/// One tracked descent path: document checklist per person, where to order each
/// paper, stages and rule alerts. Every fact shown comes from descent_chains.json
/// with its source; missing facts say "Not yet verified".
struct PlanBPathDetailView: View {
    let pathId: String

    @ObservedObject private var store = PlanBStore.shared
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var confirmRemove = false
    @State private var expandedHints: Set<String> = []
    private let chains = DescentChainRepository.shared
    private let ancestry = AncestryRepository.shared

    private var path: PlanBPath? { store.paths.first { $0.id == pathId } }

    var body: some View {
        Group {
            if let path, let chain = chains.chain(pathwayId: path.pathwayId) {
                content(path, chain)
            } else {
                ContentUnavailableView("Path not found", systemImage: "questionmark.folder")
            }
        }
        .background(Color.goBackgroundLight.opacity(0.4))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: "planb").environmentObject(purchaseManager)
        }
    }

    private func content(_ path: PlanBPath, _ chain: DescentChain) -> some View {
        let ancestorPath = ancestry.paths.first { $0.id == chain.ancestryPathId }
        let name = ancestorPath.flatMap { DestinationConfig.getDestination($0.countryId)?.displayName }
            ?? ancestorPath?.countryName ?? path.countryCode.uppercased()
        let unlocked = ancestorPath.map { purchaseManager.isCountryUnlocked($0.countryId) } ?? purchaseManager.hasAllAccess

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summary(path, name)
                documentsSection(path, chain)
                stagesSection(path, chain, unlocked: unlocked)
                milestonesSection(path)
                alertsSection(path)
                sourcesSection(chain)
                Button(role: .destructive) { confirmRemove = true } label: {
                    Label("Stop tracking this path", systemImage: "trash").font(.subheadline)
                }
                .confirmationDialog("Stop tracking \(name)?", isPresented: $confirmRemove, titleVisibility: .visible) {
                    Button("Stop tracking", role: .destructive) {
                        store.remove(path)
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(name)
    }

    // MARK: Summary

    private func summary(_ path: PlanBPath, _ name: String) -> some View {
        HStack(spacing: 16) {
            PlanBScoreRing(score: PlanBScore.path(path), size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(path.doneCount) of \(path.activeItems.count) documents done")
                    .font(.headline)
                Text("Score counts documents marked Done, plus filing and your appointment. It is not a prediction of approval.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Documents

    private static let roleOrder = ["self", "parent", "grandparent", "ggp", "ancestor"]

    static func personName(_ role: String) -> String {
        if role == "ancestor" { return String(localized: "Citizen ancestor") }
        return PlanBRole(rawValue: role)?.displayName ?? role
    }

    private func documentsSection(_ path: PlanBPath, _ chain: DescentChain) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents").font(.headline)
            ForEach(Self.roleOrder, id: \.self) { role in
                let items = path.items.filter { $0.personRole == role }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Self.personName(role))
                            .font(.subheadline.bold())
                            .foregroundColor(.goPrimary)
                        ForEach(items) { item in
                            itemRow(item, path, chain)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: PlanBPath.Item, _ path: PlanBPath, _ chain: DescentChain) -> some View {
        let doc = PlanBChainBuilder.document(for: item, in: chain)
        let skipped = item.skipped == true
        let hints = doc.map { chains.hints(for: chain, ids: $0.orderHintIds) } ?? []

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(doc.map { DataLanguage.pick($0.label, $0.labelEs) } ?? item.kind)
                    .font(.subheadline)
                    .strikethrough(skipped)
                    .foregroundColor(skipped ? .secondary : .primary)
                Spacer()
                Menu {
                    ForEach(PlanBDocState.allCases) { state in
                        Button(state.displayName) { store.setState(state, itemId: item.id, in: path.id) }
                    }
                } label: {
                    Text(item.state.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state == .done ? Color.green.opacity(0.15) : Color.goPrimary.opacity(0.12))
                        .foregroundColor(item.state == .done ? .green : .goPrimary)
                        .cornerRadius(8)
                }
                .disabled(skipped)
            }
            if let doc, let condition = doc.condition {
                Text(DataLanguage.pick(condition, doc.conditionEs))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Toggle("Not needed for me", isOn: Binding(
                    get: { skipped },
                    set: { store.setSkipped($0, itemId: item.id, in: path.id) }
                ))
                .font(.caption)
            }
            if let doc {
                badges(doc)
            }
            if let ordered = item.orderedOn {
                Text("Ordered on \(ordered)").font(.caption2).foregroundColor(.secondary)
            }
            if !hints.isEmpty {
                DisclosureGroup(isExpanded: Binding(
                    get: { expandedHints.contains(item.id) },
                    set: { if $0 { expandedHints.insert(item.id) } else { expandedHints.remove(item.id) } }
                )) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(hints) { hint in hintView(hint) }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Where to get it").font(.caption.bold())
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func badges(_ doc: DescentChain.Document) -> some View {
        let apostille = doc.needsApostille == true
        let translation = doc.needsTranslation == true
        if apostille || translation {
            HStack(spacing: 6) {
                if apostille { badge("Apostille") }
                if translation { badge("Translation") }
            }
        }
    }

    private func badge(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.goTertiary.opacity(0.12))
            .foregroundColor(.goTertiary)
            .cornerRadius(6)
    }

    private func hintView(_ hint: DescentOrderHint) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(DataLanguage.pick(hint.label, hint.labelEs)).font(.caption.bold())
            if let howTo = hint.howTo {
                Text(DataLanguage.pick(howTo, hint.howToEs)).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Not yet verified").font(.caption).foregroundColor(.secondary)
            }
            if let fee = hint.fee {
                Text("Fee: \(fee)").font(.caption2).foregroundColor(.secondary)
            }
            if let s = hint.url, let url = URL(string: s) {
                Link(destination: url) {
                    Label("Open official page", systemImage: "arrow.up.right.square").font(.caption)
                }
            }
            if let checked = hint.lastVerified {
                Text("Checked \(checked)").font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    // MARK: Stages

    private func stagesSection(_ path: PlanBPath, _ chain: DescentChain, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stages").font(.headline)
            Picker("Current stage", selection: Binding(
                get: { path.stage },
                set: { store.setStage($0, in: path.id) }
            )) {
                ForEach(chain.stages) { stage in
                    Text(DataLanguage.pick(stage.label, stage.labelEs))
                        .tag(PlanBStage(rawValue: stage.id) ?? .gather)
                }
            }
            .pickerStyle(.menu)

            ForEach(chain.stages) { stage in
                HStack(alignment: .top) {
                    Image(systemName: stage.id == path.stage.rawValue ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.goPrimary)
                    Text(DataLanguage.pick(stage.label, stage.labelEs)).font(.subheadline)
                    Spacer()
                    if unlocked {
                        Text(monthsText(stage.typicalMonths)).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            if !unlocked {
                Button {
                    Analytics.log(.planbPaywallShown, properties: ["reason": "timelines", "cc": path.countryCode])
                    showPaywall = true
                } label: {
                    Label("Keep your Plan B on track: unlock stage timelines", systemImage: "lock.fill")
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func monthsText(_ m: DescentChain.Stage.Months?) -> String {
        guard let m else { return String(localized: "Not yet verified") }
        let f: (Double) -> String = { $0 == $0.rounded() ? String(Int($0)) : String(format: "%.1f", $0) }
        if m.low == m.high { return String(localized: "about \(f(m.low)) mo") }
        return String(localized: "\(f(m.low)) to \(f(m.high)) mo")
    }

    // MARK: Filing and appointment

    private func milestonesSection(_ path: PlanBPath) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            dateToggle("Application filed", value: path.filedOn) { store.setFiled($0, in: path.id) }
            dateToggle("Appointment booked", value: path.appointmentOn) { store.setAppointment($0, in: path.id) }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func dateToggle(_ title: LocalizedStringKey, value: String?, set: @escaping (Date?) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(title, isOn: Binding(get: { value != nil }, set: { set($0 ? Date() : nil) }))
                .font(.subheadline)
            if let date = PlanBDate.date(value) {
                DatePicker("Date", selection: Binding(get: { date }, set: { set($0) }), displayedComponents: .date)
                    .font(.caption)
            }
        }
    }

    // MARK: Alerts

    private func alertsSection(_ path: PlanBPath) -> some View {
        let available = Set(PushNotificationService.ruleAlertCodes.values).contains(path.countryCode)
        let freeHolder = store.alertCountryCodes.first { Set(PushNotificationService.ruleAlertCodes.values).contains($0) }
        let cappedOut = !purchaseManager.hasAllAccess && path.alertsEnabled && available
            && freeHolder != nil && freeHolder != path.countryCode

        return VStack(alignment: .leading, spacing: 8) {
            Text("Rule alerts").font(.headline)
            if available {
                Toggle("Alert me when the rules change", isOn: Binding(
                    get: { path.alertsEnabled },
                    set: { store.setAlerts($0, in: path.id) }
                ))
                .font(.subheadline)
                if cappedOut {
                    Button {
                        Analytics.log(.planbPaywallShown, properties: ["reason": "alerts", "cc": path.countryCode])
                        showPaywall = true
                    } label: {
                        Text("The free plan includes alerts for one country. Unlock alerts for every country you track.")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            } else {
                Text("Rule alerts for this country are not available yet. GoThere still re-checks the official sources before each release.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.goPrimary.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: Sources

    private func sourcesSection(_ chain: DescentChain) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Official sources").font(.headline)
            if let checked = chain.lastVerified {
                Text("Rules last verified \(checked)").font(.caption).foregroundColor(.secondary)
            }
            ForEach(chain.sources, id: \.self) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        Label(source.title, systemImage: "arrow.up.right.square")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Text(chains.disclaimer).font(.caption2).foregroundColor(.secondary).padding(.top, 4)
        }
    }
}
