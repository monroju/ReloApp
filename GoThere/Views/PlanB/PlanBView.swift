import SwiftUI

/// Plan B tab: readiness score, tracked paths, next actions and rule alerts.
/// "Options, not exits": no decision asked of the user, no political wording.
struct PlanBView: View {
    var body: some View {
        NavigationStack {
            PlanBScreen()
        }
    }
}

struct PlanBScreen: View {
    @ObservedObject private var store = PlanBStore.shared
    @State private var scoreLogged = false
    private let chains = DescentChainRepository.shared
    private let ancestry = AncestryRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if store.paths.isEmpty {
                    emptyState
                } else {
                    pathsSection
                    nextActionsSection
                    alertsSection
                }
                Text(chains.disclaimer)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color.goBackgroundLight.opacity(0.4))
        .navigationTitle("Plan B")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !scoreLogged else { return }
            scoreLogged = true
            Analytics.log(.planbScoreViewed, properties: ["score_bucket": PlanBScore.bucket(store.overallScore),
                                                          "paths": store.paths.count])
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            PlanBScoreRing(score: store.overallScore, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("Options, not exits.")
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)
                Text("A second citizenship takes one to three years of paperwork. Start the slow part now, decide later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your paths").font(.headline)
            Text("Check whether a parent, grandparent or great-grandparent can pass citizenship down to you. If it looks likely, tap Track this path and GoThere builds your document checklist.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                AncestryCheckerView()
            } label: {
                Label("Check my ancestry", systemImage: "tree.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.goPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your paths").font(.headline)
                Spacer()
                NavigationLink {
                    AncestryCheckerView()
                } label: {
                    Label("Add", systemImage: "plus").font(.subheadline)
                }
            }
            ForEach(store.paths) { path in
                NavigationLink {
                    PlanBPathDetailView(pathId: path.id)
                } label: {
                    pathRow(path)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pathRow(_ path: PlanBPath) -> some View {
        HStack(spacing: 12) {
            PlanBScoreRing(score: PlanBScore.path(path), size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(countryName(path)).font(.body.bold()).foregroundColor(.primary)
                Text("\(path.doneCount) of \(path.activeItems.count) documents done")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private struct NextAction: Identifiable {
        let path: PlanBPath
        let item: PlanBPath.Item
        var id: String { path.id + "/" + item.id }
    }

    /// The first three open documents across all paths, earliest state first.
    private var nextActions: [NextAction] {
        let open = store.paths.flatMap { p in
            p.activeItems.filter { $0.state != .done }.map { NextAction(path: p, item: $0) }
        }
        let rank: (PlanBDocState) -> Int = { PlanBDocState.allCases.firstIndex(of: $0) ?? 0 }
        return Array(open.enumerated()
            .sorted { (rank($0.element.item.state), $0.offset) < (rank($1.element.item.state), $1.offset) }
            .map(\.element)
            .prefix(3))
    }

    @ViewBuilder
    private var nextActionsSection: some View {
        let actions = nextActions
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Next steps").font(.headline)
                ForEach(actions) { action in
                    let path = action.path
                    let item = action.item
                    NavigationLink {
                        PlanBPathDetailView(pathId: path.id)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.state == .notStarted ? "circle" : "clock")
                                .foregroundColor(.goPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(itemLabel(path, item)).font(.subheadline).foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Text("\(countryName(path)) · \(PlanBPathDetailView.personName(item.personRole)) · \(item.state.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rule watch").font(.headline)
            Text("GoThere checks the official sources every week. When a rule changes for a country you track, you get one alert with what changed and the source link.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                PushNotificationService.shared.requestPermissionAndSubscribe()
            } label: {
                Label("Turn on alerts", systemImage: "bell.badge")
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(Color.goPrimary.opacity(0.08))
        .cornerRadius(12)
    }

    private func countryName(_ path: PlanBPath) -> String {
        guard let chain = chains.chain(pathwayId: path.pathwayId),
              let a = ancestry.paths.first(where: { $0.id == chain.ancestryPathId }) else {
            return path.countryCode.uppercased()
        }
        return DestinationConfig.getDestination(a.countryId)?.displayName ?? a.countryName
    }

    private func itemLabel(_ path: PlanBPath, _ item: PlanBPath.Item) -> String {
        guard let chain = chains.chain(pathwayId: path.pathwayId),
              let doc = PlanBChainBuilder.document(for: item, in: chain) else { return item.kind }
        return DataLanguage.pick(doc.label, doc.labelEs)
    }
}

struct PlanBScoreRing: View {
    let score: Int
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().stroke(Color.goPrimary.opacity(0.18), lineWidth: size / 9)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(Color.goPrimary, style: StrokeStyle(lineWidth: size / 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(size > 60 ? .title3.bold() : .caption.bold())
                .foregroundColor(.goPrimary)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Readiness \(score) of 100"))
    }
}

/// Tasks home card for people with no move date: the Plan B entry point.
struct PlanBHomeCard: View {
    @ObservedObject private var store = PlanBStore.shared

    var body: some View {
        Button {
            NotificationCenter.default.post(name: .gothereDeepLink, object: nil, userInfo: ["route": "planb"])
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.goPrimary)
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        if store.paths.isEmpty {
                            Text("Not moving yet? Build your Plan B.")
                        } else {
                            Text("Your Plan B: \(store.overallScore) of 100")
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    Text("See if you can inherit a second citizenship and track the paperwork.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Shown from a "Likely eligible" checker result: pick the ancestor's generation, then track.
struct PlanBTrackSheet: View {
    let chain: DescentChain
    let countryName: String
    @Environment(\.dismiss) private var dismiss
    @State private var ancestor: PlanBRole = .grandparent

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Your \(countryName) ancestor is your", selection: $ancestor) {
                        ForEach(chain.ancestorChoices) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(.inline)
                } footer: {
                    if let note = chain.lineage.note {
                        Text(DataLanguage.pick(note, chain.lineage.noteEs))
                    }
                }
                Section {
                    Button("Track this path") {
                        PlanBStore.shared.trackDescent(chain: chain, ancestor: ancestor)
                        dismiss()
                        NotificationCenter.default.post(name: .gothereDeepLink, object: nil, userInfo: ["route": "planb"])
                    }
                    .font(.body.bold())
                } footer: {
                    Text("Names and dates you add stay on this phone.")
                }
            }
            .navigationTitle(countryName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                if !chain.ancestorChoices.contains(ancestor), let last = chain.ancestorChoices.last {
                    ancestor = last
                }
            }
        }
    }
}
