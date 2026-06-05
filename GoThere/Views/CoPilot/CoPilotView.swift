import SwiftUI

/// Co-Pilot dashboard — a single screen that reads everything GoThere knows
/// (visa, income, documents, tasks, target date, cita) and surfaces compound
/// insights no individual screen shows. Reached from the card atop the Tasks tab.
struct CoPilotView: View {
    @EnvironmentObject var countrySelection: CountrySelection
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var vm = CoPilotViewModel()
    @State private var pushRoute: InsightRoute?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                readinessHeader

                if vm.cards.isEmpty {
                    allClearCard
                } else {
                    ForEach(vm.cards) { card in
                        insightCardView(card)
                    }
                }

                disclaimer
            }
            .padding()
        }
        .navigationTitle("My Move")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $pushRoute) { route in
            switch route {
            case .calculator: CostCalculatorView()
            case .wizard:     VisaWizardView(countryId: countrySelection.current)
            case .cita:       CitaMonitorView()
            default:          EmptyView()
            }
        }
        .task { vm.start() }
        .onAppear { vm.rebuild() }
    }

    // MARK: - Readiness header

    private var readinessHeader: some View {
        let r = vm.readiness
        return HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(scoreColor(r.value).opacity(0.18), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: CGFloat(r.value) / 100)
                    .stroke(scoreColor(r.value), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(r.value)")
                        .font(.title.bold())
                        .foregroundColor(scoreColor(r.value))
                    Text("ready")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("Move readiness")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(r.label)
                    .font(.headline)
                if let days = vm.state.daysToTarget, days >= 0 {
                    Text("\(days) days to your target date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func scoreColor(_ value: Int) -> Color {
        if value >= 80 { return .goSuccess }
        if value >= 50 { return .goWarning }
        return .goError
    }

    // MARK: - Insight card

    private func insightCardView(_ card: InsightCard) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.icon)
                .font(.title3)
                .foregroundColor(severityColor(card.severity))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(.subheadline.weight(.semibold))
                Text(card.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let cta = card.ctaLabel, let route = card.route {
                    Button {
                        handle(route)
                    } label: {
                        HStack(spacing: 4) {
                            Text(cta)
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.goPrimary)
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor(card.severity).opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func severityColor(_ s: InsightSeverity) -> Color {
        switch s {
        case .red:   return .goError
        case .amber: return .goWarning
        case .green: return .goSuccess
        }
    }

    private var allClearCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundColor(.goSuccess)
            Text("Nothing needs your attention")
                .font(.subheadline.weight(.semibold))
            Text("As you add a visa, documents, and a target date, GoThere will surface compound insights here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var disclaimer: some View {
        Text("Insights are informational — verify visa, income, and document rules with official sources.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }

    // MARK: - Routing

    private func handle(_ route: InsightRoute) {
        switch route {
        case .documents, .resources, .decision, .tasks:
            NotificationCenter.default.post(
                name: .gothereDeepLink, object: nil,
                userInfo: ["route": route.rawValue])
        case .calculator, .wizard, .cita:
            pushRoute = route
        }
    }
}

/// Compact entry card for the Co-Pilot dashboard — shows the live readiness
/// score + the top alert, and pushes into `CoPilotView`. Placed atop the Tasks
/// tab. Self-contained (owns its own view-model) so host screens stay simple.
struct CoPilotCard: View {
    @StateObject private var vm = CoPilotViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationLink {
            CoPilotView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.18), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: CGFloat(vm.readiness.value) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(vm.readiness.value)")
                        .font(.caption.bold())
                        .foregroundColor(scoreColor)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your move co-pilot")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(topLine)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.goPrimary.opacity(0.10), Color.goTertiary.opacity(0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.goPrimary.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .task { vm.start() }
        .onAppear { vm.rebuild() }
    }

    /// The most urgent card's title, or the readiness label when all-clear.
    private var topLine: String {
        if let top = vm.cards.first { return top.title }
        return vm.readiness.label
    }

    private var scoreColor: Color {
        let v = vm.readiness.value
        if v >= 80 { return .goSuccess }
        if v >= 50 { return .goWarning }
        return .goError
    }
}
