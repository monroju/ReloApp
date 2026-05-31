import SwiftUI

/// Wave 2 — AI conversational entry point.
///
/// Surfaced from HomeView via the "I don't know where to start" tile. Talks to
/// `AIService` which proxies the conversation through api.getgothere.app/ai with
/// tool-use against on-device VisaCatalog, CostDatabase, and WizardRepository.
struct AIWhereToStartView: View {
    @StateObject private var ai = AIService.shared
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var input: String = ""
    @State private var showPaywall: Bool = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            disclaimerBanner

            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if ai.messages.isEmpty {
                            emptyStateCard
                                .padding(.top, 24)
                        }
                        ForEach(visibleMessages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                        if ai.isWaitingForReply {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: ai.messages.count) { _ in
                    withAnimation { scroll.scrollTo(ai.messages.last?.id ?? "typing", anchor: .bottom) }
                }
            }

            if let err = ai.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.goError)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            inputBar
        }
        .navigationTitle("Where should I start?")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear {
            Analytics.log(.aiConversationOpened, properties: ["sent_count": ai.sentMessageCount])
        }
    }

    // MARK: - Subviews

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.goPrimary)
            Text("Informational only. Verify with the official source — and a licensed lawyer for legal questions.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.goPrimary.opacity(0.06))
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.goPrimary)
            Text("Tell me about your situation.")
                .font(.title3.weight(.semibold))
            Text("Where do you want to go, what's your household look like, do you have any ancestry that might open doors? I'll suggest visa paths and ballpark costs from GoThere's data.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Examples")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                examplePrompt("I'm a remote worker, couple, US$5k/mo budget, drawn to Portugal or Spain")
                examplePrompt("My grandmother was born in Ireland. Am I eligible for an Irish passport?")
                examplePrompt("Retiring in Mexico — which city is most affordable on $3k/mo?")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.goPrimary.opacity(0.05))
        .cornerRadius(16)
    }

    private func examplePrompt(_ text: String) -> some View {
        Button {
            input = text
            inputFocused = true
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.up.left")
                    .font(.caption2)
                    .foregroundColor(.goPrimary)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func messageBubble(_ msg: AIMessage) -> some View {
        switch msg.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                Text(msg.displayText)
                    .padding(12)
                    .background(Color.goPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        case .assistant:
            HStack(alignment: .top) {
                Image(systemName: "sparkles")
                    .foregroundColor(.goPrimary)
                    .frame(width: 24)
                Text(.init(msg.displayText))
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                Spacer(minLength: 40)
            }
        }
    }

    private var typingIndicator: some View {
        HStack(alignment: .top) {
            Image(systemName: "sparkles")
                .foregroundColor(.goPrimary)
                .frame(width: 24)
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.goPrimary.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .offset(y: ai.isWaitingForReply ? -2 : 0)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: ai.isWaitingForReply
                        )
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            Spacer()
        }
    }

    private var inputBar: some View {
        VStack(spacing: 4) {
            quotaHint
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask anything…", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit { sendCurrent() }

                Button(action: sendCurrent) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(canSend ? .goPrimary : .secondary.opacity(0.5))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private var quotaHint: some View {
        Group {
            if !purchaseManager.hasAllAccess {
                let remaining = max(0, AIService.maxFreeMessages - ai.sentMessageCount)
                if ai.isPaywallGated {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill").font(.caption2)
                            Text("You've used your 5 free messages. Upgrade to keep going.")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundColor(.goPrimary)
                    }
                    .padding(.horizontal, 12)
                } else if remaining <= 2 {
                    Text("\(remaining) free message\(remaining == 1 ? "" : "s") left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - Behaviour

    private var visibleMessages: [AIMessage] {
        // Hide pure tool_result loopbacks — they're not useful for the user to read.
        ai.messages.filter { msg in
            switch msg.role {
            case .user:
                return msg.content.contains {
                    if case .text = $0 { return true }
                    return false
                }
            case .assistant:
                return !msg.displayText.isEmpty
            }
        }
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !ai.isWaitingForReply
            && !ai.isPaywallGated
    }

    private func sendCurrent() {
        guard canSend else {
            if ai.isPaywallGated { showPaywall = true }
            return
        }
        let toSend = input
        input = ""
        Task { await ai.send(toSend) }
    }
}

#Preview {
    NavigationStack {
        AIWhereToStartView()
            .environmentObject(PurchaseManager.shared)
    }
}
