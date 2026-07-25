import SwiftUI
import UIKit

/// Give-a-month / get-a-month referral loop.
///
/// Shows the signed-in user's shareable code (with a native share sheet) and a
/// redeem field for a friend's code. Redeeming grants both users a server-side
/// 30-day All-Access window (users/{uid}.promoAccessUntil), mirrored locally via
/// PurchaseManager.applyPromoGrant so the UI unlocks immediately.
///
/// Requires a real account — guest mode has no Firebase identity to attribute a
/// referral to, so guests see a create-account prompt instead.
struct ReferralView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @ObservedObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var info: ReferralInfo?
    @State private var loadError: String?
    @State private var isLoading = false

    @State private var enteredCode = ""
    @State private var isRedeeming = false
    @State private var redeemMessage: String?
    @State private var redeemSucceeded = false

    private var isSignedIn: Bool { auth.currentUser != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    if isSignedIn {
                        yourCodeCard
                        redeemCard
                    } else {
                        signInPrompt
                    }
                }
                .padding()
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await loadCodeIfNeeded() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundColor(.goPrimary)
            Text("Give a month, get a month")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Share your code. When a friend redeems it, you both get 30 days of All-Access — every country, every visa path — free.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    @ViewBuilder
    private var yourCodeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your invite code")
                .font(.headline)
                .foregroundColor(.goPrimary)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let info {
                Text(info.code)
                    .font(.system(.title, design: .monospaced).bold())
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = info.code
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.goPrimary)

                    ShareLink(item: shareMessage(info)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.goPrimary)
                }
            } else if let loadError {
                Text(loadError)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Try again") { Task { await loadCode() } }
                    .font(.subheadline)
                    .tint(.goPrimary)
            }
        }
        .goCard()
    }

    private var redeemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Got a code from a friend?")
                .font(.headline)
                .foregroundColor(.goPrimary)

            if redeemSucceeded {
                Label(redeemMessage ?? "You're in — enjoy your free month!",
                      systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.goSuccess)
            } else {
                TextField("Enter code", text: $enteredCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)

                if let redeemMessage {
                    Text(redeemMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button {
                    Task { await redeem() }
                } label: {
                    if isRedeeming {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 8)
                    } else {
                        Text("Redeem")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.goPrimary)
                .disabled(enteredCode.trimmingCharacters(in: .whitespaces).isEmpty || isRedeeming)
            }
        }
        .goCard()
    }

    private var signInPrompt: some View {
        VStack(spacing: 12) {
            Text("Create a free account to invite friends and redeem codes. Referral months are tied to your account, so guest mode can't earn them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .goCard()
    }

    // MARK: - Actions

    private func shareMessage(_ info: ReferralInfo) -> String {
        "I'm using GoThere to plan my move abroad — it's genuinely useful. Use my code \(info.code) and we both get a free month of All-Access: \(info.shareURL)"
    }

    private func loadCodeIfNeeded() async {
        guard isSignedIn, info == nil, !isLoading else { return }
        await loadCode()
    }

    private func loadCode() async {
        isLoading = true
        loadError = nil
        do {
            info = try await ReferralService.shared.fetchCode()
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func redeem() async {
        isRedeeming = true
        redeemMessage = nil
        let code = enteredCode.trimmingCharacters(in: .whitespaces).uppercased()
        do {
            let result = try await ReferralService.shared.redeem(code: code)
            purchaseManager.applyPromoGrant(until: result.premiumUntil)
            redeemSucceeded = true
            redeemMessage = "You're in — \(result.rewardDays) days of All-Access unlocked."
            Analytics.log(.purchaseCompleted, properties: [
                "product_id": "referral_redeem",
                "reward_days": result.rewardDays
            ])
        } catch {
            redeemMessage = error.localizedDescription
        }
        isRedeeming = false
    }
}
