import SwiftUI

/// "Policy Watch" — the in-app home for the us_policy_alerts channel. Frames standing
/// US emigration-policy factors and offers the breaking-news push opt-in.
struct PolicyWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var alertsRequested = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                optInCard
                ForEach(PolicyWatchData.items) { item in
                    itemCard(item)
                }
                Text(PolicyWatchData.footer)
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Policy Watch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("US policy, decoded for leaving")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("The standing rules that shape every US move — and what to do about each. We'll ping you when something material changes.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var optInCard: some View {
        VStack(spacing: 8) {
            if alertsRequested {
                Label("Alerts on — we'll notify you of major changes.", systemImage: "bell.badge.fill")
                    .font(.subheadline.bold()).foregroundColor(.goPrimary)
            } else {
                Button {
                    PushNotificationService.shared.requestPermissionAndSubscribe()
                    alertsRequested = true
                } label: {
                    Label("Turn on policy alerts", systemImage: "bell.badge")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.goPrimary)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func itemCard(_ item: PolicyWatchItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.icon).foregroundColor(.goPrimary)
                Text(item.headline).font(.subheadline.bold()).foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Who it affects").font(.caption2.bold()).foregroundColor(.secondary)
                Text(item.whoAffected).font(.caption).foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Your fastest route").font(.caption2.bold()).foregroundColor(.goPrimary)
                Text(item.fastestRoute).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
