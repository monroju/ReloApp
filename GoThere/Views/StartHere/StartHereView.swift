import SwiftUI

/// "Where do I start?" triage funnel — one entry that drops a user into the tool that
/// matches their situation, sorting them by tier/need (budget, family, remote, heritage,
/// Plan B, rights). Ties the tier-targeting features into a single front door.
struct StartHereView: View {
    let initialCountryId: String?
    let onStartWizard: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    init(initialCountryId: String? = nil, onStartWizard: @escaping (String) -> Void = { _ in }) {
        self.initialCountryId = initialCountryId
        self.onStartWizard = onStartWizard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                intro

                route(icon: "dollarsign.circle.fill",
                      title: "Money's tight — is this even possible?",
                      subtitle: "See the real cost to move + the cheapest visa paths.") {
                    MoveCostCalculatorView(initialCountryId: initialCountryId)
                }
                route(icon: "figure.2.and.child.holdinghands",
                      title: "I'm moving with kids",
                      subtitle: "Schooling, healthcare & child visas, country by country.") {
                    FamilyMoveView(initialCountryId: initialCountryId)
                }
                route(icon: "laptopcomputer.and.arrow.down",
                      title: "I work remotely",
                      subtitle: "Employer-letter templates + the tax traps to avoid.") {
                    RemoteWorkView()
                }
                route(icon: "tree.fill",
                      title: "I might have EU or Latin heritage",
                      subtitle: "You could already be a citizen — check your eligibility.") {
                    AncestryCheckerView()
                }
                route(icon: "chart.line.uptrend.xyaxis",
                      title: "I want a Plan B / second passport",
                      subtitle: "Golden visas & citizenship by investment.") {
                    InvestmentMigrationView(onStartWizard: onStartWizard)
                }
                route(icon: "heart.text.square.fill",
                      title: "I'm worried about rights or safety",
                      subtitle: "Compare destinations on the protections that matter to you.") {
                    RightsSafetyView()
                }
                route(icon: "rectangle.split.3x1.fill",
                      title: "Just show me my options",
                      subtitle: "Compare every visa side by side.") {
                    VisaCompareView(initialCountryId: initialCountryId, onStartWizard: onStartWizard)
                }
            }
            .padding()
        }
        .navigationTitle("Where do I start?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Where do I start?")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Pick what fits your situation — we'll take you straight to the right tool.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

    private func route<Destination: View>(icon: String, title: String, subtitle: String,
                                          @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.goPrimary)
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold()).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
