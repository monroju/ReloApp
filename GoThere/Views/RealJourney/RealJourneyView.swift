import SwiftUI

/// Premium-only view rendering a sanitized, real-world visa journey end-to-end.
/// Gated by `PurchaseManager.hasAllAccess` (subscription / lifetime / bundle combo).
/// Free Spain users see a paywall preview; subscribers see the full content.
struct RealJourneyView: View {
    let journey: RealJourney
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var expandedPhase: String?
    @State private var showPaywall = false

    private var isUnlocked: Bool { purchaseManager.hasAllAccess }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    disclaimerBanner
                    if isUnlocked {
                        fullContent
                    } else {
                        lockedPreview
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Real Journey")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                Analytics.log(.paywallViewed, country: journey.countryId, extra: [
                    "source": "real_journey",
                    "journey_id": journey.id,
                    "is_unlocked": isUnlocked
                ])
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(journey.title)
                .font(.title2.bold())
                .foregroundColor(.goPrimary)
            Text(journey.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Label(journey.totalDuration, systemImage: "calendar")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.goPrimary)
            Text(journey.disclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    @ViewBuilder
    private var fullContent: some View {
        eligibilityCard
        feeCard
        phasesList
        gotchasCard
    }

    private var eligibilityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Eligibility snapshot", icon: "checkmark.shield")
            ForEach(Array(journey.eligibilitySummary.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundColor(.goPrimary)
                    Text(item).font(.subheadline)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var feeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Fees & payment structure", icon: "eurosign.circle")
            Text(journey.feeSummary)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var phasesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Phase-by-phase walkthrough", icon: "list.number")
            ForEach(journey.phases) { phase in
                phaseCard(phase)
            }
        }
    }

    private func phaseCard(_ phase: JourneyPhase) -> some View {
        let isExpanded = expandedPhase == phase.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedPhase = isExpanded ? nil : phase.id
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phase.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(phase.timeframe)
                            .font(.caption)
                            .foregroundColor(.goPrimary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()
                    Text(phase.summary)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    if !phase.documents.isEmpty {
                        subSection("Documents") {
                            ForEach(Array(phase.documents.enumerated()), id: \.offset) { _, doc in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "doc.text").foregroundColor(.goPrimary).font(.caption)
                                    Text(doc).font(.caption).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if !phase.lawyerPatterns.isEmpty {
                        subSection("What the lawyer typically says") {
                            ForEach(phase.lawyerPatterns) { p in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.situation)
                                        .font(.caption2.bold())
                                        .foregroundColor(.goPrimary)
                                    Text(p.phrasing)
                                        .font(.caption)
                                        .italic()
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if !phase.gotchas.isEmpty {
                        subSection("Gotchas") {
                            ForEach(Array(phase.gotchas.enumerated()), id: \.offset) { _, g in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle").foregroundColor(.orange).font(.caption)
                                    Text(g).font(.caption).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .padding(.top, 0)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var gotchasCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Cross-phase gotchas worth knowing", icon: "lightbulb")
            ForEach(journey.crossPhaseGotchas) { g in
                VStack(alignment: .leading, spacing: 4) {
                    Text(g.title).font(.subheadline.bold())
                    Text(g.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Locked preview

    private var lockedPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Inside this guide")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                ForEach(journey.phases.prefix(8)) { phase in
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").foregroundColor(.goPrimary).font(.caption)
                        Text(phase.title).font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text("What you'll get")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                bulletRow("Every document the lawyer requested, by phase")
                bulletRow("Real fee ranges + payment-split structure")
                bulletRow("Sanitized correspondence patterns (what the lawyer actually said)")
                bulletRow("Province-specific timing expectations")
                bulletRow("Subsanación playbook + 30-day deadline interpretation")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Button {
                showPaywall = true
            } label: {
                Label("Unlock all Real Journeys with GoThere Pro", systemImage: "lock.open.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.goPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button("Already subscribed? Restore") {
                Task { await purchaseManager.restorePurchases() }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.goPrimary)
            Text(title).font(.subheadline.bold())
        }
    }

    private func subSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundColor(.secondary)
            content()
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.goPrimary).font(.caption)
            Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }
}
