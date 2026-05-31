import SwiftUI
import FirebaseFirestore

/// Premium "concierge" tier — upper-tier highest-willingness-to-pay. SCAFFOLD ONLY:
/// no live IAP/pricing is wired (that's an ASC + referral-backend decision for the
/// operator). For now this presents the value prop and captures a waitlist signal in
/// Firestore (`conciergeWaitlist/{uid}`) so demand can be measured before committing
/// to pricing. Flip `isLiveTier` once the SKU + advisor network exist.
struct ConciergeView: View {
    @Environment(\.dismiss) private var dismiss

    /// Set true once a real concierge SKU + vetted-advisor network are live.
    /// While false, the CTA captures interest instead of selling.
    private let isLiveTier = false

    @State private var joined = false
    @State private var submitting = false

    private let benefits: [(String, String)] = [
        ("person.2.badge.gearshape", "Vetted advisor matching", "Hand-picked immigration lawyers, tax advisors, and relocation agents in your target country — pre-screened, not a directory dump."),
        ("doc.badge.gearshape", "Done-with-you visa prep", "We help assemble and sanity-check your application packet against the consulate's exact checklist."),
        ("bolt.shield", "Priority support", "Direct line for time-sensitive questions during your move window."),
        ("house.and.flag", "Settling-in concierge", "Warm intros for housing, banking, and schools — the things that take locals to unlock."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                ForEach(Array(benefits.enumerated()), id: \.offset) { _, b in
                    benefitRow(icon: b.0, title: b.1, detail: b.2)
                }
                ctaCard
                disclaimer
            }
            .padding()
        }
        .navigationTitle("GoThere Concierge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Concierge")
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)
                Text(isLiveTier ? "PREMIUM" : "COMING SOON")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.goPrimary)
                    .cornerRadius(4)
            }
            Text("White-glove relocation support for people who'd rather pay to get it right than spend months figuring it out alone.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.goPrimary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundColor(.primary)
                Text(detail).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var ctaCard: some View {
        VStack(spacing: 8) {
            if joined {
                Label("You're on the list — we'll be in touch.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.goPrimary)
            } else {
                Button {
                    Task { await joinWaitlist() }
                } label: {
                    HStack {
                        if submitting { ProgressView().tint(.white) }
                        Text(isLiveTier ? "Talk to a concierge" : "Join the waitlist")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.goPrimary)
                    .cornerRadius(12)
                }
                .disabled(submitting)
                Text("No charge to express interest. We'll only reach out when it launches.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private var disclaimer: some View {
        Text("Concierge connects you with independent, licensed professionals. GoThere is not a law firm and does not provide legal or tax advice.")
            .font(.caption2).foregroundColor(.secondary)
    }

    /// Records interest in Firestore. Reversible, no payment. Mirrors the auth/uid
    /// pattern used by PurchaseManager.
    private func joinWaitlist() async {
        submitting = true
        defer { submitting = false }
        if let uid = AuthService.shared.uid {
            let db = Firestore.firestore()
            try? await db.collection("conciergeWaitlist").document(uid).setData([
                "uid": uid,
                "platform": "ios",
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
        }
        Analytics.log(.purchaseInitiated, properties: ["product_id": "concierge_waitlist"])
        joined = true
    }
}
